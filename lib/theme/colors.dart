// ============================================================================
// مساعد الاستثمار Flutter - Institutional Dark Design System
// ===============================================================================
//
// THEME OVERHAUL (2026-10-10) — Master Refactoring Blueprint:
//   - إزالة ألوان النيون والتدرجات العشوائية (TikTok/Game-like)
//   - اعتماد Institutional Dark Palette (Obsidian / Slate / Emerald / Gold)
//   - مطابقة TradingView Pro / Bloomberg / Binance Institutional
//
// القاعدة: لكل لون دوره — مفيش ألوان للزينة.
//   - Obsidian: الخلفية الأساسية العميقة
//   - Slate: الأسطح والبطاقات
//   - Institutional Emerald: اللون الرئيسي (نماء/ربح)
//   - Crisp Carmine: الهبوط/الخسارة
//   - Refined Gold: التحليلات المتقدمة/الاشتراكات
// ===============================================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ════════════════════════════════════════════════════════════════════════
  // 1. PRIMARY — Institutional Emerald (اللون الرئيسي للمنصة)
  // ════════════════════════════════════════════════════════════════════════
  // لون النماء والربح المالي النقي — مطابق TradingView/Binance
  static const Color primary = Color(0xFF10B981);          // Institutional Emerald-600
  static const Color primaryDark = Color(0xFF059669);     // Emerald-700 (hover/pressed)
  static const Color primaryLight = Color(0xFF34D399);     // Emerald-400 (subtle highlights)
  static const Color primaryMuted = Color(0x1F10B981);    // 12% emerald (chips/badges bg)
  static const Color primaryContainer = Color(0x2610B981); // 15% emerald (containers)
  static const Color primaryGlow = Color(0x3310B981);     // 20% emerald (subtle glow — NOT neon)

  // ════════════════════════════════════════════════════════════════════════
  // 2. SECONDARY — Slate Teal (لون ثانوي هادئ، مش نيون)
  // ════════════════════════════════════════════════════════════════════════
  static const Color secondary = Color(0xFF14B8A6);        // Teal-500
  static const Color secondaryDark = Color(0xFF0F766E);    // Teal-700
  static const Color secondaryLight = Color(0xFF5EEAD4);   // Teal-300
  static const Color secondaryMuted = Color(0x1F14B8A6);   // 12% teal

  // ════════════════════════════════════════════════════════════════════════
  // 3. ACCENT — Refined Gold (للتحليلات المتقدمة والاشتراكات فقط)
  // ════════════════════════════════════════════════════════════════════════
  static const Color accent = Color(0xFFF59E0B);           // Gold-500
  static const Color accentDark = Color(0xFFD97706);      // Gold-600
  static const Color accentLight = Color(0xFFFBBF24);     // Gold-400
  static const Color accentMuted = Color(0x1FF59E0B);      // 12% gold

  // ════════════════════════════════════════════════════════════════════════
  // 4. SEMANTIC COLORS (دلالات واضحة — مش للزينة)
  // ════════════════════════════════════════════════════════════════════════
  // Success / Bullish — Emerald Up (صعود/ربح)
  static const Color success = Color(0xFF00D084);          // Emerald Up — brighter for chart
  static const Color successLight = Color(0x1A00D084);
  static const Color successContainer = Color(0x2600D084);
  static const Color buy = Color(0xFF00D084);              // = success (bullish)

  // Warning / Hold — Gold (تحذير/انتظار)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0x1AF59E0B);
  static const Color warningContainer = Color(0x26F59E0B);
  static const Color hold = Color(0xFFF59E0B);             // = warning

  // Danger / Bearish — Crisp Carmine (هبوط/خسارة)
  static const Color danger = Color(0xFFF43F5E);          // Crisp Carmine-500
  static const Color dangerLight = Color(0x1AF43F5E);
  static const Color dangerContainer = Color(0x26F43F5E);
  static const Color sell = Color(0xFFF43F5E);             // = danger (bearish)

  // Info — Slate Blue (معلومات — مش نيون)
  static const Color info = Color(0xFF38BDF8);            // Slate-400 (subtle)
  static const Color infoLight = Color(0x1A38BDF8);
  static const Color infoContainer = Color(0x2638BDF8);

  // ════════════════════════════════════════════════════════════════════════
  // 5. DEEP OBSIDIAN BACKGROUNDS (خلفيات داكنة عميقة)
  // ════════════════════════════════════════════════════════════════════════
  // Deep Obsidian — يلغي تشتت الضوء، مريح للعين في الجلسات الطويلة
  static const Color background = Color(0xFF080B11);       // Deep Obsidian (أعمق من قبل)
  static const Color surface = Color(0xFF0F172A);         // Slate Surface-900
  static const Color surfaceMuted = Color(0xFF1E293B);    // Slate-800
  static const Color surfaceHover = Color(0xFF334155);    // Slate-700 (hover/active)
  static const Color surfaceDim = Color(0xFF0F172A);      // Slate-900 (dim)

  // Dark theme variants (نفس الألوان — الموضوع dark بالأساس)
  static const Color backgroundDark = Color(0xFF080B11);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color surfaceMutedDark = Color(0xFF1E293B);
  static const Color surfaceHoverDark = Color(0xFF334155);
  static const Color surfaceDimDark = Color(0xFF0F172A);

  // ════════════════════════════════════════════════════════════════════════
  // 6. HIGH-CONTRAST TEXT (وضوح عالي للقراءة المالية)
  // ════════════════════════════════════════════════════════════════════════
  static const Color text = Color(0xFFF8FAFC);           // Text Primary — Slate-50
  static const Color textSecondary = Color(0xFF94A3B8);   // Text Secondary — Slate-400
  static const Color textMuted = Color(0xFF64748B);       // Text Muted — Slate-500
  static const Color textLight = Color(0xFFF1F5F9);       // Text Light — Slate-100
  static const Color textOnPrimary = Color(0xFFFFFFFF);   // على خلفية Emerald
  static const Color textDark = Color(0xFFF8FAFC);        // = text (dark theme أساسي)
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // ════════════════════════════════════════════════════════════════════════
  // 7. BORDERS & CARDS (حواف خفيفة أنيقة)
  // ════════════════════════════════════════════════════════════════════════
  static const Color border = Color(0xFF1E293B);          // Slate-800 — حد خفيف
  static const Color borderLight = Color(0xFF334155);     // Slate-700 — حد متوسط
  static const Color borderDark = Color(0xFF475569);     // Slate-600 — حد قوي
  static const Color card = Color(0xFF0F172A);           // Slate-900 — سطح البطاقة
  static const Color cardBorder = Color(0xFF1E293B);     // Slate-800 — حد البطاقة

  // ════════════════════════════════════════════════════════════════════════
  // 8. CHART COLORS (ألوان الشارت — مطابقة TradingView)
  // ════════════════════════════════════════════════════════════════════════
  static const Color chartUp = Color(0xFF00D084);         // Emerald Up
  static const Color chartDown = Color(0xFFF43F5E);      // Crisp Carmine
  static const Color chartNeutral = Color(0xFF94A3B8);   // Slate-400

  // ════════════════════════════════════════════════════════════════════════
  // 9. ACTION COLORS (ألوان الإجراءات)
  // ════════════════════════════════════════════════════════════════════════
  static const Color google = Color(0xFF4285F4);         // Google Blue (لزر Google Sign-In فقط)

  // ════════════════════════════════════════════════════════════════════════
  // 10. MISC
  // ════════════════════════════════════════════════════════════════════════
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
  static const Color overlay = Color(0xCC000000);          // 80% black overlay
  static const Color overlayLight = Color(0x66000000);     // 40% black overlay

  // ════════════════════════════════════════════════════════════════════════
  // 11. LEGACY ALIASE (للحفاظ على التوافق مع الكود الموجود)
  // ════════════════════════════════════════════════════════════════════════
  // CRITICAL: ألوان النيون القديمة — يحولها لألوان هادئة من الـ palette الجديد
  // عشان ما نكسرش الكود الموجود اللي بـ يستخدم neonCyan/neonLime
  // لكن بصرياً هتظهر بألوان institutional مش نيون
  static const Color neonCyan = Color(0xFF14B8A6);         // → Teal (مش cyan نيون)
  static const Color neonCyanLight = Color(0xFF5EEAD4);   // → Teal-300
  static const Color neonLime = Color(0xFF10B981);        // → Emerald (مش lime نيون)
  static const Color neonLimeLight = Color(0xFF34D399);   // → Emerald-400
  static const Color neonYellow = Color(0xFFF59E0B);      // → Gold (مش yellow نيون)

  // Quantum aliases (للحفاظ على التوافق)
  static const Color quantumBg = Color(0xFF080B11);       // → Deep Obsidian
  static const Color quantumSurface = Color(0xFF0F172A);  // → Slate Surface
  static const Color quantumGlass = Color(0xFF0F172A);    // → Slate (glassmorphism خفيف)
  static const Color quantumGlassBorder = Color(0xFF1E293B); // → Slate Border
  static const Color quantumEmerald = Color(0xFF10B981);   // → Institutional Emerald
  static const Color quantumGold = Color(0xFFF59E0B);     // → Refined Gold
  static const Color quantumCrimson = Color(0xFFF43F5E);  // → Crisp Carmine

  // ════════════════════════════════════════════════════════════════════════
  // 12. SUBTLE FINTECH GRADIENTS (تدرجات هادئة — مش صاخبة)
  // ════════════════════════════════════════════════════════════════════════
  // FIX: استبدال gradientNeon + gradientPurplePink بـ gradients institutional هادئة
  static const LinearGradient gradientNeon = LinearGradient(
    colors: [primary, secondary],  // Emerald → Teal (هادئ)
  );
  static const LinearGradient gradientPurplePink = LinearGradient(
    colors: [primary, secondary],  // = gradientNeon (alias للتوافق)
  );
  static const LinearGradient gradientDark = LinearGradient(
    colors: [Color(0xFF080B11), Color(0xFF0F172A), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientSurface = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],  // Emerald gradient
  );
  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],  // Carmine gradient
  );
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],  // Gold gradient (subtle)
  );
  static const LinearGradient gradientInfo = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF5EEAD4)],  // Teal gradient
  );
  static const LinearGradient gradientHero = LinearGradient(
    colors: [primaryDark, primary],  // Emerald hero (هادئ)
  );
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primaryDark, primary],
  );
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [secondaryDark, secondary],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// SPACING — 8pt grid system (مطابق Material Design)
// ════════════════════════════════════════════════════════════════════════════
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;   // المسافة الأساسية للهوامش
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double xxxxl = 48;
}

// ════════════════════════════════════════════════════════════════════════════
// BORDER RADIUS — Material 3 style (حواف ناعمة 12-16px)
// ════════════════════════════════════════════════════════════════════════════
class AppRadius {
  AppRadius._();
  static const double none = 0;
  static const double xs = 2;
  static const double sm = 6;
  static const double base = 8;
  static const double md = 12;     // الحافة الأساسية للبطاقات
  static const double lg = 16;     // البطاقات الكبيرة
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double full = 9999; // دائري كامل
}
