// ============================================================================
// مساعد الاستثمار Flutter - Smart Confluence Screen
// Advanced multi-factor confluence analysis on the active market
// API: /api/v2/recommend?market=EGX + /api/confluence/market-scan
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class SmartConfluenceScreen extends StatefulWidget {
  const SmartConfluenceScreen({super.key});

  @override
  State<SmartConfluenceScreen> createState() => _SmartConfluenceScreenState();
}

class _SmartConfluenceScreenState extends State<SmartConfluenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMarket = 'EGX';
  final List<String> _markets = const ['EGX', 'TADAWUL', 'KSE', 'QSE', 'DFM'];
  Future<List<_ConfluenceItem>>? _itemsFuture;
  Map<String, dynamic>? _scanSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString('active_market') ?? 'EGX';
    if (mounted) {
      setState(() {
        _selectedMarket = _markets.contains(m) ? m : 'EGX';
        _itemsFuture = _fetchItems();
      });
    }
  }

  Future<List<_ConfluenceItem>> _fetchItems() async {
    final items = <_ConfluenceItem>[];
    // 1) Confluence market scan (advanced multi-factor)
    try {
      final scan = await api.getConfluenceMarketScan(market: _selectedMarket);
      _scanSummary = scan;
      final rawItems = scan['items'] ??
          scan['results'] ??
          scan['stocks'] ??
          scan['recommendations'] ??
          scan['data'];
      if (rawItems is List) {
        for (final e in rawItems) {
          if (e is Map) {
            items.add(_ConfluenceItem.fromMap(Map<String, dynamic>.from(e)));
          }
        }
      }
    } catch (_) {
      _scanSummary = null;
    }
    // 2) Fallback: stitch from /api/v2/recommend
    if (items.isEmpty) {
      try {
        final raw = await api.getHunterScreener(market: _selectedMarket, limit: 12);
        for (final e in raw) {
          if (e is Map) {
            items.add(_ConfluenceItem.fromMap(Map<String, dynamic>.from(e)));
          }
        }
      } catch (_) {}
    }
    // Sort by confluence score
    items.sort((a, b) => (b.score).compareTo(a.score));
    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _fetchItems();
    });
  }

  Future<void> _changeMarket(String market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_market', market);
    setState(() => _selectedMarket = market);
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
              expandedHeight: 150,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            child: const Icon(Icons.hub_rounded,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('التلاقي الذكي',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('تحليل متعدد العوامل',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
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
                      _buildMarketChips(),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<_ConfluenceItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      children: [
                        SkeletonCard(height: 100),
                        SizedBox(height: 8),
                        SkeletonList(itemCount: 4, itemHeight: 130),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'فشل تحليل التلاقي', onRetry: _refresh);
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const StateView(
                      empty: true,
                      emptyMessage: 'لا توجد فرص تلاقي متاحة حالياً',
                    );
                  }
                  return Column(
                    children: [
                      _buildSummaryHeader(items),
                      const SizedBox(height: 4),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(icon: Icon(Icons.list_rounded, size: 18), text: 'الفرص'),
                    Tab(
                        icon: Icon(Icons.stacked_bar_chart_rounded, size: 18),
                        text: 'العوامل'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: FutureBuilder<List<_ConfluenceItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SkeletonList(itemCount: 4, itemHeight: 130);
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOpportunitiesTab(items),
                      _buildFactorsTab(items),
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

  Widget _buildMarketChips() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _markets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final m = _markets[index];
          final active = m == _selectedMarket;
          return GestureDetector(
            onTap: () => _changeMarket(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<_ConfluenceItem> items) {
    final highConviction =
        items.where((i) => i.score >= 75).length;
    final avgScore = items.isEmpty
        ? 0.0
        : items.map((i) => i.score).reduce((a, b) => a + b) / items.length;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceMuted],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell('إجمالي الفرص', '${items.length}',
                AppColors.primary, Icons.list_alt_rounded),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _summaryCell('ثقة عالية', '$highConviction',
                AppColors.success, Icons.verified_rounded),
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          Expanded(
            child: _summaryCell('متوسط النقاط', avgScore.toStringAsFixed(0),
                AppColors.accent, Icons.trending_up_rounded),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildOpportunitiesTab(List<_ConfluenceItem> items) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        itemCount: items.length,
        cacheExtent: 600,
        itemBuilder: (context, index) {
          final item = items[index];
          return RepaintBoundary(
            child: _OpportunityCard(item: item),
          );
        },
      ),
    );
  }

  Widget _buildFactorsTab(List<_ConfluenceItem> items) {
    // Aggregate factors across all items
    final factorCounts = <String, int>{};
    for (final item in items) {
      for (final f in item.factors) {
        final key = f.name;
        factorCounts[key] = (factorCounts[key] ?? 0) + 1;
      }
    }
    final sortedFactors = factorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedFactors.isEmpty) {
      return const Center(
        child: Text('لا توجد عوامل متاحة',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }
    final maxCount = sortedFactors.first.value;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedFactors.length,
      itemBuilder: (context, index) {
        final entry = sortedFactors[index];
        final pct = maxCount > 0 ? entry.value / maxCount : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
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
                  Expanded(
                    child: Text(entry.key,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  Text('${entry.value} سهم',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.05, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Opportunity Card
// ============================================================================
class _OpportunityCard extends StatelessWidget {
  final _ConfluenceItem item;

  const _OpportunityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(item.score);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.4),
          width: item.score >= 80 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: (item.score / 100).clamp(0.0, 1.0),
                        strokeWidth: 4,
                        backgroundColor: AppColors.surfaceMuted,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      item.score.toInt().toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.ticker,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    if (item.displayName.isNotEmpty &&
                        item.displayName != item.ticker)
                      Text(item.displayName,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _signalColor(item.signal).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(_signalLabel(item.signal),
                    style: TextStyle(
                      color: _signalColor(item.signal),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
          if (item.factors.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('عوامل التلاقي',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.factors.map((f) {
                final tone = f.tone;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _toneColor(tone).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_toneIcon(tone),
                          size: 12, color: _toneColor(tone)),
                      const SizedBox(width: 4),
                      Text(f.name,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _toneColor(tone))),
                      if (f.value.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text('(${f.value})',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          if (item.entryPrice != null || item.targetPrice != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (item.entryPrice != null)
                  Expanded(
                      child: _priceCol('الدخول',
                          item.entryPrice!.toStringAsFixed(2))),
                if (item.targetPrice != null)
                  Expanded(
                      child: _priceCol('الهدف',
                          item.targetPrice!.toStringAsFixed(2))),
                if (item.stopLoss != null)
                  Expanded(
                      child: _priceCol('وقف الخسارة',
                          item.stopLoss!.toStringAsFixed(2))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Color _scoreColor(double score) {
    if (score >= 90) return const Color(0xFFFFD700);
    if (score >= 80) return AppColors.success;
    if (score >= 70) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.textMuted;
  }

  Color _signalColor(String signal) {
    final s = signal.toUpperCase();
    if (s.contains('BUY')) return AppColors.success;
    if (s.contains('SELL')) return AppColors.danger;
    return AppColors.warning;
  }

  String _signalLabel(String signal) {
    final s = signal.toUpperCase().replaceAll(' ', '_');
    switch (s) {
      case 'STRONG_BUY':
        return 'شراء قوي';
      case 'BUY':
        return 'شراء';
      case 'STRONG_SELL':
        return 'بيع قوي';
      case 'SELL':
        return 'بيع';
      case 'HOLD':
        return 'احتفاظ';
      case 'ACCUMULATE':
        return 'تجميع';
      default:
        return signal;
    }
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
// Models
// ============================================================================
class _ConfluenceItem {
  final String ticker;
  final String displayName;
  final double score;
  final String signal;
  final double? entryPrice;
  final double? targetPrice;
  final double? stopLoss;
  final List<_Factor> factors;

  _ConfluenceItem({
    required this.ticker,
    required this.displayName,
    required this.score,
    required this.signal,
    required this.entryPrice,
    required this.targetPrice,
    required this.stopLoss,
    required this.factors,
  });

  factory _ConfluenceItem.fromMap(Map<String, dynamic> m) {
    final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString();
    final name = (m['name'] ?? m['company'] ?? '').toString();
    final nameAr = (m['name_ar'] ?? m['nameAr'] ?? '').toString();
    final score = _toDouble(m['score'] ??
            m['confluence_score'] ??
            m['maestro_score'] ??
            m['confidence']) ??
        0;
    final signal =
        (m['signal'] ?? m['recommendation'] ?? 'HOLD').toString();
    // Factors
    final factors = <_Factor>[];
    final rawFactors = m['factors'] ?? m['signals'] ?? m['reasons'];
    if (rawFactors is List) {
      for (final f in rawFactors) {
        if (f is Map) {
          final fm = Map<String, dynamic>.from(f);
          factors.add(_Factor(
            name: (fm['name'] ?? fm['factor'] ?? fm['signal'] ?? '').toString(),
            value: (fm['value'] ?? '').toString(),
            tone: _toneFromValue(fm['tone'] ?? fm['type'] ?? fm['signal']),
          ));
        } else {
          factors.add(_Factor(
            name: f.toString(),
            value: '',
            tone: 'default',
          ));
        }
      }
    } else if (rawFactors is Map) {
      rawFactors.forEach((k, v) {
        factors.add(_Factor(
          name: k.toString(),
          value: v?.toString() ?? '',
          tone: _toneFromValue(v),
        ));
      });
    }
    // If no factors but match_reasons present
    if (factors.isEmpty) {
      final reasons = m['match_reasons'] ?? m['reasoning'];
      if (reasons is List) {
        for (final r in reasons) {
          factors.add(_Factor(
            name: r.toString(),
            value: '',
            tone: 'info',
          ));
        }
      }
    }
    return _ConfluenceItem(
      ticker: ticker,
      displayName: nameAr.isNotEmpty ? nameAr : (name.isNotEmpty ? name : ticker),
      score: score,
      signal: signal,
      entryPrice: _toDouble(m['entry_price'] ?? m['current_price']),
      targetPrice: _toDouble(m['target_price']),
      stopLoss: _toDouble(m['stop_loss']),
      factors: factors,
    );
  }

  static String _toneFromValue(dynamic v) {
    final s = v?.toString().toLowerCase() ?? '';
    if (s.contains('buy') || s.contains('bull') || s.contains('pos'))
      return 'success';
    if (s.contains('sell') || s.contains('bear') || s.contains('neg'))
      return 'danger';
    if (s.contains('hold') || s.contains('neutral')) return 'warning';
    if (s.contains('info')) return 'info';
    return 'default';
  }
}

class _Factor {
  final String name;
  final String value;
  final String tone;
  const _Factor({
    required this.name,
    required this.value,
    required this.tone,
  });
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
