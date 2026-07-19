import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/order_repository.dart';
import '../models/cart_item.dart';
import '../models/enums.dart';
import '../models/order.dart';
import '../models/store_location.dart';
import '../services/notification_service.dart';
import 'cart_provider.dart';
import 'connectivity_provider.dart';
import 'menu_provider.dart';
import 'location_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

enum CheckoutPhase { idle, submitting, success, failed }

class CheckoutState {
  final CheckoutPhase phase;
  final String? errorMessage;
  final Order? order;

  const CheckoutState({this.phase = CheckoutPhase.idle, this.errorMessage, this.order});

  CheckoutState copyWith({CheckoutPhase? phase, String? errorMessage, Order? order}) => CheckoutState(
        phase: phase ?? this.phase,
        errorMessage: errorMessage,
        order: order ?? this.order,
      );
}

/// Drives spec 3.4. Crucially: the cart is only cleared AFTER a confirmed
/// successful submission. A failed submission leaves the cart and the
/// pending order draft fully intact so the user can just tap retry.
class CheckoutNotifier extends Notifier<CheckoutState> {
  static const _uuid = Uuid();
  Timer? _statusTimer;

  @override
  CheckoutState build() {
    ref.onDispose(() => _statusTimer?.cancel());
    return const CheckoutState();
  }

  Future<void> submitOrder({
    required List<CartItem> items,
    required StoreLocation location,
    int deliveryFeeRs = kBaseDeliveryFeeRs,
  }) async {
    state = state.copyWith(phase: CheckoutPhase.submitting, errorMessage: null);

    final isOnline = ref.read(isOnlineProvider).valueOrNull ?? false;
    final order = Order(
      orderId: _uuid.v4(),
      items: items,
      location: location,
      status: OrderStatus.received,
      placedAt: DateTime.now(),
      deliveryFeeRs: deliveryFeeRs,
    );

    try {
      await ref.read(orderRepositoryProvider).submit(order, isOnline: isOnline);

      // Success: safe to clear the cart now.
      await ref.read(cartProvider.notifier).clear();

      // Notification scheduling is best-effort — if it throws (missing
      // exact-alarm permission on some Android versions, etc.) it must
      // NEVER block navigation away from the checkout screen. Previously
      // an uncaught exception here left the UI stuck on the loading
      // spinner forever.
      try {
        await NotificationService.instance.scheduleOrderTimeline(
          orderId: order.orderId,
          placedAt: order.placedAt,
        );
      } catch (_) {
        // Swallow — order still succeeded, just no OS notifications.
      }

      state = state.copyWith(phase: CheckoutPhase.success, order: order);
      _startStatusSimulation(order);
    } on OrderSubmissionException catch (e) {
      // Failure: cart untouched, draft order kept so "retry" resubmits the
      // exact same items with no re-entry required.
      state = state.copyWith(phase: CheckoutPhase.failed, errorMessage: e.message, order: order);
      try {
        await NotificationService.instance.notifyOrderFailed();
      } catch (_) {
        // Best-effort, same reasoning as above.
      }
    } catch (e) {
      // Catch-all: any unexpected error must still resolve the UI state
      // rather than leaving the submit button stuck spinning forever.
      state = state.copyWith(
        phase: CheckoutPhase.failed,
        errorMessage: 'Something went wrong placing your order.',
        order: order,
      );
    }
  }

  Future<void> retry() async {
    final pending = state.order;
    if (pending == null) return;
    await submitOrder(items: pending.items, location: pending.location, deliveryFeeRs: pending.deliveryFeeRs);
  }

  void reset() {
    _statusTimer?.cancel();
    state = const CheckoutState();
  }

  /// Rehydrates an order read back from disk on cold start (spec 3.4 — the
  /// app must not lose track of an order after being killed). Notifications
  /// were already OS-scheduled at placement time, so this only needs to
  /// resume driving the in-app status forward for any remaining transitions.
  void resumeOrder(Order order) {
    state = state.copyWith(phase: CheckoutPhase.success, order: order, errorMessage: null);
    if (order.status != OrderStatus.delivered) {
      _startStatusSimulation(order, resumeFromElapsed: true);
    }
  }

  void _startStatusSimulation(Order order, {bool resumeFromElapsed = false}) {
    _statusTimer?.cancel();
    final repo = ref.read(orderRepositoryProvider);
    final elapsed = DateTime.now().difference(order.placedAt);

    void scheduleTransition(Duration delay, OrderStatus status) {
      final remaining = delay - elapsed;
      Timer(remaining.isNegative ? Duration.zero : remaining, () async {
        await repo.updateStatus(order.orderId, status);
        if (state.order?.orderId == order.orderId) {
          state = state.copyWith(order: order.copyWith(status: status));
        }
      });
    }

    scheduleTransition(OrderTimeline.toPreparing, OrderStatus.preparing);
    scheduleTransition(OrderTimeline.toReadyOrOutForDelivery, OrderStatus.readyOrOutForDelivery);
    scheduleTransition(OrderTimeline.toDelivered, OrderStatus.delivered);
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

/// Resumes the most recent order (e.g. app reopened after being killed
/// while an order was in flight) by reading it back from disk.
final latestOrderProvider = FutureProvider.autoDispose<Order?>((ref) async {
  final menu = await ref.watch(menuProvider.future);
  final stores = await ref.watch(storesProvider.future);
  return ref.watch(orderRepositoryProvider).latestOrder(menu, stores);
});
