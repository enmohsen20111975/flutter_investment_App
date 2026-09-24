// ============================================================================
// مساعد الاستثمار Flutter - Wealth Charts Screen
// رسوم بيانية شاملة للثروة: منحنى القيمة + توزيع الأصول + PnL يومي + PnL الأسهم
// APIs:
//   GET /api/portfolio/equity-curve?days=90  → api.getPortfolioEquityCurve(days)
//   GET /api/portfolio/holdings              → api.getPortfolioHoldings()
//   GET /api/portfolio/risk-summary          → api.getPortfolioRiskSummary()
// ============================================================================

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_localizations.dart';

class WealthChartsScreen extends StatefulWidget {
  const WealthChartsScreen({super.key});

  @override
  State<WealthChartsScreen> createState() => _WealthChartsScreenState();
}

class _WealthChartsScreenState extends State<WealthChartsScreen> {
  List<Map<String, dynamic>> _equityCurve = [];
  List<Map<String, dynamic>> _holdings = [];
  Map<String, dynamic> _riskSummary = {};
  bool _loading = true;
  String? _error;

  // Period selector
  int _selectedDays = 90;
  static const List<int> _periodOptions = [30, 90, 180, 365];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ──────────────────────────────────────────────────────────────────────
  // API calls
  // ──────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchEquityCurve() async {
    try {
      final raw = await api.getPortfolioEquityCurve(days: _selectedDays);
      return _normalizePointList(raw);
    } catch (e) {
      debugPrint('[WealthCharts] equity-curve fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHoldings() async {
    try {
      final data = await api.getPortfolioHoldings();
      List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final list = data['holdings'] ??
            data['positions'] ??
            data['items'] ??
            data['portfolio']?['positions'] ??
            data['portfolio']?['items'] ??
            data['data'] ??
            const [];
        raw = list is List ? list : const [];
      } else {
        raw = const [];
      }
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[WealthCharts] holdings fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> _fetchRiskSummary() async {
    try {
      final data = await api.getPortfolioRiskSummary();
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[WealthCharts] risk-summary fetch failed: $e');
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _normalizePointList(dynamic raw) {
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final inner = raw['points'] ??
          raw['equity_curve'] ??
          raw['data'] ??
          raw['series'] ??
          const [];
      list = inner is List ? inner : const [];
    } else {
      list = const [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        _fetchEquityCurve(),
        _fetchHoldings(),
        _fetchRiskSummary(),
      ]);
      if (!mounted) return;
      setState(() {
        _equityCurve = results[0] as List<Map<String, dynamic>>;
        _holdings = results[1] as List<Map<String, dynamic>>;
        _riskSummary = results[2] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────
  double _toDouble(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  String _fmt(dynamic v, [int digits = 2]) {
    return _toDouble(v).toStringAsFixed(digits);
  }

  /// Extract a numeric equity value from a curve point.
  /// Tries common keys the backend may use.
  double _equityValue(Map<String, dynamic> p) {
    return _toDouble(p['equity'] ??
        p['value'] ??
        p['total_value'] ??
        p['portfolio_value'] ??
        p['market_value'] ??
        p['y']);
  }

  String _equityLabel(Map<String, dynamic> p) {
    return (p['date'] ??
            p['day'] ??
            p['timestamp'] ??
            p['created_at'] ??
            p['x'] ??
            '')
        .toString();
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.isArabic;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'رسوم الثروة البيانية',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadAll,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonCard(height: 50),
          SizedBox(height: 12),
          SkeletonChart(height: 220),
          SizedBox(height: 12),
          SkeletonChart(height: 220),
          SizedBox(height: 12),
          SkeletonChart(height: 200),
          SizedBox(height: 12),
          SkeletonChart(height: 200),
        ],
      );
    }

    if (_error != null &&
        _equityCurve.isEmpty &&
        _holdings.isEmpty &&
        _riskSummary.isEmpty) {
      return StateView(
        error: 'فشل تحميل بيانات الثروة',
        onRetry: _loadAll,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          _buildEquityCurveCard(),
          const SizedBox(height: 16),
          _buildAssetAllocationCard(),
          const SizedBox(height: 16),
          _buildDailyPnLCard(),
          const SizedBox(height: 16),
          _buildStockPnLCard(),
          const SizedBox(height: 16),
          _buildRiskSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _periodOptions.map((d) {
          final active = _selectedDays == d;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedDays == d) return;
                setState(() => _selectedDays = d);
                _loadAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$d يوم',
                  style: TextStyle(
                    color: active ? AppColors.white : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Equity Curve (Line chart) ──────────────────────────────────────────
  Widget _buildEquityCurveCard() {
    final points = _equityCurve;
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _equityValue(points[i])));
    }
    final hasData = spots.isNotEmpty;
    final first = hasData ? spots.first.y : 0.0;
    final last = hasData ? spots.last.y : 0.0;
    final change = last - first;
    final changePct = first > 0 ? (change / first) * 100 : 0.0;
    final isUp = change >= 0;

    return _chartCard(
      title: 'منحنى القيمة (Equity Curve)',
      subtitle: 'القيمة الإجمالية للمحفظة يومياً',
      icon: Icons.show_chart_rounded,
      iconColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_fmt(last)} ج.م',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${_fmt(first)} ج.م',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              if (hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isUp ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${_fmt(change)} (${_fmt(changePct, 1)}%)',
                    style: TextStyle(
                      color:
                          isUp ? AppColors.success : AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: hasData
                ? LineChart(LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _safeInterval(spots),
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppColors.border.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 42,
                          interval: _safeInterval(spots),
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              _compact(v),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((s) {
                            return LineTooltipItem(
                              '${_fmt(s.y)} ج.م',
                              const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ))
                : const StateView(
                    empty: true,
                    emptyMessage: 'لا تتوفر بيانات لمنحنى القيمة',
                  ),
          ),
        ],
      ),
    );
  }

  // ── Asset Allocation (Donut) ───────────────────────────────────────────
  Widget _buildAssetAllocationCard() {
    // Group holdings by sector
    final bySector = <String, double>{};
    double totalValue = 0;
    for (final h in _holdings) {
      final sector = (h['sector']?.toString() ??
              h['type']?.toString() ??
              h['category']?.toString() ??
              'أخرى');
      final value = _toDouble(h['market_value'] ??
          h['current_value'] ??
          ((h['shares'] ?? h['quantity'] ?? 0) *
              _toDouble(h['current_price'])));
      bySector[sector] = (bySector[sector] ?? 0) + value;
      totalValue += value;
    }

    final palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.neonCyan,
      AppColors.danger,
    ];

    final sections = <PieChartSectionData>[];
    final legend = <_LegendItem>[];
    if (bySector.isNotEmpty && totalValue > 0) {
      final entries = bySector.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        final pct = (e.value / totalValue) * 100;
        final color = palette[i % palette.length];
        sections.add(PieChartSectionData(
          value: e.value,
          color: color,
          title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
          radius: 46,
          titleStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ));
        legend.add(_LegendItem(
          label: e.key,
          value: '${pct.toStringAsFixed(1)}%',
          color: color,
        ));
      }
    }

    return _chartCard(
      title: 'توزيع الأصول',
      subtitle: 'حسب القطاع/النوع',
      icon: Icons.donut_large_rounded,
      iconColor: AppColors.secondary,
      child: sections.isEmpty
          ? const StateView(
              empty: true,
              emptyMessage: 'لا توجد holdings لتوزيعها',
            )
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    sections: sections,
                  )),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: legend
                      .map((l) => _legendChip(l))
                      .toList(),
                ),
              ],
            ),
    );
  }

  // ── Daily PnL (Area chart) ──────────────────────────────────────────────
  Widget _buildDailyPnLCard() {
    // Compute day-over-day delta from equity curve
    final deltas = <FlSpot>[];
    for (var i = 1; i < _equityCurve.length; i++) {
      final prev = _equityValue(_equityCurve[i - 1]);
      final curr = _equityValue(_equityCurve[i]);
      deltas.add(FlSpot((i - 1).toDouble(), curr - prev));
    }

    final hasData = deltas.isNotEmpty;
    double? maxAbs;
    if (hasData) {
      for (final s in deltas) {
        final a = s.y.abs();
        if (maxAbs == null || a > maxAbs) maxAbs = a;
      }
    }

    return _chartCard(
      title: 'الربح/الخسارة اليومية',
      subtitle: 'التغير اليومي بقيمة المحفظة',
      icon: Icons.area_chart_rounded,
      iconColor: AppColors.accent,
      child: SizedBox(
        height: 180,
        child: hasData && maxAbs != null && maxAbs > 0
            ? LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAbs * 0.5,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: deltas,
                    isCurved: false,
                    color: AppColors.accent,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final isUp = s.y >= 0;
                        return LineTooltipItem(
                          '${isUp ? '+' : ''}${_fmt(s.y)} ج.م',
                          TextStyle(
                            color: isUp
                                ? AppColors.success
                                : AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ))
            : const StateView(
                empty: true,
                emptyMessage: 'لا تتوفر بيانات يومية كافية',
              ),
      ),
    );
  }

  // ── Stock PnL (Bar chart) ──────────────────────────────────────────────
  Widget _buildStockPnLCard() {
    final bars = <BarChartGroupData>[];
    final labels = <String>[];
    double? maxAbs;

    final pnlItems = <Map<String, dynamic>>[];
    for (final h in _holdings) {
      final symbol = (h['stock_ticker'] ??
              h['ticker'] ??
              h['symbol'] ??
              h['stock_symbol'] ??
              '—')
          .toString();
      final pnl = _toDouble(h['unrealized_pnl'] ??
          h['pnl'] ??
          h['gain'] ??
          h['profit_loss']);
      pnlItems.add({'symbol': symbol, 'pnl': pnl});
      final a = pnl.abs();
      if (maxAbs == null || a > maxAbs) maxAbs = a;
    }
    // Sort by abs pnl desc, take top 10
    pnlItems.sort(
        (a, b) => (b['pnl'] as double).abs().compareTo((a['pnl'] as double).abs()));
    final top = pnlItems.take(10).toList();

    for (var i = 0; i < top.length; i++) {
      final item = top[i];
      final pnl = item['pnl'] as double;
      final color = pnl >= 0 ? AppColors.success : AppColors.danger;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: pnl,
            color: color,
            width: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ));
      labels.add(item['symbol'] as String);
    }

    return _chartCard(
      title: 'ربح/خسارة كل سهم',
      subtitle: 'أعلى 10 أسهم بحسب القيمة المطلقة',
      icon: Icons.bar_chart_rounded,
      iconColor: AppColors.success,
      child: bars.isEmpty
          ? const StateView(
              empty: true,
              emptyMessage: 'لا توجد holdings لعرض ربحها/خسارتها',
            )
          : SizedBox(
              height: 220,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxAbs != null && maxAbs > 0 ? maxAbs * 0.5 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval:
                          maxAbs != null && maxAbs > 0 ? maxAbs * 0.5 : 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _compact(v),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gIdx, rod, rIdx) {
                      final pnl = rod.toY;
                      final isUp = pnl >= 0;
                      return BarTooltipItem(
                        '${isUp ? '+' : ''}${_fmt(pnl)} ج.م',
                        TextStyle(
                          color: isUp ? AppColors.success : AppColors.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
              )),
            ),
    );
  }

  // ── Risk Summary card ─────────────────────────────────────────────────
  Widget _buildRiskSummaryCard() {
    final entries = _riskSummary.entries
        .where((e) =>
            e.value is num ||
            (e.value is String &&
                double.tryParse(e.value as String) != null))
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return _chartCard(
      title: 'ملخص المخاطر',
      subtitle: 'مقاييس المخاطر الرئيسية للمحفظة',
      icon: Icons.shield_rounded,
      iconColor: AppColors.warning,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _prettyKey(e.key),
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(e.value, 2),
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _prettyKey(String k) {
    return k.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  String _compact(double v) {
    final abs = v.abs();
    if (abs >= 1_000_000) return '${(v / 1_000_000).toStringAsFixed(1)}M';
    if (abs >= 1_000) return '${(v / 1_000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  double _safeInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1.0;
    double? min;
    double? max;
    for (final s in spots) {
      if (min == null || s.y < min) min = s.y;
      if (max == null || s.y > max) max = s.y;
    }
    final range = (max ?? 0) - (min ?? 0);
    if (range <= 0) return 1.0;
    return range / 4;
  }

  Widget _legendChip(_LegendItem l) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: l.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('${l.label} ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
        Text(l.value,
            style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _chartCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTypography.titleSmall),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final String value;
  final Color color;
  const _LegendItem({
    required this.label,
    required this.value,
    required this.color,
  });
}
