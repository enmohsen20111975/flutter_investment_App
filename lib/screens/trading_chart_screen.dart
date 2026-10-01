// ============================================================================
// مساعد الاستثمار Flutter - Trading Chart Screen (Interactive Full View)
// Full TradingView chart + sidebar with technical analysis
// API: /api/v2/chart/full-analysis?ticker=X&timeframe=MONTH&limit=30
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/price_chart.dart' as pc;
import '../models/chart_data_model.dart';

class TradingChartScreen extends StatefulWidget {
  final String ticker;
  final String? displayName;

  const TradingChartScreen({
    super.key,
    required this.ticker,
    this.displayName,
  });

  @override
  State<TradingChartScreen> createState() => _TradingChartScreenState();
}

class _TradingChartScreenState extends State<TradingChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeframe = 'MONTH';
  Future<Map<String, dynamic>>? _dataFuture;
  pc.ChartType _chartType = pc.ChartType.candle;

  static const List<_TimeframeOption> _timeframes = [
    _TimeframeOption('DAY', 'يومي', '1D'),
    _TimeframeOption('WEEK', 'أسبوعي', '1W'),
    _TimeframeOption('MONTH', 'شهري', '1M'),
    _TimeframeOption('QUARTER', 'ربع سنوي', '3M'),
    _TimeframeOption('YEAR', 'سنوي', '1Y'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dataFuture = _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    return api.getChartFullAnalysis(
      ticker: widget.ticker,
      timeframe: _timeframe,
      limit: 30,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  Future<void> _changeTimeframe(String tf) async {
    if (tf == _timeframe) return;
    setState(() => _timeframe = tf);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 110,
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
                  padding: const EdgeInsets.fromLTRB(16, 38, 16, 12),
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
                          Expanded(
                            child: Hero(
                              tag: 'screener-${widget.ticker}',
                              child: Material(
                                color: Colors.transparent,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.ticker,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (widget.displayName != null &&
                                        widget.displayName!.isNotEmpty)
                                      Text(
                                        widget.displayName!,
                                        style: TextStyle(
                                          color: AppColors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.white),
                  onPressed: _refresh,
                  tooltip: 'تحديث',
                ),
              ],
            ),
            // Timeframe selector
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: _timeframes.map((tf) {
                    final active = tf.value == _timeframe;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _changeTimeframe(tf.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tf.short,
                            style: TextStyle(
                              color: active
                                  ? AppColors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      children: [
                        SkeletonChart(height: 320),
                        SizedBox(height: 8),
                        SkeletonCard(height: 160),
                        SizedBox(height: 8),
                        SkeletonCard(height: 120),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'فشل تحميل بيانات الشارت', onRetry: _refresh);
                  }
                  final data = snapshot.data ?? {};
                  if (data.isEmpty) {
                    return const StateView(
                      empty: true,
                      emptyMessage: 'لا توجد بيانات تحليل متاحة لهذا السهم',
                    );
                  }
                  final parsed = _FullAnalysisData.fromMap(data);
                  return Column(
                    children: [
                      _buildChartSection(parsed),
                      const SizedBox(height: 8),
                      _buildPriceHeader(parsed),
                      _buildTabs(parsed),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Chart section
  // ===========================================================================
  Widget _buildChartSection(_FullAnalysisData data) {
    final candles = data.candles;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Chart type switcher
          Row(
            children: [
              _ChartTypeChip(
                label: 'شموع',
                active: _chartType == pc.ChartType.candle,
                onTap: () => setState(() => _chartType = pc.ChartType.candle),
              ),
              const SizedBox(width: 6),
              _ChartTypeChip(
                label: 'خط',
                active: _chartType == pc.ChartType.line,
                onTap: () => setState(() => _chartType = pc.ChartType.line),
              ),
              const SizedBox(width: 6),
              _ChartTypeChip(
                label: 'مساحة',
                active: _chartType == pc.ChartType.area,
                onTap: () => setState(() => _chartType = pc.ChartType.area),
              ),
              const Spacer(),
              Text(
                '${candles.length} شمعة',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RepaintBoundary(
            child: SizedBox(
              height: 320,
              child: candles.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد بيانات شموع متاحة',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : _NativeMiniChart(
                      candles: candles,
                      type: _chartType,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Price header
  // ===========================================================================
  Widget _buildPriceHeader(_FullAnalysisData data) {
    final price = data.currentPrice;
    final change = data.changePercent;
    final isUp = (change ?? 0) >= 0;
    final color = isUp ? AppColors.chartUp : AppColors.chartDown;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            AppColors.surface,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('السعر الحالي',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(
                  price != null ? price.toStringAsFixed(2) : '--',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (change != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(
                    isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tabs (analysis sidebar)
  // ===========================================================================
  Widget _buildTabs(_FullAnalysisData data) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'المؤشرات'),
              Tab(text: 'الإشارات'),
              Tab(text: 'الدعم والمقاومة'),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIndicatorsTab(data),
                _buildSignalsTab(data),
                _buildLevelsTab(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsTab(_FullAnalysisData data) {
    final indicators = data.indicators;
    if (indicators.isEmpty) {
      return const Center(
          child: Text('لا توجد مؤشرات', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: indicators.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final ind = indicators[index];
        final value = ind.value;
        final tone = ind.tone;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          title: Text(ind.name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(ind.note,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMuted)),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _toneColor(tone).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: _toneColor(tone),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignalsTab(_FullAnalysisData data) {
    final signals = data.signals;
    if (signals.isEmpty) {
      return const Center(
          child: Text('لا توجد إشارات', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: signals.length,
      itemBuilder: (context, index) {
        final sig = signals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border(
              right: BorderSide(color: _toneColor(sig.tone), width: 3),
            ),
          ),
          child: Row(
            children: [
              Icon(_toneIcon(sig.tone), color: _toneColor(sig.tone), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sig.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    if (sig.detail.isNotEmpty)
                      Text(sig.detail,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelsTab(_FullAnalysisData data) {
    final supports = data.supports;
    final resistances = data.resistances;
    if (supports.isEmpty && resistances.isEmpty) {
      return const Center(
          child: Text('لا توجد مستويات', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('مستويات المقاومة',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.danger)),
        const SizedBox(height: 6),
        ...resistances.map((l) => _LevelRow(level: l, isSupport: false)),
        const SizedBox(height: 12),
        const Text('مستويات الدعم',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.success)),
        const SizedBox(height: 6),
        ...supports.map((l) => _LevelRow(level: l, isSupport: true)),
      ],
    );
  }

  Color _toneColor(String tone) {
    switch (tone) {
      case 'success':
        return AppColors.success;
      case 'danger':
        return AppColors.danger;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  IconData _toneIcon(String tone) {
    switch (tone) {
      case 'success':
        return Icons.check_circle_outline;
      case 'danger':
        return Icons.cancel_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ============================================================================
// Native Mini Chart - lightweight candle/line/area renderer
// ============================================================================
class _NativeMiniChart extends StatelessWidget {
  final List<ChartDataModel> candles;
  final pc.ChartType type;

  const _NativeMiniChart({required this.candles, required this.type});

  @override
  Widget build(BuildContext context) {
    return pc.PriceChart(
      data: candles,
      type: type,
      showVolume: false,
      showGrid: true,
    );
  }
}

// ============================================================================
// Chart type chip
// ============================================================================
class _ChartTypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ChartTypeChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Level row
// ============================================================================
class _LevelRow extends StatelessWidget {
  final _Level level;
  final bool isSupport;

  const _LevelRow({required this.level, required this.isSupport});

  @override
  Widget build(BuildContext context) {
    final color = isSupport ? AppColors.success : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isSupport ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              level.label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Text(
            level.value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Models
// ============================================================================
class _TimeframeOption {
  final String value;
  final String label;
  final String short;
  const _TimeframeOption(this.value, this.label, this.short);
}

class _FullAnalysisData {
  final double? currentPrice;
  final double? changePercent;
  final List<ChartDataModel> candles;
  final List<_Indicator> indicators;
  final List<_Signal> signals;
  final List<_Level> supports;
  final List<_Level> resistances;

  _FullAnalysisData({
    required this.currentPrice,
    required this.changePercent,
    required this.candles,
    required this.indicators,
    required this.signals,
    required this.supports,
    required this.resistances,
  });

  factory _FullAnalysisData.fromMap(Map<String, dynamic> m) {
    final data = m['data'] is Map ? Map<String, dynamic>.from(m['data']) : m;
    // Candles
    final rawCandles = data['candles'] ??
        data['chart_data'] ??
        data['ohlc'] ??
        data['series'] ??
        (m['candles'] ?? m['chart_data']);
    List<ChartDataModel> candles = [];
    if (rawCandles is List) {
      for (final c in rawCandles) {
        if (c is Map) {
          candles.add(ChartDataModel.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    // Current price
    final price = _toDouble(data['current_price'] ??
        data['price'] ??
        data['last_price'] ??
        (candles.isNotEmpty ? candles.last.close : null));
    final change = _toDouble(data['change_percent'] ??
        data['changePercent'] ??
        data['change']);
    // Indicators
    final rawInd = data['indicators'] ?? data['technical_indicators'];
    List<_Indicator> indicators = [];
    if (rawInd is Map) {
      rawInd.forEach((k, v) {
        if (v is Map) {
          indicators.add(_Indicator(
            name: k.toString(),
            value: v['value']?.toString() ?? v['signal']?.toString() ?? '--',
            tone: _toneFromValue(v['signal'] ?? v['tone']),
            note: v['note']?.toString() ?? '',
          ));
        } else {
          indicators.add(_Indicator(
            name: k.toString(),
            value: v?.toString() ?? '--',
            tone: 'default',
            note: '',
          ));
        }
      });
    } else if (rawInd is List) {
      for (final e in rawInd) {
        if (e is Map) {
          final im = Map<String, dynamic>.from(e);
          indicators.add(_Indicator(
            name: (im['name'] ?? im['indicator'] ?? '').toString(),
            value: (im['value'] ?? im['signal'] ?? '--').toString(),
            tone: _toneFromValue(im['signal'] ?? im['tone']),
            note: (im['note'] ?? im['description'] ?? '').toString(),
          ));
        }
      }
    }
    // Signals
    final rawSig = data['signals'] ?? data['analysis_signals'];
    List<_Signal> signals = [];
    if (rawSig is List) {
      for (final e in rawSig) {
        if (e is Map) {
          final sm = Map<String, dynamic>.from(e);
          signals.add(_Signal(
            name: (sm['name'] ?? sm['title'] ?? '').toString(),
            detail: (sm['detail'] ?? sm['description'] ?? '').toString(),
            tone: _toneFromValue(sm['tone'] ?? sm['type']),
          ));
        }
      }
    }
    // Levels
    final rawSup = data['supports'] ?? data['support_levels'];
    final rawRes = data['resistances'] ?? data['resistance_levels'];
    List<_Level> supports = _parseLevels(rawSup);
    List<_Level> resistances = _parseLevels(rawRes);

    return _FullAnalysisData(
      currentPrice: price,
      changePercent: change,
      candles: candles,
      indicators: indicators,
      signals: signals,
      supports: supports,
      resistances: resistances,
    );
  }

  static List<_Level> _parseLevels(dynamic raw) {
    final list = <_Level>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is num) {
          list.add(_Level(label: 'مستوى', value: e.toDouble()));
        } else if (e is Map) {
          final lm = Map<String, dynamic>.from(e);
          list.add(_Level(
            label: (lm['label'] ?? lm['name'] ?? 'مستوى').toString(),
            value: _toDouble(lm['price'] ?? lm['value'] ?? lm['level']) ?? 0,
          ));
        }
      }
    }
    return list;
  }

  static String _toneFromValue(dynamic v) {
    final s = v?.toString().toLowerCase() ?? '';
    if (s.contains('buy') || s.contains('bull')) return 'success';
    if (s.contains('sell') || s.contains('bear')) return 'danger';
    if (s.contains('hold') || s.contains('neutral')) return 'warning';
    if (s.contains('info')) return 'info';
    return 'default';
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _Indicator {
  final String name;
  final String value;
  final String tone;
  final String note;
  const _Indicator({
    required this.name,
    required this.value,
    required this.tone,
    required this.note,
  });
}

class _Signal {
  final String name;
  final String detail;
  final String tone;
  const _Signal({required this.name, required this.detail, required this.tone});
}

class _Level {
  final String label;
  final double value;
  const _Level({required this.label, required this.value});
}
