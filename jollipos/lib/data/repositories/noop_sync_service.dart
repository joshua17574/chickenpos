import '../../domain/entities/order.dart';
import '../../domain/repositories/sync_service.dart';

/// Default disabled sync — the app runs fully offline. Replace with a Firestore
/// implementation that posts [Order.toJson] to a collection; the repository
/// contract stays identical.
class NoopSyncService implements SyncService {
  const NoopSyncService();

  @override
  bool get isEnabled => false;

  @override
  Future<void> pushOrder(Order order) async {/* no-op */}

  @override
  Future<void> pullChanges() async {/* no-op */}
}
