import 'dart:math';

import '../../core/constants.dart';
import '../../models/burger.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/store_location.dart';
import '../db/app_database.dart';

class OrderSubmissionException implements Exception {
  final String message;
  OrderSubmissionException(this.message);
}

/// Simulates submitting an order to a backend. Per spec 3.4, a failed
/// submission must never lose the cart or leave the app ambiguous — so this
/// repository never mutates the cart itself; the caller (order provider)
/// only clears the cart AFTER a confirmed successful submission.
class OrderRepository {
  final AppDatabase _db = AppDatabase.instance;
  final Random _random = Random();

  Future<void> submit(Order order, {required bool isOnline}) async {
    if (!isOnline) {
      throw OrderSubmissionException('No internet connection.');
    }

    await Future.delayed(const Duration(milliseconds: 600));

    if (AppConstants.simulateRandomOrderFailure && _random.nextDouble() < 0.2) {
      throw OrderSubmissionException('Connection dropped while placing your order.');
    }

    await _db.saveOrder(order);
  }

  Future<void> updateStatus(String orderId, OrderStatus status) => _db.updateOrderStatus(orderId, status);

  Future<Order?> latestOrder(List<Burger> menuById, List<StoreLocation> stores) =>
      _db.readLatestOrder(menuById, stores);
}
