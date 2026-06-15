import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required UserRole role,
    /// PIN hash (never store plaintext in production — hashed in repository).
    required String pinHash,
    @Default(true) bool active,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
