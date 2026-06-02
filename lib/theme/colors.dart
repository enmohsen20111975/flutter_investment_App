// ============================================================================
// مساعد الاستثمار Flutter - Theme Colors
// VIBRANT FUN THEME - TikTok / Game-like / Delightful
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Electric Purple/Pink
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryDark = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryMuted = Color(0x148B5CF6);
  static const Color primaryContainer = Color(0x268B5CF6);
  static const Color primaryGlow = Color(0xFFC084FC);

  // Secondary - Hot Pink
  static const Color secondary = Color(0xFFEC4899);
  static const Color secondaryDark = Color(0xFFDB2777);
  static const Color secondaryLight = Color(0xFFF472B6);
  static const Color secondaryMuted = Color(0x14EC4899);

  // Accent - Electric Orange
  static const Color accent = Color(0xFFF97316);
  static const Color accentDark = Color(0xFFEA580C);
  static const Color accentLight = Color(0xFFFB923C);

  // Neon accents
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonCyanLight = Color(0xFF22D3EE);
  static const Color neonLime = Color(0xFF84CC16);
  static const Color neonLimeLight = Color(0xFFBEF264);
  static const Color neonYellow = Color(0xFFFACC15);

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

  // Fun Dark Backgrounds
  static const Color background = Color(0xFF0F0A1A);
  static const Color surface = Color(0xFF1A1025);
  static const Color surfaceMuted = Color(0xFF281A3A);
  static const Color surfaceHover = Color(0xFF332045);
  static const Color surfaceDim = Color(0xFF221535);

  // Dark theme variants
  static const Color backgroundDark = Color(0xFF0F0A1A);
  static const Color surfaceDark = Color(0xFF1A1025);
  static const Color surfaceMutedDark = Color(0xFF281A3A);
  static const Color surfaceHoverDark = Color(0xFF332045);
  static const Color surfaceDimDark = Color(0xFF221535);

  // Fun Text Colors
  static const Color text = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFC4B5FD);
  static const Color textMuted = Color(0xFF8B7AA0);
  static const Color textLight = Color(0xFFE8E0F0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1025);
  static const Color textSecondaryDark = Color(0xFF475569);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Fun Borders
  static const Color border = Color(0xFF3B2A50);
  static const Color borderLight = Color(0xFF4A3560);
  static const Color borderDark = Color(0xFF5A4570);

  // Chart Colors
  static const Color chartUp = Color(0xFF22C55E);
  static const Color chartDown = Color(0xFFEF4444);
  static const Color chartNeutral = Color(0xFF8B7AA0);

  // Action Colors
  static const Color buy = Color(0xFF22C55E);
  static const Color sell = Color(0xFFEF4444);
  static const Color hold = Color(0xFFF59E0B);
  static const Color google = Color(0xFF4285F4);

  // Misc
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0xCC000000);
  static const Color overlayLight = Color(0x66000000);

  // ============================================================================
  // FUN GRADIENTS
  // ============================================================================
  static const LinearGradient gradientNeon = LinearGradient(
    colors: [primary, secondary, accent],
  );
  static const LinearGradient gradientPurplePink = LinearGradient(
    colors: [primary, secondary],
  );
  static const LinearGradient gradientDark = LinearGradient(
    colors: [Color(0xFF0F0A1A), Color(0xFF1A1025), Color(0xFF281A3A)],
  );
  static const LinearGradient gradientSurface = LinearGradient(
    colors: [Color(0xFF1A1025), Color(0xFF281A3A)],
  );
  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFF281A3A), Color(0xFF332045)],
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );
  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFCD34D)],
  );
  static const LinearGradient gradientInfo = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  );
  static const LinearGradient gradientHero = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
  );
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryDark],
  );
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [secondary, secondaryDark],
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
