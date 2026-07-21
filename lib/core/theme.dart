// ============================================================================
// مساعد الاستثمار Flutter - Core Theme
// Unified ThemeData for the entire app
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AppThemeCore {
  AppThemeCore._();

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
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
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
              fontFamily: 'Cairo',
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
          hintStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Cairo'),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
          unselectedLabelStyle: TextStyle(fontSize: 10, fontFamily: 'Cairo'),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.headline1,
          displayMedium: AppTypography.headline2,
          displaySmall: AppTypography.headline3,
          headlineMedium: AppTypography.headline4,
          titleLarge: AppTypography.titleLarge,
          titleMedium: AppTypography.titleMedium,
          titleSmall: AppTypography.titleSmall,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelSmall: AppTypography.labelSmall,
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
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Cairo',
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
              fontFamily: 'Cairo',
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
          hintStyle: const TextStyle(color: AppColors.textMutedDark, fontFamily: 'Cairo'),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surfaceDark,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMutedDark,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
          unselectedLabelStyle: TextStyle(fontSize: 10, fontFamily: 'Cairo'),
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.headline1.copyWith(color: AppColors.textDark),
          displayMedium: AppTypography.headline2.copyWith(color: AppColors.textDark),
          displaySmall: AppTypography.headline3.copyWith(color: AppColors.textDark),
          headlineMedium: AppTypography.headline4.copyWith(color: AppColors.textDark),
          titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textDark),
          titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textDark),
          titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textDark),
          bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textDark),
          bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
          bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textMutedDark),
          labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textSecondaryDark),
          labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textMutedDark),
        ),
      );
}
