import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hashes cashier/admin PINs. A per-install salt should be added in production;
/// kept simple here for the offline demo.
abstract class PinHasher {
  static const _salt = 'jollipos::v1';

  static String hash(String pin) =>
      sha256.convert(utf8.encode('$_salt::$pin')).toString();

  static bool verify(String pin, String hash) => PinHasher.hash(pin) == hash;
}
