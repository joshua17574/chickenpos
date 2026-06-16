import 'package:intl/intl.dart';

/// Currency + money math helpers. Money is stored as int **centavos** in the DB
/// to avoid floating-point rounding errors; formatted as PHP for display.
abstract class Money {
  static final NumberFormat _php =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  /// Format integer centavos as a peso string, e.g. 12550 -> "₱125.50".
  static String format(int centavos) => _php.format(centavos / 100);

  /// Parse a peso double (e.g. 125.50) into centavos (12550).
  static int toCentavos(double pesos) => (pesos * 100).round();

  static double toPesos(int centavos) => centavos / 100;

  /// Parse free-form user input (e.g. "125", "125.5", "₱1,250.00") into
  /// centavos. Returns null when the text is not a valid non-negative amount.
  static int? parsePesos(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return toCentavos(value);
  }
}
