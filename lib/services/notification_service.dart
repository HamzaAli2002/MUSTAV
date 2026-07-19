import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/enums.dart';
import '../models/order.dart';

/// Wraps flutter_local_notifications. Order-status notifications are all
/// SCHEDULED up front at placement time (zonedSchedule), so they fire from
/// the OS even if the app is backgrounded or force-killed afterwards —
/// satisfying the "verify while backgrounded" requirement in spec 3.4
/// without depending on a long-lived background process.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    // Critical fix: without this, tz.local defaults to UTC, so every
    // zonedSchedule() call computes the wrong fire time relative to the
    // device's actual clock — this is why only the immediate "Received"
    // notification ever showed up and the rest silently never fired.
    //
    // No native plugin used here (like flutter_timezone) — that pulled in
    // an old Android Gradle Plugin version and caused Kotlin/Java
    // JVM-target build failures. Instead we compute the device's current
    // UTC offset in pure Dart and map it to a fixed "Etc/GMT" zone already
    // bundled in the timezone package's data.
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final etcName = offsetHours == 0
          ? 'UTC'
          : 'Etc/GMT${offsetHours > 0 ? '-' : '+'}${offsetHours.abs()}';
      tz.setLocalLocation(tz.getLocation(etcName));
    } catch (_) {
      // Fall back to UTC rather than crashing.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    const channel = AndroidNotificationChannel(
      'order_status',
      'Order Status Updates',
      description: 'Notifies you when your MUSTAV order status changes.',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'order_status',
      'Order Status Updates',
      channelDescription: 'Notifies you when your MUSTAV order status changes.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Schedules the full Received → Preparing → Ready/Out for Delivery →
  /// Delivered sequence at once, anchored to [placedAt].
  Future<void> scheduleOrderTimeline({
    required String orderId,
    required DateTime placedAt,
  }) async {
    await _showImmediate(
      id: _notifId(orderId, OrderStatus.received),
      title: 'Order Received 🔥',
      body: 'MUSTAV has your order — firing up the grill now.',
    );

    await _scheduleAt(
      id: _notifId(orderId, OrderStatus.preparing),
      title: 'Preparing your order 👨‍🍳',
      body: 'Your smashed burger is on the flat top.',
      fireAt: placedAt.add(OrderTimeline.toPreparing),
    );

    await _scheduleAt(
      id: _notifId(orderId, OrderStatus.readyOrOutForDelivery),
      title: 'Ready / Out for Delivery 🛵',
      body: 'Your order is ready and on its way.',
      fireAt: placedAt.add(OrderTimeline.toReadyOrOutForDelivery),
    );

    await _scheduleAt(
      id: _notifId(orderId, OrderStatus.delivered),
      title: 'Delivered ✅',
      body: 'Enjoy your MUSTAV — crafted for your cravings.',
      fireAt: placedAt.add(OrderTimeline.toDelivered),
    );
  }

  Future<void> cancelOrderTimeline(String orderId) async {
    for (final status in OrderStatus.values) {
      await _plugin.cancel(_notifId(orderId, status));
    }
  }

  Future<void> notifyOrderFailed() async {
    await _showImmediate(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Order failed to send ⚠️',
      body: 'Connection dropped. Your cart is safe — tap to retry.',
    );
  }

  int _notifId(String orderId, OrderStatus status) =>
      (orderId.hashCode ^ status.index).abs() % 2147483647;

  Future<void> _showImmediate(
      {required int id, required String title, required String body}) async {
    await _plugin.show(id, title, body, _details);
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(fireAt, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
