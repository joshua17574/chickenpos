import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/user.dart';

/// Holds the signed-in cashier/admin for the current device session.
class AuthController extends Notifier<User?> {
  @override
  User? build() => null;

  /// Attempts PIN login; returns the user on success (and sets state), else null.
  Future<User?> login(String pin) async {
    final user = await ref.read(authRepositoryProvider).loginWithPin(pin);
    if (user != null) state = user;
    return user;
  }

  void logout() => state = null;
}

final authControllerProvider =
    NotifierProvider<AuthController, User?>(AuthController.new);

final isLoggedInProvider =
    Provider<bool>((ref) => ref.watch(authControllerProvider) != null);
