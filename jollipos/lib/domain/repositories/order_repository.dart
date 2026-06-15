import '../entities/enums.dart';
import '../entities/order.dart';

/// Order data boundary used by checkout, KDS, and reports.
abstract interface class OrderRepository {
  Future<void> saveOrder(Order order);
  Future<void> updateStatus(String orderId, OrderStatus status);

  Stream<List<Order>> watchActiveOrders();
  Future<List<Order>> getOrdersBetween(DateTime start, DateTime end);

  /// Sequential, store-wide order number.
  Future<int> nextOrderNumber();

  /// Daily-cycling kitchen queue number.
  Future<int> nextQueueNumber(DateTime day);

  /// Offline-first sync hooks.
  Future<List<Order>> getUnsynced();
  Future<void> markSynced(String orderId);
}
