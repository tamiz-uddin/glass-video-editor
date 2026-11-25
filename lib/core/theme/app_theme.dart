import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF12121A);
  static const glassLight = Color(0x1AFFFFFF);
  static const glassBorder = Color(0x26FFFFFF);
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9CA3AF);
  static const accentViolet = Color(0xFF8B5CF6);
  static const accentCyan = Color(0xFF22D3EE);

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentViolet, accentCyan],
  );
}

class AppRadius {
  AppRadius._();

  static const double panel = 20;
  static const double button = 14;
  static const double chip = 12;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accentViolet,
        secondary: AppColors.accentCyan,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }
}
