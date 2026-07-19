import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'enums.dart';
import 'store_location.dart';

const int kBaseDeliveryFeeRs = 50;
const int kPerKmDeliveryFeeRs = 8;
const int kMaxDeliveryFeeRs = 300;

/// Delivery fee scales with distance from the customer to the store:
/// a flat base fee plus a per-km rate, capped at a maximum. Falls back to
/// the base fee alone when distance isn't known (e.g. manual city pick
/// with no GPS reading).
int computeDeliveryFeeRs(double? distanceKm) {
  if (distanceKm == null) return kBaseDeliveryFeeRs;
  final fee = kBaseDeliveryFeeRs + (distanceKm * kPerKmDeliveryFeeRs).round();
  return fee.clamp(kBaseDeliveryFeeRs, kMaxDeliveryFeeRs);
}

/// A placed order — a frozen snapshot of cart items + pricing at the moment
/// of checkout, plus its lifecycle status. Kept separate from CartItem so
/// editing the live cart afterwards never mutates order history.
class Order extends Equatable {
  final String orderId;
  final List<CartItem> items;
  final StoreLocation location;
  final OrderStatus status;
  final DateTime placedAt;
  final int deliveryFeeRs;

  const Order({
    required this.orderId,
    required this.items,
    required this.location,
    required this.status,
    required this.placedAt,
    this.deliveryFeeRs = kBaseDeliveryFeeRs,
  });

  int get subtotalRs => items.fold(0, (sum, item) => sum + item.lineTotalRs);
  int get totalRs => subtotalRs + deliveryFeeRs;

  Order copyWith({OrderStatus? status}) => Order(
        orderId: orderId,
        items: items,
        location: location,
        status: status ?? this.status,
        placedAt: placedAt,
        deliveryFeeRs: deliveryFeeRs,
      );

  @override
  List<Object?> get props => [orderId, status, placedAt];
}

/// Fixed delay schedule (from placedAt) for each status transition, used to
/// simulate the backend per spec 3.4 and to schedule OS-level notifications
/// up front so they still fire if the app is backgrounded or killed.
class OrderTimeline {
  static const Duration toPreparing = Duration(seconds: 20);
  static const Duration toReadyOrOutForDelivery = Duration(seconds: 60);
  static const Duration toDelivered = Duration(seconds: 120);
}
