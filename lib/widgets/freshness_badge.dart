// ============================================================================
// مساعد الاستثمار Flutter - Freshness Badge Widget
// Displays prediction data freshness with a colored dot + Arabic label.
// Mirrors website RecommendationMonitoring.tsx freshness indicator.
//
// Freshness rules:
//   < 5 min  → green dot  + label
//   5-60 min → amber dot  + label
//   > 60 min OR is_stale → red dot + "بيانات قديمة"
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';

class FreshnessBadge extends StatelessWidget {
  /// Arabic label from the backend (e.g. "منذ دقيقتين").
  final String? freshnessLabel;

  /// Age of the latest prediction in seconds.
  final int? freshnessSeconds;

  /// Backend-side staleness flag (overrides time-based logic when true).
  final bool isStale;

  /// Number of predictions generated today (optional, shown as suffix).
  final int? predictionsToday;

  /// Number of predictions in the last 7 days (optional, shown as suffix).
  final int? predictionsLast7d;

  final bool compact;

  const FreshnessBadge({
    super.key,
    this.freshnessLabel,
    this.freshnessSeconds,
    this.isStale = false,
    this.predictionsToday,
    this.predictionsLast7d,
    this.compact = false,
  });

  /// Build a [FreshnessBadge] directly from a backend `freshness_info` map.
  /// Tolerates missing keys (returns a neutral "غير متوفر" state).
  factory FreshnessBadge.fromInfo(Map<String, dynamic>? info,
      {bool compact = false}) {
    if (info == null) {
      return FreshnessBadge(compact: compact);
    }
    return FreshnessBadge(
      freshnessLabel: info['freshness_label']?.toString(),
      freshnessSeconds: _toInt(info['freshness_seconds']),
      isStale: info['is_stale'] == true || info['is_stale'] == 1,
      predictionsToday: _toInt(info['predictions_today']),
      predictionsLast7d: _toInt(info['predictions_last_7d']),
      compact: compact,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  ({Color color, String label, IconData icon}) get _state {
    // Stale override.
    if (isStale) {
      return (color: AppColors.danger, label: 'بيانات قديمة', icon: Icons.error_outline);
    }
    final secs = freshnessSeconds;
    if (secs == null) {
      // No data → neutral grey.
      return (color: AppColors.textMuted, label: freshnessLabel ?? 'غير متوفر', icon: Icons.help_outline);
    }
    if (secs < 5 * 60) {
      return (color: AppColors.success, label: freshnessLabel ?? 'الآن', icon: Icons.bolt_rounded);
    }
    if (secs < 60 * 60) {
      return (color: AppColors.warning, label: freshnessLabel ?? 'منذ قليل', icon: Icons.schedule_rounded);
    }
    return (color: AppColors.danger, label: 'بيانات قديمة', icon: Icons.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final hasCount = predictionsToday != null || predictionsLast7d != null;
    final countText = <String>[
      if (predictionsToday != null) 'اليوم: $predictionsToday',
      if (predictionsLast7d != null) 'آخر 7 أيام: $predictionsLast7d',
    ].join(' • ');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: state.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: state.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing-style dot (static here — keep it simple & cheap).
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(
              color: state.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: state.color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(state.icon, size: 12, color: state.color),
                    const SizedBox(width: 4),
                    Text(
                      state.label,
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w700,
                        color: state.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                if (!compact && hasCount) ...[
                  const SizedBox(height: 2),
                  Text(
                    countText,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
