// ============================================================================
// مساعد الاستثمار Flutter - Theme Colors
// VIBRANT FUN THEME - TikTok / Game-like / Delightful
// ============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary - Royal Indigo / Electric Blue
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryMuted = Color(0x1F6366F1);
  static const Color primaryContainer = Color(0x266366F1);
  static const Color primaryGlow = Color(0xFFA5B4FC);

  // Secondary - Tech Cyan / Sky Blue (replaces clashing hot pink)
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryDark = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryMuted = Color(0x1F0EA5E9);

  // Accent - Warm Luxury Gold / Amber
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentLight = Color(0xFFFBBF24);

  // Neon accents
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonCyanLight = Color(0xFF22D3EE);
  static const Color neonLime = Color(0xFF10B981);
  static const Color neonLimeLight = Color(0xFF34D399);
  static const Color neonYellow = Color(0xFFFACC15);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0x1A10B981);
  static const Color successContainer = Color(0x2610B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0x1AF59E0B);
  static const Color warningContainer = Color(0x26F59E0B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color dangerLight = Color(0x1AF43F5E);
  static const Color dangerContainer = Color(0x26F43F5E);
  static const Color info = Color(0xFF38BDF8);
  static const Color infoLight = Color(0x1A38BDF8);
  static const Color infoContainer = Color(0x2638BDF8);

  // Modern Obsidian & Slate Dark Backgrounds (No muddy purple)
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceMuted = Color(0xFF1E293B);
  static const Color surfaceHover = Color(0xFF334155);
  static const Color surfaceDim = Color(0xFF0F172A);

  // Dark theme variants
  static const Color backgroundDark = Color(0xFF0B0F19);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceMutedDark = Color(0xFF1E293B);
  static const Color surfaceHoverDark = Color(0xFF334155);
  static const Color surfaceDimDark = Color(0xFF0F172A);

  // High-Contrast Crisp Text Colors (High legibility)
  static const Color text = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFF1F5F9);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondaryDark = Color(0xFF475569);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Modern Borders
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);
  static const Color borderDark = Color(0xFF475569);

  // Chart Colors
  static const Color chartUp = Color(0xFF10B981);
  static const Color chartDown = Color(0xFFF43F5E);
  static const Color chartNeutral = Color(0xFF94A3B8);

  // Action Colors
  static const Color buy = Color(0xFF10B981);
  static const Color sell = Color(0xFFF43F5E);
  static const Color hold = Color(0xFFF59E0B);
  static const Color google = Color(0xFF4285F4);

  // Misc
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0xCC000000);
  static const Color overlayLight = Color(0x66000000);

  // ============================================================================
  // QUANTUM LUXURY FINTECH DARK THEME
  // ============================================================================
  static const Color quantumBg = Color(0xFF0B0F19);
  static const Color quantumSurface = Color(0xFF111827);
  static const Color quantumGlass = Color(0xFF162032);
  static const Color quantumGlassBorder = Color(0xFF26354D);
  static const Color quantumEmerald = Color(0xFF10B981);
  static const Color quantumGold = Color(0xFFF59E0B);
  static const Color quantumCrimson = Color(0xFFF43F5E);

  // ============================================================================
  // SLEEK FINTECH GRADIENTS
  // ============================================================================
  static const LinearGradient gradientNeon = LinearGradient(
    colors: [primary, secondary, accent],
  );
  static const LinearGradient gradientPurplePink = LinearGradient(
    colors: [primary, secondary],
  );
  static const LinearGradient gradientDark = LinearGradient(
    colors: [Color(0xFF0B0F19), Color(0xFF111827), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientSurface = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFF162032), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
  );
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24), Color(0xFFFCD34D)],
  );
  static const LinearGradient gradientInfo = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  );
  static const LinearGradient gradientHero = LinearGradient(
    colors: [primaryDark, primary, secondary],
  );
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryDark, primary],
  );
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [secondaryDark, secondary],
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
