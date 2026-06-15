import '../entities/order.dart';

/// Remote sync seam. Local-first: orders are saved to Drift immediately, then
/// pushed here when connectivity allows. Swap [NoopSyncService] for a Firestore
/// implementation without changing app logic.
abstract interface class SyncService {
  /// Whether a remote backend is configured/available.
  bool get isEnabled;

  /// Push a single order to the remote backend. Throws on failure so the caller
  /// can keep it queued.
  Future<void> pushOrder(Order order);

  /// Optional pull of catalog/order changes from remote (no-op by default).
  Future<void> pullChanges();
}
