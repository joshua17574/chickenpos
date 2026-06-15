import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../core/settings/app_settings.dart';

/// Loads/persists [AppSettings] via shared_preferences.
class SettingsController extends Notifier<AppSettings> {
  static const _kStore = 'store_name';
  static const _kVat = 'vat_rate';
  static const _kDark = 'dark_mode';

  @override
  AppSettings build() {
    final p = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      storeName: p.getString(_kStore) ?? const AppSettings().storeName,
      vatRate: p.getDouble(_kVat) ?? const AppSettings().vatRate,
      darkMode: p.getBool(_kDark) ?? false,
    );
  }

  Future<void> setVatRate(double rate) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setDouble(_kVat, rate);
    state = state.copyWith(vatRate: rate);
  }

  Future<void> setStoreName(String name) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setString(_kStore, name);
    state = state.copyWith(storeName: name);
  }

  Future<void> setDarkMode(bool dark) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setBool(_kDark, dark);
    state = state.copyWith(darkMode: dark);
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Theme mode derived from settings.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider).darkMode ? ThemeMode.dark : ThemeMode.light,
);
