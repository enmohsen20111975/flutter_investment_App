// ============================================================================
// مساعد الاستثمار Flutter - Empty State Widget
// Reusable empty state display widget
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    this.message = 'لا توجد بيانات',
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(message, style: AppTypography.bodyMedium),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NoResultsWidget extends StatelessWidget {
  final String query;

  const NoResultsWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      message: 'لا توجد نتائج لـ "$query"',
      icon: Icons.search_off_rounded,
    );
  }
}
