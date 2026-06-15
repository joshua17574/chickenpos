import '../../domain/entities/enums.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/sync_service.dart';
import '../local/daos/order_dao.dart';

/// Drift-backed order repository with best-effort remote sync.
///
/// Orders are always persisted locally first (offline-first). If a [SyncService]
/// is enabled, a push is attempted; failure simply leaves the order unsynced for
/// the background sync worker to retry.
class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository(this._dao, this._sync);

  final OrderDao _dao;
  final SyncService _sync;

  @override
  Future<void> saveOrder(Order order) async {
    await _dao.saveOrder(order);
    if (_sync.isEnabled) {
      try {
        await _sync.pushOrder(order);
        await _dao.markSynced(order.id);
      } catch (_) {
        // Stays unsynced; retried later. Local save already succeeded.
      }
    }
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status) =>
      _dao.updateStatus(orderId, status);

  @override
  Stream<List<Order>> watchActiveOrders() => _dao.watchActiveOrders();

  @override
  Future<List<Order>> getOrdersBetween(DateTime start, DateTime end) =>
      _dao.getOrdersBetween(start, end);

  @override
  Future<int> nextOrderNumber() => _dao.nextOrderNumber();

  @override
  Future<int> nextQueueNumber(DateTime day) => _dao.nextQueueNumber(day);

  @override
  Future<List<Order>> getUnsynced() => _dao.getUnsynced();

  @override
  Future<void> markSynced(String orderId) => _dao.markSynced(orderId);
}
