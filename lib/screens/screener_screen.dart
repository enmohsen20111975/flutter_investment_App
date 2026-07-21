// ============================================================================
// مساعد الاستثمار Flutter - Screener Screen (Multi-chart grid)
// Displays multiple mini candlestick/line charts in a grid
// API: /api/v2/recommend?market=EGX&limit=20
// ============================================================================

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import 'trading_chart_screen.dart';

class ScreenerScreen extends StatefulWidget {
  final int marketVersion;

  const ScreenerScreen({super.key, this.marketVersion = 0});

  @override
  State<ScreenerScreen> createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen>
    with AutomaticKeepAliveClientMixin {
  String _selectedMarket = 'EGX';
  final List<String> _markets = const ['EGX', 'TADAWUL', 'KSE', 'QSE', 'DFM', 'ADX'];
  Future<List<_ScreenerItem>>? _itemsFuture;
  String _sortMode = 'score'; // score | change | ticker

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ScreenerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final market = prefs.getString('active_market') ?? 'EGX';
    if (mounted) {
      setState(() {
        _selectedMarket = _markets.contains(market) ? market : 'EGX';
        _itemsFuture = _fetchItems();
      });
    }
  }

  Future<List<_ScreenerItem>> _fetchItems() async {
    try {
      final raw = await api.getHunterScreener(
        market: _selectedMarket,
        limit: 20,
      );
      final items = <_ScreenerItem>[];
      for (final e in raw) {
        if (e is Map) {
          items.add(_ScreenerItem.fromMap(Map<String, dynamic>.from(e)));
        }
      }
      // Build synthetic OHLC mini series from current price + change %
      // so the grid shows visual movement without extra round-trips.
      final rng = math.Random(42);
      for (final item in items) {
        item.series = _synthesizeSeries(item, rng);
      }
      _applySort(items);
      return items;
    } catch (_) {
      return <_ScreenerItem>[];
    }
  }

  List<_MiniPoint> _synthesizeSeries(_ScreenerItem item, math.Random rng) {
    final base = item.currentPrice ?? item.entryPrice ?? 10.0;
    final changePct = item.changePercent;
    final trend = changePct == null
        ? (rng.nextDouble() - 0.5) * 2
        : changePct.clamp(-12, 12).toDouble();
    final points = <_MiniPoint>[];
    var price = base / (1 + (trend / 100));
    for (var i = 0; i < 16; i++) {
      final noise = (rng.nextDouble() - 0.5) * base * 0.02;
      final drift = (trend / 100) * base / 16;
      price = (price + drift + noise).clamp(base * 0.6, base * 1.6);
      points.add(_MiniPoint(i.toDouble(), price));
    }
    points.add(_MiniPoint(16.toDouble(), base));
    return points;
  }

  void _applySort(List<_ScreenerItem> items) {
    switch (_sortMode) {
      case 'change':
        items.sort((a, b) =>
            (b.changePercent ?? -999).compareTo(a.changePercent ?? -999));
        break;
      case 'ticker':
        items.sort((a, b) => a.ticker.compareTo(b.ticker));
        break;
      default:
        items.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _fetchItems();
    });
  }

  Future<void> _changeMarket(String market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_market', market);
    setState(() {
      _selectedMarket = market;
      _itemsFuture = _fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('المسح المتعدد - Screener',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort_rounded, color: AppColors.text),
              onSelected: (val) {
                setState(() => _sortMode = val);
                _refresh();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'score', child: Text('حسب النقاط')),
                PopupMenuItem(value: 'change', child: Text('حسب التغير %')),
                PopupMenuItem(value: 'ticker', child: Text('حسب الاسم')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Market chips + hero header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.grid_view_rounded, color: AppColors.white, size: 20),
                      SizedBox(width: 8),
                      Text('مسح سريع للأسهم',
                          style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Spacer(),
                      Text('20 سهم',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _markets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final m = _markets[index];
                        final active = m == _selectedMarket;
                        return GestureDetector(
                          onTap: () => _changeMarket(m),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              m,
                              style: TextStyle(
                                color: active ? AppColors.primary : AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_ScreenerItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonGrid();
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'فشل تحميل بيانات المسح', onRetry: _refresh);
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const StateView(
                      empty: true,
                      emptyMessage: 'لا توجد أسهم متاحة للمسح حالياً',
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _refresh,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: items.length,
                      cacheExtent: 800,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return RepaintBoundary(
                          child: _ScreenerTile(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TradingChartScreen(
                                    ticker: item.ticker,
                                    displayName: item.displayName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const SkeletonCard(height: 160),
    );
  }
}

// ============================================================================
// Screener Tile - mini chart card
// ============================================================================
class _ScreenerTile extends StatelessWidget {
  final _ScreenerItem item;
  final VoidCallback onTap;

  const _ScreenerTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUp = (item.changePercent ?? 0) >= 0;
    final changeColor = isUp ? AppColors.chartUp : AppColors.chartDown;
    return Hero(
      tag: 'screener-${item.ticker}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceMuted],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.ticker,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _scoreColor(item.score!).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.score!.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(item.score!),
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.displayName.isNotEmpty &&
                    item.displayName != item.ticker) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.displayName,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Expanded(
                  child: RepaintBoundary(
                    child: _MiniLineChart(
                      series: item.series,
                      color: changeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item.currentPrice != null
                          ? item.currentPrice!.toStringAsFixed(2)
                          : '--',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}${item.changePercent?.toStringAsFixed(2) ?? '0.00'}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: changeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 90) return const Color(0xFFFFD700);
    if (score >= 80) return AppColors.success;
    if (score >= 70) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.textMuted;
  }
}

// ============================================================================
// Mini Line Chart - lightweight sparkline
// ============================================================================
class _MiniLineChart extends StatelessWidget {
  final List<_MiniPoint> series;
  final Color color;

  const _MiniLineChart({required this.series, required this.color});

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(
        child: Icon(Icons.show_chart, color: AppColors.textMuted, size: 20),
      );
    }
    final spots = series
        .map((p) => FlSpot(p.x, p.y))
        .toList(growable: false);
    final ys = series.map((p) => p.y).toList(growable: false);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final range = (maxY - minY).clamp(0.0001, double.infinity);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: minY - range * 0.05,
        maxY: maxY + range * 0.05,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 1.8,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.30),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Models
// ============================================================================
class _ScreenerItem {
  final String ticker;
  final String displayName;
  final double? currentPrice;
  final double? entryPrice;
  final double? changePercent;
  final double? score;
  final String signal;
  List<_MiniPoint> series;

  _ScreenerItem({
    required this.ticker,
    required this.displayName,
    required this.currentPrice,
    required this.entryPrice,
    required this.changePercent,
    required this.score,
    required this.signal,
    required this.series,
  });

  factory _ScreenerItem.fromMap(Map<String, dynamic> m) {
    final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString();
    final name = (m['name'] ?? m['company'] ?? '').toString();
    final nameAr = (m['name_ar'] ?? m['nameAr'] ?? '').toString();
    return _ScreenerItem(
      ticker: ticker,
      displayName: nameAr.isNotEmpty ? nameAr : (name.isNotEmpty ? name : ticker),
      currentPrice: _toDouble(m['current_price'] ?? m['price'] ?? m['last_price']),
      entryPrice: _toDouble(m['entry_price']),
      changePercent: _toDouble(m['change_percent'] ?? m['changePercent'] ?? m['change']),
      score: _toDouble(m['score'] ?? m['maestro_score']),
      signal: (m['signal'] ?? m['recommendation'] ?? 'HOLD').toString(),
      series: const <_MiniPoint>[],
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

class _MiniPoint {
  final double x;
  final double y;
  const _MiniPoint(this.x, this.y);
}
