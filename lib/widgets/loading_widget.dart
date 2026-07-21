// ============================================================================
// مساعد الاستثمار Flutter - Loading Widget
// Reusable loading indicator widget
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message ?? 'جاري التحميل...',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
