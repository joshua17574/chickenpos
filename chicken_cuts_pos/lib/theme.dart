import 'package:flutter/material.dart';

/// Design system for Chicken Cuts POS.
class AppColors {
  static const bg = Color(0xFFF3F0E8);
  static const bgDark = Color(0xFF101820);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFBF8F1);
  static const surfaceDark = Color(0xFF1B2731);
  static const primary = Color(0xFFD84A2B);
  static const primaryDeep = Color(0xFFAF321D);
  static const header = Color(0xFF10242A);
  static const headerSoft = Color(0xFF173941);
  static const ink = Color(0xFF19242A);
  static const inkDark = Color(0xFFF8FAFC);
  static const muted = Color(0xFF736D64);
  static const line = Color(0xFFE2DACC);
  static const lineDark = Color(0xFF374151);
  static const grocery = Color(0xFF138A66);
  static const wc = Color(0xFFD84A2B);
  static const indigo = Color(0xFF4159A7);
  static const teal = Color(0xFF0E7C72);
  static const pepsi = Color(0xFF2563A9);
  static const lemon = Color(0xFFE3AB25);
  static const success = Color(0xFF177F5B);
  static const warning = Color(0xFFC6790A);
  static const danger = Color(0xFFB83737);
  static const paperPattern = Color(0xFFE9DFCF);

  static const brandGradient = LinearGradient(
    colors: [header, headerSoft, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color category(String c) {
    switch (c.toUpperCase()) {
      case 'GROCERY':
        return grocery;
      case 'WC':
        return wc;
      case 'DRINKS':
      case 'BEVERAGE':
      case 'BEVERAGES':
        return pepsi;
      default:
        return teal;
    }
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    surface: dark ? AppColors.surfaceDark : AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? AppColors.bgDark : AppColors.bg,
    fontFamily: 'Roboto',
    dividerColor: dark ? AppColors.lineDark : AppColors.line,
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: dark ? AppColors.inkDark : AppColors.ink,
          displayColor: dark ? AppColors.inkDark : AppColors.ink,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.surfaceDark : AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: AppColors.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    splashFactory: InkRipple.splashFactory,
  );
}
