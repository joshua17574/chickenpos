import 'package:drift/drift.dart';

import '../../../domain/entities/enums.dart';
import '../../../domain/entities/shift.dart';
import '../../../domain/entities/user.dart';
import '../database.dart';
import '../tables/tables.dart';

part 'user_dao.g.dart';

/// User auth + cashier shift management.
@DriftAccessor(tables: [Users, Shifts])
class UserDao extends DatabaseAccessor<AppDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  Future<List<User>> getUsers() =>
      (select(users)..where((u) => u.active.equals(true)))
          .map(_toUser)
          .get();

  Future<User?> findByPinHash(String pinHash) =>
      (select(users)..where((u) => u.pinHash.equals(pinHash) & u.active.equals(true)))
          .map(_toUser)
          .getSingleOrNull();

  Future<void> upsertUser(User u) =>
      into(users).insertOnConflictUpdate(UsersCompanion.insert(
        id: u.id,
        name: u.name,
        role: u.role.index,
        pinHash: u.pinHash,
        active: Value(u.active),
      ));

  // ---------------- Shifts ----------------
  Future<Shift?> openShiftFor(String cashierId) =>
      (select(shifts)
            ..where((s) => s.cashierId.equals(cashierId) & s.closedAt.isNull()))
          .map(_toShift)
          .getSingleOrNull();

  Future<void> saveShift(Shift s) =>
      into(shifts).insertOnConflictUpdate(ShiftsCompanion.insert(
        id: s.id,
        cashierId: s.cashierId,
        openingFloatCentavos: s.openingFloatCentavos,
        openedAt: s.openedAt,
        closedAt: Value(s.closedAt),
        countedCashCentavos: Value(s.countedCashCentavos),
        expectedCashCentavos: Value(s.expectedCashCentavos),
      ));

  // ---------------- Mappers ----------------
  User _toUser(UserRow r) => User(
        id: r.id,
        name: r.name,
        role: UserRole.values[r.role],
        pinHash: r.pinHash,
        active: r.active,
      );

  Shift _toShift(ShiftRow r) => Shift(
        id: r.id,
        cashierId: r.cashierId,
        openingFloatCentavos: r.openingFloatCentavos,
        openedAt: r.openedAt,
        closedAt: r.closedAt,
        countedCashCentavos: r.countedCashCentavos,
        expectedCashCentavos: r.expectedCashCentavos,
      );
}
