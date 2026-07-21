// ============================================================================
// مساعد الاستثمار Flutter - App Card
// Unified card widget for consistent UI across screens
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surface;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);

    Widget card = Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: effectiveRadius,
        child: card,
      );
    }

    return card;
  }
}

class AppCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const AppCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ?? const [AppColors.primary, AppColors.primaryDark];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.white.withValues(alpha: 0.8),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.white),
            ),
        ],
      ),
    );
  }
}
