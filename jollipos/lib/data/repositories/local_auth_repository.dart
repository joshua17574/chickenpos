import '../../core/utils/pin_hasher.dart';
import '../../domain/entities/shift.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/daos/user_dao.dart';

/// Drift-backed auth repository. PINs are matched by hash; plaintext never
/// leaves the UI layer.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._dao);

  final UserDao _dao;

  @override
  Future<List<User>> getUsers() => _dao.getUsers();

  @override
  Future<User?> loginWithPin(String pin) =>
      _dao.findByPinHash(PinHasher.hash(pin));

  @override
  Future<void> upsertUser(User user) => _dao.upsertUser(user);

  @override
  Future<Shift?> openShiftFor(String cashierId) =>
      _dao.openShiftFor(cashierId);

  @override
  Future<void> saveShift(Shift shift) => _dao.saveShift(shift);
}
