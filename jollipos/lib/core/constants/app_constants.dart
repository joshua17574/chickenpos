/// App-wide configuration constants for JolliPOS.
abstract class AppConstants {
  static const String appName = 'JolliPOS';
  static const String brandTagline = 'Fast service, faster checkout';

  /// Default VAT rate (Philippines style 12%). Configurable in Admin settings.
  static const double defaultVatRate = 0.12;

  /// Statutory discount for Senior Citizen / PWD (20%).
  static const double statutoryDiscountRate = 0.20;

  /// Low-stock alert threshold for inventory-tracked items.
  static const int lowStockThreshold = 10;

  /// Auto-sync interval when a remote backend is configured.
  static const Duration syncInterval = Duration(seconds: 15);

  /// Default admin PIN seeded on first run (changeable in Admin).
  static const String defaultAdminPin = '1234';

  /// Local DB file name.
  static const String dbFileName = 'jollipos.sqlite';
}

/// Responsive breakpoints (logical pixels).
abstract class Breakpoints {
  static const double phone = 600;
  static const double tablet = 900;
}
