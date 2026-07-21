// ============================================================================
// مساعد الاستثمار Flutter - Persona Card Widget
// Displays persona opportunity with score bar and gates
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../models/persona_model.dart';

class PersonaCard extends StatelessWidget {
  final PersonaOpportunity opportunity;
  final VoidCallback? onTap;
  final bool showGates;

  const PersonaCard({
    super.key,
    required this.opportunity,
    this.onTap,
    this.showGates = true,
  });

  @override
  Widget build(BuildContext context) {
    final score = opportunity.score ?? 0;
    final scoreColor = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: opportunity.signalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      opportunity.signalLabel[0],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: opportunity.signalColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.displayName,
                        style: AppTypography.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (opportunity.sector != null)
                        Text(
                          opportunity.sector!,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPriceChip(
                    'الدخول',
                    opportunity.entryPrice,
                    AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: _buildPriceChip(
                    'الهدف',
                    opportunity.targetPrice,
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildPriceChip(
                    'الوقف',
                    opportunity.stopLoss,
                    AppColors.danger,
                  ),
                ),
              ],
            ),
            if (showGates && opportunity.gates != null) ...[
              const SizedBox(height: 12),
              _buildGatesRow(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChip(String label, double? value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value != null ? value.toStringAsFixed(2) : '—',
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGatesRow() {
    final gates = opportunity.gates ?? {};
    final passed = opportunity.passedGates;
    final total = opportunity.totalGates;
    final ratio = total > 0 ? passed / total : 0.0;

    return Row(
      children: [
        Text('الشروط: ', style: AppTypography.labelSmall),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ratio >= 0.8
                        ? AppColors.success
                        : ratio >= 0.5
                            ? AppColors.warning
                            : AppColors.danger,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$passed/$total',
                style: AppTypography.labelSmall.copyWith(
                  color: ratio >= 0.8
                      ? AppColors.success
                      : ratio >= 0.5
                          ? AppColors.warning
                          : AppColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
