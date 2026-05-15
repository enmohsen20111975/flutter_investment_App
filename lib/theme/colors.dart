// ============================================================================
// مساعد الاستثمار Flutter - Theme Colors
// Ultra modern Material 3 design tokens matching React Native theme
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors - Emerald Green
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryMuted = Color(0x1410B981);
  static const Color primaryContainer = Color(0x2610B981);

  // Secondary Colors - Indigo
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryDark = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF818CF8);
  static const Color secondaryMuted = Color(0x146366F1);

  // Accent Colors - Amber
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0x1422C55E);
  static const Color successContainer = Color(0x2622C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0x14F59E0B);
  static const Color warningContainer = Color(0x26F59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0x14EF4444);
  static const Color dangerContainer = Color(0x26EF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0x143B82F6);
  static const Color infoContainer = Color(0x263B82F6);

  // Background Colors - Light Surface System
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceHover = Color(0xFFE2E8F0);
  static const Color surfaceDim = Color(0xFFE8ECF1);

  // Background Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF334155);
  static const Color surfaceHoverDark = Color(0xFF475569);
  static const Color surfaceDimDark = Color(0xFF1E293B);

  // Text Colors - Dark Theme
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Text Colors
  static const Color text = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border Colors
  static const Color border = Color(0xFFE8ECF1);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);

  // Chart Colors
  static const Color chartUp = Color(0xFF22C55E);
  static const Color chartDown = Color(0xFFEF4444);
  static const Color chartNeutral = Color(0xFF94A3B8);

  // Action Colors
  static const Color buy = Color(0xFF22C55E);
  static const Color sell = Color(0xFFEF4444);
  static const Color hold = Color(0xFFF59E0B);
  static const Color google = Color(0xFF4285F4);

  // Misc
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryDark],
  );
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [secondary, secondaryDark],
  );
  static const LinearGradient gradientHero = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
  );
}

// Spacing - 8pt grid
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;
}

// Border Radius - Material 3 style
class AppRadius {
  AppRadius._();
  static const double none = 0;
  static const double xs = 2;
  static const double sm = 6;
  static const double base = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double full = 9999;
}
