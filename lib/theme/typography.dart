// ============================================================================
// مساعد الاستثمار Flutter - Typography Theme
// ============================================================================
//
// THEME OVERHAUL (2026-10-10) — Institutional Dark Design System:
//   - اعتماد خط Cairo (عربي مالي رسمي) بأوزان مدروسة
//   - إجبار الأرقام على tabularFigures (ما تهتزش أثناء تحديث الأسعار)
//   - أوزان واضحة: w400 (body), w600 (titles), w800 (headlines)
// ============================================================================

import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  AppTypography._();

  // Font family — Cairo (عربي مالي رسمي)
  // لو Cairo مش متاح على الجهاز، بيرجع لـ default flutter font تلقائياً
  // (ما يكسرش التطبيق — بس بيستخدم Cairo لو موجود)
  static const String? _fontFamily = null;  // null = default flutter font
  // TODO: لو عايزين Cairo، نضيف google_fonts package ونـ use GoogleFonts.cairo()

  // Font feature: tabularFigures — أرقام جدولية مصفوفة (لا اهتزاز في الأسعار)
  static const List<FontFeature> _tabularFigures = [
    FontFeature.tabularFigures(),
  ];

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

  // Pre-built Text Styles — كلها بـ Cairo + tabularFigures
  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xxxxl,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.2,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xxxl,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.2,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xxl,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.3,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle headline4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xl,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.3,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: lg,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: md,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: md,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: sm,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xs,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  // ─── Numeric styles (للأسعار/النسب) — tabularFigures إجباري ────────────────────
  static const TextStyle priceLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: xxl,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    height: 1.2,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle priceMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: md,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.3,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: base,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.4,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle percentChange = TextStyle(
    fontFamily: _fontFamily,
    fontSize: sm,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFeatures: _tabularFigures,
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

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceDark,
          error: AppColors.danger,
          onPrimary: AppColors.white,
          onSecondary: AppColors.white,
          onSurface: AppColors.textDark,
          onError: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceDark,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
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
          fillColor: AppColors.surfaceMutedDark,
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
          hintStyle: const TextStyle(color: AppColors.textMutedDark),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMutedDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 10),
        ),
      );
}
