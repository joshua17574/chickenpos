import 'package:flutter/material.dart';

/// JolliPOS brand palette — original bold red primary + yellow accent.
/// Not affiliated with any real quick-service brand.
abstract class AppColors {
  // Brand
  static const Color brandRed = Color(0xFFD7261E);
  static const Color brandRedDark = Color(0xFFA51810);
  static const Color brandYellow = Color(0xFFFFC107);
  static const Color brandYellowDark = Color(0xFFE6A800);

  // Neutrals
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF6F6F8);
  static const Color surfaceDark = Color(0xFF1C1B1F);
  static const Color backgroundDark = Color(0xFF121214);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Order status (used across cart, checkout, KDS)
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusPreparing = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFF1565C0);
}
