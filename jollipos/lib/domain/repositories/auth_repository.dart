import '../entities/shift.dart';
import '../entities/user.dart';

/// Authentication + cashier shift boundary.
abstract interface class AuthRepository {
  Future<List<User>> getUsers();

  /// Returns the matching active user for a PIN, or null.
  Future<User?> loginWithPin(String pin);

  Future<void> upsertUser(User user);

  /// Currently open shift for a cashier, if any.
  Future<Shift?> openShiftFor(String cashierId);
  Future<void> saveShift(Shift shift);
}
