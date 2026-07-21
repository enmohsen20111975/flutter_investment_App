// ============================================================================
// مساعد الاستثمار Flutter - Prediction Performance Screen
// Tracks historical prediction accuracy (win/loss) and metrics
// API: /api/mobile/predictions?status=closed
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class PredictionPerformanceScreen extends StatefulWidget {
  const PredictionPerformanceScreen({super.key});

  @override
  State<PredictionPerformanceScreen> createState() =>
      _PredictionPerformanceScreenState();
}

class _PredictionPerformanceScreenState
    extends State<PredictionPerformanceScreen> {
  Future<List<_ClosedPrediction>>? _predictionsFuture;

  @override
  void initState() {
    super.initState();
    _predictionsFuture = _fetchPredictions();
  }

  Future<List<_ClosedPrediction>> _fetchPredictions() async {
    try {
      final raw = await api.getMobilePredictions(status: 'closed', limit: 100);
      final list = <_ClosedPrediction>[];
      for (final e in raw) {
        if (e is Map) {
          list.add(_ClosedPrediction.fromMap(Map<String, dynamic>.from(e)));
        }
      }
      return list;
    } catch (_) {
      return <_ClosedPrediction>[];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _predictionsFuture = _fetchPredictions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<List<_ClosedPrediction>>(
          future: _predictionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomScrollView(
                slivers: [
                  _buildSliverHeader(),
                  const SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SkeletonCard(height: 120),
                        SizedBox(height: 8),
                        SkeletonCard(height: 200),
                        SizedBox(height: 8),
                        SkeletonList(itemCount: 3, itemHeight: 90),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return CustomScrollView(
                slivers: [
                  _buildSliverHeader(),
                  SliverFillRemaining(
                    child: StateView(
                        error: 'فشل تحميل تقييم التوقعات', onRetry: _refresh),
                  ),
                ],
              );
            }
            final preds = snapshot.data ?? [];
            final metrics = _Metrics.compute(preds);
            return CustomScrollView(
              slivers: [
                _buildSliverHeader(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildStatsRow(metrics),
                      const SizedBox(height: 8),
                      if (preds.isNotEmpty) _buildChart(metrics),
                      const SizedBox(height: 8),
                      _buildLegendRow(metrics),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (preds.isEmpty)
                  const SliverFillRemaining(
                    child: StateView(
                      empty: true,
                      emptyMessage: 'لا توجد توقعات مغلقة لتقييمها بعد',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.builder(
                      itemCount: preds.length,
                      itemBuilder: (context, index) {
                        final p = preds[index];
                        return RepaintBoundary(
                          child: _PredictionCard(prediction: p),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fact_check_outlined,
                        color: AppColors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تقييم التوقعات',
                            style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('دقة أداء التوقعات السابقة',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.white),
                    onPressed: _refresh,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(_Metrics m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'إجمالي التوقعات',
              value: '${m.total}',
              icon: Icons.list_alt_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'ناجحة',
              value: '${m.wins}',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'خاسرة',
              value: '${m.losses}',
              icon: Icons.cancel_outlined,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              label: 'معلقة',
              value: '${m.pending}',
              icon: Icons.pending_outlined,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(_Metrics m) {
    if (m.total == 0) return const SizedBox.shrink();
    final winRate = m.total > 0 ? m.wins / m.total : 0.0;
    final lossRate = m.total > 0 ? m.losses / m.total : 0.0;
    final pendingRate = m.total > 0 ? m.pending / m.total : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('توزيع النتائج', style: AppTypography.titleSmall),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accuracyColor(m.accuracy).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  'دقة ${(m.accuracy * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _accuracyColor(m.accuracy),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: RepaintBoundary(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  sections: [
                    if (m.wins > 0)
                      PieChartSectionData(
                        value: winRate,
                        color: AppColors.success,
                        title: '${(winRate * 100).toStringAsFixed(0)}%',
                        radius: 42,
                        titleStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (m.losses > 0)
                      PieChartSectionData(
                        value: lossRate,
                        color: AppColors.danger,
                        title: '${(lossRate * 100).toStringAsFixed(0)}%',
                        radius: 42,
                        titleStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (m.pending > 0)
                      PieChartSectionData(
                        value: pendingRate,
                        color: AppColors.warning,
                        title: '${(pendingRate * 100).toStringAsFixed(0)}%',
                        radius: 42,
                        titleStyle: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(_Metrics m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendDot('ناجحة', AppColors.success, m.wins),
          _legendDot('خاسرة', AppColors.danger, m.losses),
          _legendDot('معلقة', AppColors.warning, m.pending),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ($count)',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Color _accuracyColor(double acc) {
    if (acc >= 0.7) return AppColors.success;
    if (acc >= 0.5) return AppColors.warning;
    return AppColors.danger;
  }
}

// ============================================================================
// Stat Card
// ============================================================================
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// Prediction Card
// ============================================================================
class _PredictionCard extends StatelessWidget {
  final _ClosedPrediction prediction;

  const _PredictionCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final isWin = prediction.outcome == 'WIN';
    final isLoss = prediction.outcome == 'LOSS';
    final color = isWin
        ? AppColors.success
        : (isLoss ? AppColors.danger : AppColors.warning);
    final outcomeLabel = isWin
        ? 'ناجح'
        : (isLoss ? 'خاسر' : 'معلق');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          right: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(prediction.ticker,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(outcomeLabel,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _field('الدخول',
                    prediction.entryPrice?.toStringAsFixed(2) ?? '--'),
              ),
              Expanded(
                child: _field('الهدف',
                    prediction.targetPrice?.toStringAsFixed(2) ?? '--'),
              ),
              Expanded(
                child: _field('السعر النهائي',
                    prediction.finalPrice?.toStringAsFixed(2) ?? '--'),
              ),
              Expanded(
                child: _field(
                    'العائد %',
                    prediction.returnPct != null
                        ? '${prediction.returnPct! >= 0 ? '+' : ''}${prediction.returnPct!.toStringAsFixed(2)}%'
                        : '--'),
              ),
            ],
          ),
          if (prediction.predictionDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(prediction.predictionDate,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                const Spacer(),
                if (prediction.confidence > 0)
                  Text(
                    'الثقة: ${prediction.confidence}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: _confidenceColor(prediction.confidence),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Color _confidenceColor(int c) {
    if (c >= 75) return AppColors.success;
    if (c >= 50) return AppColors.warning;
    return AppColors.danger;
  }
}

// ============================================================================
// Metrics
// ============================================================================
class _Metrics {
  final int total;
  final int wins;
  final int losses;
  final int pending;
  final double accuracy;

  _Metrics({
    required this.total,
    required this.wins,
    required this.losses,
    required this.pending,
    required this.accuracy,
  });

  static _Metrics compute(List<_ClosedPrediction> preds) {
    int wins = 0, losses = 0, pending = 0;
    for (final p in preds) {
      if (p.outcome == 'WIN') {
        wins++;
      } else if (p.outcome == 'LOSS') {
        losses++;
      } else {
        pending++;
      }
    }
    final decided = wins + losses;
    final acc = decided > 0 ? wins / decided : 0.0;
    return _Metrics(
      total: preds.length,
      wins: wins,
      losses: losses,
      pending: pending,
      accuracy: acc,
    );
  }
}

// ============================================================================
// Closed Prediction Model
// ============================================================================
class _ClosedPrediction {
  final String ticker;
  final String outcome; // WIN | LOSS | PENDING
  final double? entryPrice;
  final double? targetPrice;
  final double? finalPrice;
  final double? returnPct;
  final int confidence;
  final String predictionDate;
  final String signal;

  _ClosedPrediction({
    required this.ticker,
    required this.outcome,
    required this.entryPrice,
    required this.targetPrice,
    required this.finalPrice,
    required this.returnPct,
    required this.confidence,
    required this.predictionDate,
    required this.signal,
  });

  factory _ClosedPrediction.fromMap(Map<String, dynamic> m) {
    final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString();
    final rawOutcome = (m['outcome'] ?? m['result'] ?? m['status'] ?? '')
        .toString()
        .toUpperCase();
    String outcome;
    if (rawOutcome.contains('WIN') ||
        rawOutcome.contains('SUCCESS') ||
        rawOutcome.contains('CORRECT')) {
      outcome = 'WIN';
    } else if (rawOutcome.contains('LOSS') ||
        rawOutcome.contains('FAIL') ||
        rawOutcome.contains('WRONG')) {
      outcome = 'LOSS';
    } else {
      outcome = 'PENDING';
    }
    final entry = _toDouble(m['entry_price'] ?? m['entry']);
    final target = _toDouble(m['target_price'] ?? m['target']);
    final finalPrice = _toDouble(
        m['final_price'] ?? m['actual_price'] ?? m['close_price'] ?? m['close']);
    final ret = _toDouble(m['return_pct'] ?? m['return'] ?? m['pnl_pct']);
    final conf = _toInt(m['confidence'] ?? m['confidence_score']);
    final date = (m['prediction_date'] ??
            m['created_at'] ??
            m['date'] ??
            '')
        .toString();
    final signal = (m['signal'] ?? m['signal_type'] ?? 'HOLD').toString();
    // Auto-compute outcome if missing
    if (rawOutcome.isEmpty && entry != null && finalPrice != null) {
      final isBuy =
          signal.toUpperCase().contains('BUY') || signal.contains('شراء');
      final diff = finalPrice - entry;
      outcome = ((isBuy && diff > 0) || (!isBuy && diff < 0)) ? 'WIN' : 'LOSS';
    }
    return _ClosedPrediction(
      ticker: ticker,
      outcome: outcome,
      entryPrice: entry,
      targetPrice: target,
      finalPrice: finalPrice,
      returnPct: ret,
      confidence: conf,
      predictionDate: date.length >= 10 ? date.substring(0, 10) : date,
      signal: signal,
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
