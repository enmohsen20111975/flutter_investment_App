// ============================================================================
// مساعد الاستثمار Flutter - Dashboard Screen
// Single /api/mobile/dashboard endpoint with live updates
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/mobile_api.dart';
import '../api/client.dart';
import '../models/json_helpers.dart';
import '../models/market.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/app_card.dart';
import '../services/polling_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hunter_screen.dart';

class DashboardScreen extends StatefulWidget {
  final int marketVersion;

  const DashboardScreen({super.key, this.marketVersion = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Future<Map<String, dynamic>>? _dashboardFuture;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _goldData;
  Map<String, dynamic>? _currencyData;
  late TabController _topMoversTabController;
  StreamSubscription<Map<String, dynamic>>? _pollingSubscription;

  // Explosive-opportunities preview (GAP 5).
  Future<List<Map<String, dynamic>>>? _explosiveFuture;
  // 3-persona quick-switch (GAP 5).
  String _selectedPersona = 'balanced';

  @override
  void initState() {
    super.initState();
    _topMoversTabController = TabController(length: 3, vsync: this);
    _dashboardFuture = _fetchDashboard();
    _explosiveFuture = _fetchExplosivePreview();
    _startPolling();
  }

  @override
  void dispose() {
    _topMoversTabController.dispose();
    _pollingSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _refresh();
    }
  }

  void _startPolling() {
    _pollingSubscription?.cancel();
    _pollingSubscription = pollingService.dashboardStream.listen((data) {
      if (mounted) {
        setState(() {
          _dashboardData = data;
        });
      }
    });
    pollingService.startDashboardPolling();
  }

   static Map<String, dynamic>? _safeAsMap(dynamic value) {
     if (value is Map<String, dynamic>) return value;
     if (value is Map) return Map<String, dynamic>.from(value);
     return null;
   }

   Future<Map<String, dynamic>> _fetchDashboard() async {
     try {
       SharedPreferences? prefs;
       try {
         prefs = await SharedPreferences.getInstance();
       } catch (_) {}
       final market = prefs?.getString('active_market') ?? 'EGX';

       // Fetch gold and currency data in parallel with dashboard
       final goldFuture = api.getGold();
       final currencyFuture = api.getCurrencyList();

       // 1) Try the unified mobile dashboard endpoint first
       try {
         final data = await mobileApi.getDashboard(market: market);
         if (data.isNotEmpty &&
             (data['indices'] != null ||
                 data['market_indices'] != null ||
                 data['market_summary'] != null ||
                 data['top_movers'] != null ||
                 data['top_gainers'] != null)) {
           _dashboardData = data;
           return data;
         }
         debugPrint('[Dashboard] Primary endpoint returned empty/unusable data');
       } catch (e) {
         debugPrint('[Dashboard] Primary endpoint failed: $e');
       }

       // 2) Fallback: stitch dashboard from individual working endpoints
       debugPrint('[Dashboard] Falling back to individual endpoints...');
       final results = await Future.wait([
         api.getMarketOverview(market),
         api.getMarketLiveData(market),
       ]);

       final overview = results[0] as MarketOverview;
       final liveData = results[1] as Map<String, dynamic>;

       final indices = (overview.indices ?? <MarketIndex>[])
           .map((i) => <String, dynamic>{
                 'name': i.name ?? i.nameAr ?? i.symbol,
                 'value': i.value,
                 'change_percent': i.changePercent,
               })
           .toList();

       final summary = overview.summary;
       final marketSummary = summary != null
           ? <String, dynamic>{
               'advances': summary.gainers ?? 0,
               'declines': summary.losers ?? 0,
               'unchanged': summary.unchanged ?? 0,
             }
           : null;

       final topMovers = <String, dynamic>{
         'gainers': (overview.topGainers ?? <MarketStock>[])
             .map((s) => <String, dynamic>{
                   'ticker': s.ticker,
                   'price': s.currentPrice,
                   'change_percent': s.changePercent,
                 })
             .toList(),
         'losers': (overview.topLosers ?? <MarketStock>[])
             .map((s) => <String, dynamic>{
                   'ticker': s.ticker,
                   'price': s.currentPrice,
                   'change_percent': s.changePercent,
                 })
             .toList(),
         'most_active': (overview.mostActive ?? <MarketStock>[])
             .map((s) => <String, dynamic>{
                   'ticker': s.ticker,
                   'price': s.currentPrice,
                   'change_percent': s.changePercent,
                 })
             .toList(),
       };

       // Now await gold and currency data (already started in parallel)
       final goldResult = await goldFuture;
       final currencyResult = await currencyFuture;

        _goldData = _safeAsMap(goldResult) ??
            (goldResult is List && goldResult.isNotEmpty
                ? {'gold_prices': goldResult}
                : null);
        _currencyData = _safeAsMap(currencyResult) ??
            (currencyResult is List && currencyResult.isNotEmpty
                ? {'currency_rates': currencyResult}
                : null);

       final combined = <String, dynamic>{
         if (indices.isNotEmpty) 'indices': indices,
         if (marketSummary != null) 'market_summary': marketSummary,
         if ((topMovers['gainers'] as List).isNotEmpty ||
             (topMovers['losers'] as List).isNotEmpty) 'top_movers': topMovers,
         if (liveData['gold_prices'] != null) 'gold_prices': liveData['gold_prices'],
         if (liveData['currency_rates'] != null) 'currency_rates': liveData['currency_rates'],
         if (_goldData != null) 'gold_data': _goldData,
         if (_currencyData != null) 'currency_data': _currencyData,
       };

       _dashboardData = combined;
       return combined;
     } catch (e) {
       debugPrint('[Dashboard] Fetch failed: $e');
       return {};
     }
   }

  Future<void> _refresh() async {
    await mobileApi.clearDashboardCache();
    setState(() {
      _dashboardFuture = _fetchDashboard();
      _explosiveFuture = _fetchExplosivePreview();
    });
  }

  /// Fetch top explosive opportunities for the dashboard preview card (GAP 5).
  /// Failures are swallowed — the preview card simply hides on error.
  Future<List<Map<String, dynamic>>> _fetchExplosivePreview() async {
    try {
      final payload = await api.getExplosiveOpportunities(limit: 5);
      final raw = payload['top_candidates'];
      if (raw is! List) return <Map<String, dynamic>>[];
      final out = <Map<String, dynamic>>[];
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          // Defensive bad-data filter (mirror hunter_screen).
          final m5 = _toDouble(m['momentum_5d']);
          if (m5 != null && m5.abs() > 200) continue;
          out.add(m);
        }
      }
      return out;
    } catch (e) {
      debugPrint('[Dashboard] _fetchExplosivePreview failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _dashboardData == null) {
              return const SkeletonDashboard();
            }
            if (snapshot.hasError && _dashboardData == null) {
              return StateView(error: 'فشل تحميل البيانات', onRetry: _refresh);
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.dashboard_rounded, size: 20, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text('السوق', style: AppTypography.titleSmall),
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildMiniIndices(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.trending_up_rounded, size: 20, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Text('الحركة', style: AppTypography.titleSmall),
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildMiniMovers(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.diamond_rounded, size: 20, color: AppColors.warning),
                                    const SizedBox(width: 8),
                                    Text('الذهب', style: AppTypography.titleSmall),
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildMiniGold(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(Icons.currency_exchange_rounded, size: 20, color: AppColors.info),
                                    const SizedBox(width: 8),
                                    Text('العملات', style: AppTypography.titleSmall),
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildMiniCurrency(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.show_chart_rounded, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text('أكثر ارتفاعاً وانخفاضاً', style: AppTypography.titleSmall),
                            ]),
                            const SizedBox(height: 12),
                            _buildTopMovers(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ── GAP 5: Explosive opportunities preview ──
                      _buildExplosivePreview(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(title, style: AppTypography.titleSmall),
    ]);
  }

  /// GAP 5: Explosive opportunities preview card.
  /// Shows top-3 explosive tickers (ticker + score + 3 persona dots) and a
  /// 3-persona quick-switch row (gambler/balanced/conservative). Tapping
  /// the card navigates to HunterScreen.
  Widget _buildExplosivePreview() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.bolt_rounded, size: 20, color: AppColors.warning),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('أبرز الفرص الانفجارية',
                  style: AppTypography.titleSmall),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HunterScreen())),
              child: const Text('عرض الكل',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          // 3-persona quick-switch (display-only filter that highlights which
          // persona's BUY signal the user cares about; navigation passes the
          // persona context implicitly via HunterScreen's market dropdown).
          _buildPersonaQuickSwitch(),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _explosiveFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 80,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                );
              }
              final list = snap.data ?? <Map<String, dynamic>>[];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'لا توجد فرص انفجارية حالياً',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                );
              }
              return Column(
                children: list.take(3).map((c) => _explosiveRow(c)).toList(),
              );
            },
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HunterScreen())),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: const Text(
                'افتح الصياد لمزيد من التفاصيل',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaQuickSwitch() {
    final options = <_PersonaPill>[
      _PersonaPill('gambler', '🔥 المضارب', AppColors.danger),
      _PersonaPill('balanced', '⚖️ المتوازن', AppColors.warning),
      _PersonaPill('conservative', '🛡️ المحافظ', AppColors.info),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _selectedPersona == opt.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPersona = opt.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? opt.color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  opt.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? opt.color : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _explosiveRow(Map<String, dynamic> c) {
    final ticker = c['ticker']?.toString() ?? '—';
    final score = _toDouble(c['explosive_score']) ?? 0;
    final personaMap = c['persona_predictions'] is Map
        ? Map<String, dynamic>.from(c['persona_predictions'] as Map)
        : <String, dynamic>{};
    final scoreColor = score >= 85
        ? const Color(0xFFFFD700)
        : score >= 70
            ? AppColors.success
            : score >= 55
                ? AppColors.primary
                : AppColors.warning;
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const HunterScreen())),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Expanded(
            child: Text(ticker,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
          // 3 persona dots
          _personaDot('gambler', personaMap['gambler']),
          const SizedBox(width: 6),
          _personaDot('balanced', personaMap['balanced']),
          const SizedBox(width: 6),
          _personaDot('conservative', personaMap['conservative']),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text('${score.toInt()}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scoreColor)),
          ),
        ]),
      ),
    );
  }

  Widget _personaDot(String id, dynamic pred) {
    bool wouldBuy = false;
    if (pred is Map) {
      wouldBuy = pred['would_buy'] == true || pred['would_buy'] == 1;
    }
    final color = wouldBuy ? AppColors.success : AppColors.textMuted;
    return Tooltip(
      message: id,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildTopMovers() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('أكثر الحركة', Icons.trending_up),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          TabBar(
            controller: _topMoversTabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'المرتفعة'),
              Tab(text: 'المنخفضة'),
              Tab(text: 'الأكثر نشاطاً'),
            ],
          ),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _topMoversTabController,
              children: [
                _buildMoversList(_dashboardData?['top_movers']?['gainers'] ??
                    _dashboardData?['top_gainers'] ??
                    _dashboardData?['gainers']),
                _buildMoversList(_dashboardData?['top_movers']?['losers'] ??
                    _dashboardData?['top_losers'] ??
                    _dashboardData?['losers']),
                _buildMoversList(_dashboardData?['top_movers']?['most_active'] ??
                    _dashboardData?['most_active']),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMoversList(dynamic movers) {
    if (movers is! List || movers.isEmpty) {
      return const Center(
          child: Text('لا توجد بيانات',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: movers.length > 5 ? 5 : movers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = movers[i] is Map
            ? Map<String, dynamic>.from(movers[i])
            : <String, dynamic>{};
        final ticker = m['ticker']?.toString() ?? m['symbol']?.toString() ?? '';
        final price = parseDouble(m['price'] ?? m['last_price']);
        final change = parseDouble(m['change_percent'] ?? m['change']);
        final isPositive = change != null && change >= 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
                child: Text(ticker,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12))),
            if (price != null)
              Text(price.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            if (change != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isPositive ? AppColors.success : AppColors.danger)),
              ),
          ]),
        );
      },
    );
  }

  Widget _buildMiniIndices() {
    final indices = _dashboardData?['indices'] ?? _dashboardData?['market_indices'];
    if (indices is! List || indices.isEmpty) {
      return const Text('لا توجد بيانات', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: indices.take(4).map((i) {
        final idx = i is Map ? Map<String, dynamic>.from(i) : <String, dynamic>{};
        final name = idx['name']?.toString() ?? '';
        final change = parseDouble(idx['change_percent'] ?? idx['change']) ?? 0;
        final isPositive = change >= 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (isPositive ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$name ${change.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isPositive ? AppColors.success : AppColors.danger),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniMovers() {
    final movers = _dashboardData?['top_movers'] ?? _dashboardData?['top_gainers'] ?? _dashboardData?['gainers'];
    if (movers is! List || movers.isEmpty) {
      return const Text('لا توجد بيانات', style: TextStyle(fontSize: 12, color: AppColors.textMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: movers.take(3).map((m) {
        final map = m is Map ? Map<String, dynamic>.from(m) : <String, dynamic>{};
        final ticker = map['ticker']?.toString() ?? map['symbol']?.toString() ?? '';
        final change = parseDouble(map['change_percent'] ?? map['change']) ?? 0;
        final isPositive = change >= 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticker, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 11, color: isPositive ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniGold() {
    final rawGold = _goldData?['gold_prices'] ?? _goldData?['gold'] ?? _goldData?['items'];
    if (rawGold == null) return const Text('جاري التحميل...', style: TextStyle(fontSize: 12, color: AppColors.textMuted));

    List<Map<String, dynamic>> gold = [];
    if (rawGold is List) {
      gold = rawGold.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (rawGold is Map) {
      final map = Map<String, dynamic>.from(rawGold);
      final entries = map.entries.take(3);
      for (final entry in entries) {
        gold.add({'karat': entry.key, 'price': entry.value});
      }
    }

    if (gold.isEmpty) return const Text('لا توجد بيانات', style: TextStyle(fontSize: 12, color: AppColors.textMuted));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: gold.take(2).map((g) {
        final karat = g['karat']?.toString() ?? '';
        final price = parseDouble(g['price']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(karat, style: const TextStyle(fontSize: 11)),
              if (price != null)
                Text('${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniCurrency() {
    final rawRates = _currencyData?['currency_rates'] ?? _currencyData?['currencies'] ?? _currencyData?['rates'] ?? _currencyData?['items'];
    if (rawRates == null) return const Text('جاري التحميل...', style: TextStyle(fontSize: 12, color: AppColors.textMuted));

    List<Map<String, dynamic>> ratesList = [];
    if (rawRates is List) {
      ratesList = rawRates.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (rawRates is Map) {
      rawRates.forEach((key, value) {
        if (value is Map) {
          ratesList.add({'code': key, 'rate': value['rate'] ?? value['buy'] ?? value['buy_rate']});
        } else {
          ratesList.add({'code': key, 'rate': value});
        }
      });
    }

    if (ratesList.isEmpty) return const Text('لا توجد بيانات', style: TextStyle(fontSize: 12, color: AppColors.textMuted));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ratesList.take(2).map((r) {
        final code = r['code']?.toString() ?? r['currency']?.toString() ?? '';
        final rate = parseDouble(r['rate'] ?? r['buy'] ?? r['buy_rate'] ?? r['price']);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(code, style: const TextStyle(fontSize: 11)),
              if (rate != null)
                Text(rate.toStringAsFixed(2), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Helper DTO for the 3-persona quick-switch pill row.
class _PersonaPill {
  final String id;
  final String label;
  final Color color;
  const _PersonaPill(this.id, this.label, this.color);
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
