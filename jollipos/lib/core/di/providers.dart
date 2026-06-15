import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../data/repositories/local_auth_repository.dart';
import '../../data/repositories/local_catalog_repository.dart';
import '../../data/repositories/local_order_repository.dart';
import '../../data/repositories/noop_sync_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/sync_service.dart';

/// Overridden in `main()` with a loaded instance (and in tests).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Overridden in `main()` so the seeded instance is shared. Tests override with
/// `AppDatabase.memory()`.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider not overridden'),
);

/// Remote sync. Default is offline ([NoopSyncService]); swap for Firestore here.
final syncServiceProvider = Provider<SyncService>(
  (ref) => const NoopSyncService(),
);

// ---------------- Repositories ----------------
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => LocalCatalogRepository(ref.watch(databaseProvider).productDao),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => LocalOrderRepository(
    ref.watch(databaseProvider).orderDao,
    ref.watch(syncServiceProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(ref.watch(databaseProvider).userDao),
);
