// ============================================================================
// مساعد الاستثمار Flutter - Typography Theme
// ============================================================================

import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Font Sizes
  static const double xs = 10;
  static const double sm = 12;
  static const double base = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 30;
  static const double xxxxl = 36;
  static const double xxxxxl = 48;

  // Pre-built Text Styles
  static const TextStyle headline1 = TextStyle(
    fontSize: xxxxl,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.2,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: xxxl,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: xxl,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.3,
  );

  static const TextStyle headline4 = TextStyle(
    fontSize: xl,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: lg,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: md,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: md,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: sm,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: base,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: xs,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
  );
}

// App Theme Data
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.text,
          onError: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.text.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: AppColors.textMuted),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
      );
}
