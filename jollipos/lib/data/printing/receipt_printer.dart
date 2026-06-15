import '../../domain/entities/order.dart';

/// Thermal printer boundary. Implementations build ESC/POS output; swap the
/// stub for `esc_pos_printer` (network) or `blue_thermal_printer` (Bluetooth)
/// without touching the receipt UI.
abstract interface class ReceiptPrinter {
  /// Whether a physical printer is connected.
  bool get isAvailable;

  /// Render + send the receipt for [order]. Throws if printing fails.
  Future<void> printOrder(Order order, {required String storeName});
}
