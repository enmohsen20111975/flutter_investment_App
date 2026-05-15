// ============================================================================
// مساعد الاستثمار Flutter - Reusable Widgets
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

// ============================================================================
// State View - Loading, Error, Empty states
// ============================================================================
class StateView extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool empty;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  const StateView({super.key, this.loading = false, this.error, this.empty = false, this.emptyMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('جاري التحميل...', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.dangerLight, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline, color: AppColors.danger, size: 32),
              ),
              const SizedBox(height: 16),
              Text(error!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(emptyMessage ?? 'لا توجد بيانات', style: AppTypography.bodyMedium),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ============================================================================
// Data Row - Displays a label-value pair
// ============================================================================
class DataRowWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final double? change;
  final IconData? icon;
  final VoidCallback? onTap;

  const DataRowWidget({super.key, required this.title, this.subtitle, this.value, this.change, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPositive = (change ?? 0) >= 0;
    final changeColor = change == null
        ? AppColors.textMuted
        : isPositive
            ? AppColors.success
            : AppColors.danger;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryMuted, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.bodySmall),
                ],
              ),
            ),
            if (value != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value!, style: AppTypography.titleSmall),
                  if (change != null)
                    Text(
                      '${isPositive ? '+' : ''}${change!.toStringAsFixed(2)}%',
                      style: AppTypography.bodySmall.copyWith(color: changeColor),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Info Card - Displays a titled value card
// ============================================================================
class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String tone; // 'success', 'warning', 'danger', 'info', 'default'
  final IconData? icon;

  const InfoCard({super.key, required this.title, required this.value, this.subtitle, this.tone = 'default', this.icon});

  Color get _toneColor {
    switch (tone) {
      case 'success': return AppColors.success;
      case 'warning': return AppColors.warning;
      case 'danger': return AppColors.danger;
      case 'info': return AppColors.info;
      default: return AppColors.primary;
    }
  }

  Color get _toneBg {
    switch (tone) {
      case 'success': return AppColors.successLight;
      case 'warning': return AppColors.warningLight;
      case 'danger': return AppColors.dangerLight;
      case 'info': return AppColors.infoLight;
      default: return AppColors.primaryMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: _toneColor),
                const SizedBox(width: 6),
              ],
              Text(title, style: AppTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTypography.headline4.copyWith(color: _toneColor)),
          if (subtitle != null)
            Text(subtitle!, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

// ============================================================================
// Section Header
// ============================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.icon, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Text(title, style: AppTypography.titleMedium),
          const Spacer(),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: Text('عرض الكل', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// Action Button
// ============================================================================
class ActionButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final String variant; // 'primary', 'outline', 'danger'
  final bool fullWidth;
  final bool loading;
  final IconData? icon;

  const ActionButton({super.key, required this.title, this.onPress, this.variant = 'primary', this.fullWidth = false, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide border;

    switch (variant) {
      case 'outline':
        bgColor = AppColors.transparent;
        textColor = AppColors.primary;
        border = const BorderSide(color: AppColors.primary);
        break;
      case 'danger':
        bgColor = AppColors.danger;
        textColor = AppColors.white;
        border = BorderSide.none;
        break;
      default:
        bgColor = AppColors.primary;
        textColor = AppColors.white;
        border = BorderSide.none;
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPress,
        icon: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
            : (icon != null ? Icon(icon, size: 18) : null),
        label: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: border,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      ),
    );
  }
}

// ============================================================================
// Badge
// ============================================================================
class BadgeWidget extends StatelessWidget {
  final String text;
  final String variant; // 'success', 'warning', 'danger', 'default'
  final String size; // 'sm', 'md'

  const BadgeWidget({super.key, required this.text, this.variant = 'default', this.size = 'sm'});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (variant) {
      case 'success':
        bgColor = AppColors.successContainer;
        textColor = AppColors.success;
        break;
      case 'warning':
        bgColor = AppColors.warningContainer;
        textColor = AppColors.warning;
        break;
      case 'danger':
        bgColor = AppColors.dangerContainer;
        textColor = AppColors.danger;
        break;
      default:
        bgColor = AppColors.surfaceMuted;
        textColor = AppColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: size == 'sm' ? 8 : 12, vertical: size == 'sm' ? 2 : 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(text, style: TextStyle(fontSize: size == 'sm' ? 10 : 12, fontWeight: FontWeight.w600, color: textColor)),
    );
  }
}

// ============================================================================
// Progress Bar
// ============================================================================
class ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const ProgressBar({super.key, required this.progress, this.color = AppColors.primary, this.height = 4});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: progress / 100,
        backgroundColor: AppColors.surfaceMuted,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
      ),
    );
  }
}

// ============================================================================
// Header Card - Gradient header used across screens
// ============================================================================
class HeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const HeaderCard({super.key, required this.icon, required this.title, required this.subtitle, this.gradientColors = const [AppColors.primary, AppColors.primaryDark]});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Chip Filter
// ============================================================================
class ChipFilter extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const ChipFilter({super.key, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
