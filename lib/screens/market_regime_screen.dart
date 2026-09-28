// ============================================================================
// مساعد الاستثمار Flutter - Market Regime Screen
// شاشة حالة السوق — DEFENSIVE / NORMAL / AGGRESSIVE
//
// تعرض:
//   - حالة السوق الحالية (شارة كبيرة ملوّنة)
//   - 6 مؤشرات التقييم (اتجاه المؤشر + الاتساع + ATR + حجم التداول + خسارة الصفقات + السحب)
//   - أسباب الحالة الحالية
//   - تاريخ آخر تحديث / المصدر
//
// المصدر: GET /api/market/regime?market=EGX
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

// ─── Provider: Market Regime Data ─────────────────────────────────────────
final marketRegimeProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return GLMApiClient.instance.getMarketRegime(market: 'EGX');
});

class MarketRegimeScreen extends ConsumerWidget {
  const MarketRegimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(marketRegimeProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: const Text('حالة السوق'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => ref.refresh(marketRegimeProvider),
            ),
          ],
        ),
        body: asyncData.when(
          loading: () => const LoadingWidget(message: 'جارٍ تحميل حالة السوق...'),
          error: (e, st) => _ErrorView(
            message: 'فشل تحميل حالة السوق: $e',
            onRetry: () => ref.refresh(marketRegimeProvider),
          ),
          data: (data) {
            if (data.isEmpty ||
                data['success'] == false ||
                data['regime'] == null) {
              final errMsg = data['error']?.toString() ?? 'لا توجد بيانات متاحة';
              return EmptyStateWidget(
                icon: Icons.shield_moon_outlined,
                message: 'تعذّر الحصول على حالة السوق: $errMsg',
              );
            }
            return _RegimeBody(data: data);
          },
        ),
      ),
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────
class _RegimeBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RegimeBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final regime = (data['regime'] ?? 'UNKNOWN').toString().toUpperCase();
    final confidence = _toDouble(data['confidence']);
    final market = data['market']?.toString() ?? 'EGX';
    final updatedAt = data['updated_at']?.toString() ??
        data['timestamp']?.toString() ??
        '—';
    final reasons = _asStringList(data['reasons']);
    final indicators = _asMap(data['indicators']);
    final history = _asList(data['history']);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RegimeBadge(regime: regime, confidence: confidence, market: market),
        const SizedBox(height: 16),
        if (indicators.isNotEmpty) ...[
          _SectionTitle(icon: Icons.insights, text: 'مؤشرات التقييم'),
          const SizedBox(height: 8),
          _IndicatorsGrid(indicators: indicators),
          const SizedBox(height: 16),
        ],
        if (reasons.isNotEmpty) ...[
          _SectionTitle(icon: Icons.lightbulb_outline, text: 'أسباب الحالة'),
          const SizedBox(height: 8),
          _ReasonsList(reasons: reasons),
          const SizedBox(height: 16),
        ],
        if (history.isNotEmpty) ...[
          _SectionTitle(icon: Icons.history, text: 'تاريخ الحالات'),
          const SizedBox(height: 8),
          _HistoryList(history: history),
          const SizedBox(height: 16),
        ],
        _MetaCard(market: market, updatedAt: updatedAt),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Regime Badge (large color-coded card) ──────────────────────────────
class _RegimeBadge extends StatelessWidget {
  final String regime;
  final double confidence;
  final String market;
  const _RegimeBadge({required this.regime, required this.confidence, required this.market});

  @override
  Widget build(BuildContext context) {
    final (color, labelAr, emoji) = _regimeStyle(regime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Text(
                labelAr,
                style: AppTypography.headline2.copyWith(color: color, fontSize: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              regime,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('السوق: ', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
              Text(market, style: AppTypography.titleMedium),
              const SizedBox(width: 16),
              Text('الثقة: ', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
              Text(
                confidence > 0 ? '${(confidence * 100).toStringAsFixed(0)}%' : '—',
                style: AppTypography.titleMedium.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, String, String) _regimeStyle(String r) {
    switch (r) {
      case 'DEFENSIVE':
        return (AppColors.danger, 'دفاعي', '🛡️');
      case 'NORMAL':
        return (AppColors.warning, 'طبيعي', '⚖️');
      case 'AGGRESSIVE':
        return (AppColors.success, 'هجومي', '🚀');
      default:
        return (AppColors.textMuted, 'غير معروف', '❓');
    }
  }
}

// ─── Section Title ─────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.quantumEmerald),
        const SizedBox(width: 8),
        Text(text, style: AppTypography.titleMedium),
      ],
    );
  }
}

// ─── Indicators Grid (6 indicators) ─────────────────────────────────────
class _IndicatorsGrid extends StatelessWidget {
  final Map<String, dynamic> indicators;
  const _IndicatorsGrid({required this.indicators});

  @override
  Widget build(BuildContext context) {
    final entries = indicators.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, i) {
        final e = entries[i];
        final label = _indicatorLabelAr(e.key);
        final value = _formatValue(e.value);
        final isFlag = e.value is bool;
        final isPositive = isFlag ? e.value == true : false;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.quantumGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isFlag) ...[
                    Icon(
                      isPositive ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: isPositive ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      style: AppTypography.titleSmall.copyWith(
                        color: isFlag
                            ? (isPositive ? AppColors.success : AppColors.danger)
                            : AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _indicatorLabelAr(String key) {
    const map = {
      'index_trend': 'اتجاه المؤشر',
      'breadth': 'اتساع السوق',
      'atr': 'تذبذب ATR',
      'turnover': 'معدل الدوران',
      'loss_streak': 'سلسلة الخسارة',
      'drawdown': 'السحب الحالي',
      'volume_ratio': 'نسبة الحجم',
      'advance_decline': 'الصاعد/الهابط',
      'rsi': 'مؤشر RSI',
      'momentum': 'الزخم',
    };
    return map[key] ?? key.replaceAll('_', ' ');
  }

  String _formatValue(dynamic v) {
    if (v == null) return '—';
    if (v is bool) return v ? 'إيجابي' : 'سلبي';
    if (v is num) {
      if (v.abs() >= 100) return v.toStringAsFixed(0);
      return v.toStringAsFixed(2);
    }
    return v.toString();
  }
}

// ─── Reasons List ───────────────────────────────────────────────────────
class _ReasonsList extends StatelessWidget {
  final List<String> reasons;
  const _ReasonsList({required this.reasons});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.quantumGlassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: reasons
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•', style: TextStyle(color: AppColors.quantumEmerald, fontSize: 18, height: 1.3)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r, style: AppTypography.bodyMedium)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── History List ────────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<dynamic> history;
  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.quantumGlassBorder),
      ),
      child: Column(
        children: history.take(10).map((h) {
          final m = h is Map<String, dynamic> ? h : <String, dynamic>{};
          final regime = (m['regime'] ?? '?').toString().toUpperCase();
          final date = m['date']?.toString() ?? m['timestamp']?.toString() ?? '—';
          final (color, labelAr, emoji) = _regimeStyle(regime);
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Text(emoji, style: const TextStyle(fontSize: 20)),
            title: Text(labelAr, style: AppTypography.titleSmall.copyWith(color: color)),
            subtitle: Text(date, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
          );
        }).toList(),
      ),
    );
  }

  (Color, String, String) _regimeStyle(String r) {
    switch (r) {
      case 'DEFENSIVE':
        return (AppColors.danger, 'دفاعي', '🛡️');
      case 'NORMAL':
        return (AppColors.warning, 'طبيعي', '⚖️');
      case 'AGGRESSIVE':
        return (AppColors.success, 'هجومي', '🚀');
      default:
        return (AppColors.textMuted, 'غير معروف', '❓');
    }
  }
}

// ─── Meta Card ───────────────────────────────────────────────────────────
class _MetaCard extends StatelessWidget {
  final String market;
  final String updatedAt;
  const _MetaCard({required this.market, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.quantumGlassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'السوق: $market · آخر تحديث: $updatedAt',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────
double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v);
    if (parsed != null) return parsed;
  }
  return 0;
}

List<String> _asStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
  }
  if (v is String) return [v];
  return [];
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return {};
}

List<dynamic> _asList(dynamic v) {
  if (v is List) return v;
  return [];
}
