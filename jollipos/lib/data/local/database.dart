import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import 'daos/order_dao.dart';
import 'daos/product_dao.dart';
import 'daos/user_dao.dart';
import 'tables/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Products,
    ModifierGroups,
    Modifiers,
    Users,
    Shifts,
    Orders,
    OrderItems,
    Payments,
  ],
  daos: [ProductDao, OrderDao, UserDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static LazyDatabase _open() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, AppConstants.dbFileName));
      return NativeDatabase.createInBackground(file);
    });
  }

  /// In-memory database for tests.
  static AppDatabase memory() => AppDatabase(NativeDatabase.memory());
}
