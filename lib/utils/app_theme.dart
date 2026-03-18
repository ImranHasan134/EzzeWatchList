// lib/utils/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  static const Color gold        = Color(0xFFFFD700);
  static const Color goldDark    = Color(0xFFFFA500);
  static const Color ratingGold  = Color(0xFFFFD700); // alias used by detail & poster
  static const Color darkBg      = Color(0xFF0E0E0E);
  static const Color lightBg     = Color(0xFFF8F6F0);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
      ).copyWith(
        primary: gold,
        secondary: goldDark,
        surface: lightBg,
      ),
      scaffoldBackgroundColor: lightBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: gold,
        secondary: goldDark,
        surface: darkBg,
      ),
      scaffoldBackgroundColor: darkBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}