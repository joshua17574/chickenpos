import '../constants/app_constants.dart';

/// Immutable app settings persisted to shared_preferences.
class AppSettings {
  const AppSettings({
    this.storeName = 'JolliPOS Store #1',
    this.vatRate = AppConstants.defaultVatRate,
    this.darkMode = false,
  });

  final String storeName;
  final double vatRate;
  final bool darkMode;

  AppSettings copyWith({String? storeName, double? vatRate, bool? darkMode}) =>
      AppSettings(
        storeName: storeName ?? this.storeName,
        vatRate: vatRate ?? this.vatRate,
        darkMode: darkMode ?? this.darkMode,
      );
}
