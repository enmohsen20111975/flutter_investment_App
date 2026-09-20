// ============================================================================
// مساعد الاستثمار Flutter - Quantum Luxury Dashboard Screen
// Home / Market Overview with Live APIs & Offline-First Support
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../api/cache_manager.dart';
import '../api/local_database.dart';
import '../widgets/app_card.dart';
import '../widgets/stock_search_dialog.dart';
import '../widgets/investors_flow_card.dart';
import 'stock_history_screen.dart';
import 'hunter_screen.dart';
import 'radar_screen.dart';
import 'metals_screen.dart';
import 'currency_screen.dart';
import 'trading_chart_screen.dart';
import 'investors_screen.dart';
import '../core/app_localizations.dart';
import '../services/polling_service.dart';

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

  bool _isLoading = true;
  bool _isOffline = false;
  Map<String, dynamic>? _marketSummary;
  List<dynamic> _indices = [];
  List<dynamic> _gainers = [];
  List<dynamic> _losers = [];
  List<dynamic> _mostActive = [];
  Map<String, dynamic>? _goldData;
  Map<String, dynamic>? _currencyData;
  Map<String, dynamic>? _investorsData;

  late TabController _tabController;
  StreamSubscription<Map<String, dynamic>>? _pollingSub;
  StreamSubscription<String>? _cacheSubscription;
  bool _hasLoadedInitial = false;
  /// Prevents concurrent overlapping _loadDashboardData calls
  bool _loadGuard = false;
  /// Debounce timer for cache-update-triggered explosive refresh
  Timer? _explosiveDebounce;

  // Explosive-opportunities preview (GAP 5).
  late Future<List<Map<String, dynamic>>> _explosiveFuture =
      Future.delayed(const Duration(milliseconds: 800), _fetchExplosivePreview);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
    _listenToPolling();
    _cacheSubscription = ApiCacheManager.instance.updates
        .where((key) => key.startsWith('explosive_opportunities_'))
        .listen((_) {
      // Debounce: wait 500ms after the last update before rebuilding
      _explosiveDebounce?.cancel();
      _explosiveDebounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _explosiveFuture =
                Future.delayed(Duration.zero, _fetchExplosivePreview);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _explosiveDebounce?.cancel();
    _cacheSubscription?.cancel();
    _tabController.dispose();
    _pollingSub?.cancel();
    super.dispose();
  }

  void _listenToPolling() {
    _pollingSub?.cancel();
    _pollingSub = pollingService.dashboardStream.listen((data) {
      if (!mounted) return;
      setState(() {
        _marketSummary = data['market_summary'] ?? data['summary'];
        _indices = data['indices'] ?? data['market_indices'] ?? _indices;
        _gainers = data['gainers'] ?? data['top_gainers'] ?? _gainers;
        _losers = data['losers'] ?? data['top_losers'] ?? _losers;
        _mostActive = data['most_active'] ?? _mostActive;
        _goldData = _safeAsMap(data['gold']) ??
            _safeAsMap(data['gold_data']) ??
            _goldData;
        _currencyData = _safeAsMap(data['currency']) ??
            _safeAsMap(data['currency_data']) ??
            _currencyData;
        _isOffline = false;
      });
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadDashboardData();
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  Future<void> _loadDashboardData({bool isSilent = false}) async {
    // Guard: prevent overlapping concurrent fetches
    if (_loadGuard) return;
    _loadGuard = true;
    try {
      await _doLoadDashboard(isSilent: isSilent);
    } finally {
      _loadGuard = false;
    }
  }

  Future<void> _doLoadDashboard({bool isSilent = false}) async {
    // 1. Instant local display (0ms): render cached data immediately without blocking
    if (_indices.isEmpty) {
      try {
        final localIndices = await LocalDatabase.instance.getMarketIndices();
        final localStocks = await LocalDatabase.instance.queryStocks();
        if (mounted && localIndices.isNotEmpty) {
          setState(() {
            _indices = localIndices;
            if (localStocks.isNotEmpty) {
              _gainers = localStocks.take(5).toList();
              _losers = localStocks.skip(5).take(5).toList();
              _mostActive = localStocks.take(8).toList();
            }
          });
        }
      } catch (_) {}
    }

    if (!isSilent && _indices.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        api.getMarketSummary().catchError((_) => <String, dynamic>{}),
        api.getMarketIndices().catchError((_) => <dynamic>[]),
        api
            .getStockMovementClassification()
            .catchError((_) => <String, dynamic>{}),
        api.getGold().catchError((_) => <String, dynamic>{}),
        api.getCurrencyList().catchError((_) => <dynamic>[]),
        api.getEgxInvestors(latest: true).catchError((_) => <String, dynamic>{}),
      ]);

      final summary = results[0] is Map<String, dynamic>
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final indices = results[1] is List ? results[1] as List : <dynamic>[];
      final movers = results[2] is Map<String, dynamic>
          ? results[2] as Map<String, dynamic>
          : <String, dynamic>{};
      final goldResult = results[3] is Map<String, dynamic>
          ? results[3] as Map<String, dynamic>
          : <String, dynamic>{};
      final currencyResult =
          results[4] is List ? results[4] as List : <dynamic>[];
      final investorsResult = results[5] is Map<String, dynamic>
          ? results[5] as Map<String, dynamic>
          : <String, dynamic>{};

      List<dynamic> gainers = movers['top_gainers'] ??
          movers['gainers'] ??
          summary['top_gainers'] ??
          summary['gainers'] ??
          [];
      List<dynamic> losers = movers['top_losers'] ??
          movers['losers'] ??
          summary['top_losers'] ??
          summary['losers'] ??
          [];
      List<dynamic> mostActive = movers['most_active'] ??
          summary['most_active'] ??
          summary['active'] ??
          [];

      if (gainers.isEmpty || losers.isEmpty || mostActive.isEmpty) {
        try {
          final overview = await api.getMarketOverview();
          if (gainers.isEmpty && overview.topGainers != null) {
            gainers = overview.topGainers!
                .map((s) => {
                      'ticker': s.ticker,
                      'symbol': s.ticker,
                      'name': s.name,
                      'price': s.currentPrice,
                      'current_price': s.currentPrice,
                      'change_percent': s.changePercent
                    })
                .toList();
          }
          if (losers.isEmpty && overview.topLosers != null) {
            losers = overview.topLosers!
                .map((s) => {
                      'ticker': s.ticker,
                      'symbol': s.ticker,
                      'name': s.name,
                      'price': s.currentPrice,
                      'current_price': s.currentPrice,
                      'change_percent': s.changePercent
                    })
                .toList();
          }
          if (mostActive.isEmpty && overview.mostActive != null) {
            mostActive = overview.mostActive!
                .map((s) => {
                      'ticker': s.ticker,
                      'symbol': s.ticker,
                      'name': s.name,
                      'price': s.currentPrice,
                      'current_price': s.currentPrice,
                      'change_percent': s.changePercent
                    })
                .toList();
          }
        } catch (_) {}
      }

      if (gainers.isEmpty || losers.isEmpty || mostActive.isEmpty) {
        try {
          final localStocks = await LocalDatabase.instance.queryStocks();
          if (localStocks.isNotEmpty) {
            if (gainers.isEmpty) gainers = localStocks.take(5).toList();
            if (losers.isEmpty) losers = localStocks.skip(5).take(5).toList();
            if (mostActive.isEmpty) mostActive = localStocks.take(8).toList();
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          if (summary.isNotEmpty) _marketSummary = summary;
          if (indices.isNotEmpty) _indices = indices;
          if (gainers.isNotEmpty) _gainers = gainers;
          if (losers.isNotEmpty) _losers = losers;
          if (mostActive.isNotEmpty) _mostActive = mostActive;
          if (investorsResult.isNotEmpty) _investorsData = investorsResult;
          _goldData = _safeAsMap(goldResult) ??
              (goldResult is List && (goldResult as List).isNotEmpty
                  ? {'gold_prices': goldResult}
                  : _goldData);
          _currencyData = _safeAsMap(currencyResult) ??
              (currencyResult.isNotEmpty
                  ? {'currency_rates': currencyResult}
                  : _currencyData);
          _isOffline = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Fetch error, using offline fallback: $e');
      final localIndices = await LocalDatabase.instance.getMarketIndices();
      final localStocks = await LocalDatabase.instance.queryStocks();

      if (mounted) {
        setState(() {
          if (localIndices.isNotEmpty) _indices = localIndices;
          if (localStocks.isNotEmpty) {
            _gainers = localStocks.take(5).toList();
            _losers = localStocks.skip(5).take(5).toList();
            _mostActive = localStocks.take(8).toList();
          }
          _isOffline = true;
          _isLoading = false;
        });
      }
    }
  }

  static Map<String, dynamic>? _safeAsMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchExplosivePreview() async {
    try {
      final payload = await api.getExplosiveOpportunities(limit: 10);
      final raw = payload['top_candidates'];
      if (raw is! List) return <Map<String, dynamic>>[];
      final out = <Map<String, dynamic>>[];
      for (final e in raw) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          final m5 = _toDouble(m['momentum_5d']);
          if (m5 != null && m5.abs() > 200) continue;
          final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString().trim();
          if (RegExp(r'^\d{4}$').hasMatch(ticker))
            continue; // Filter out Saudi stocks from EGX preview
          out.add(m);
          if (out.length >= 5) break;
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
    // i18n helper
    final isAr = AppLocalizations.isArabic;
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.quantumEmerald,
          backgroundColor: AppColors.quantumGlass,
          onRefresh: () => _loadDashboardData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Ticker & Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.quantumGold
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.quantumGold
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isOffline
                                              ? Icons.wifi_off
                                              : Icons.fiber_manual_record,
                                          size: 10,
                                          color: _isOffline
                                              ? AppColors.quantumGold
                                              : AppColors.quantumEmerald,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isOffline
                                              ? 'وضع بدون إنترنت'
                                              : 'مباشر • EGX',
                                          style: const TextStyle(
                                            color: AppColors.quantumGold,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'نظرة عامة على السوق',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.quantumGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.quantumGlassBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: AppColors.quantumEmerald),
                              onPressed: () => _loadDashboardData(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 1. Universal Stock Search & Instant Inspector Bar
                      InkWell(
                        onTap: () => StockSearchDialog.show(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.quantumSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.quantumEmerald.withValues(alpha: 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppColors.quantumEmerald, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'فحص وتحليل أي سهم فوري... COMI, FWRY, HRHO',
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.quantumEmerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bolt, color: AppColors.quantumEmerald, size: 13),
                                    SizedBox(width: 2),
                                    Text('فحص سهم', style: TextStyle(color: AppColors.quantumEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 2. Modern Quick Action Pills Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickActionPill('الأسهم الانفجارية 🚀', Icons.local_fire_department_rounded, AppColors.quantumCrimson, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const HunterScreen()));
                            }),
                            const SizedBox(width: 8),
                            _buildQuickActionPill('رادار السيولة 🌊', Icons.radar_rounded, AppColors.quantumEmerald, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const RadarScreen()));
                            }),
                            const SizedBox(width: 8),
                            _buildQuickActionPill('TradingView 📈', Icons.candlestick_chart_rounded, AppColors.quantumGold, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TradingChartScreen(ticker: 'EGX30', displayName: 'مؤشر EGX 30')));
                            }),
                            const SizedBox(width: 8),
                            _buildQuickActionPill('حركة المستثمرين 👥', Icons.groups_rounded, AppColors.info, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestorsScreen()));
                            }),
                            const SizedBox(width: 8),
                            _buildQuickActionPill('أسعار الذهب 🥇', Icons.diamond_rounded, AppColors.warning, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MetalsScreen()));
                            }),
                            const SizedBox(width: 8),
                            _buildQuickActionPill('أسعار العملات 💱', Icons.currency_exchange_rounded, Colors.tealAccent, () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CurrencyScreen()));
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Live Gold & Currency Interactive Showcase Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildGoldShowcaseCard(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCurrencyShowcaseCard(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 4. EGX Investors Flow Radar Card (المصريين والعرب والأجانب)
                      InvestorsFlowCard(initialData: _investorsData),

                      const SizedBox(height: 16),

                      // 5. Explosive Opportunities Preview
                      _buildExplosivePreview(),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.quantumEmerald),
                  ),
                )
              else ...[
                // Indices Horizontal Cards (EGX30, EGX70, etc.)
                if (_indices.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 145,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _indices.length,
                        itemBuilder: (context, index) {
                          final item = _indices[index];
                          return _buildIndexCard(item);
                        },
                      ),
                    ),
                  ),

                // Market Stats Banner (Turnover, Volume)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.quantumGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.quantumGlassBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                              'قيمة التداول اليومية',
                              _marketSummary?['turnover'] ?? '2.45B ج.م',
                              Icons.payments_outlined),
                          Container(
                              height: 30,
                              width: 1,
                              color: AppColors.quantumGlassBorder),
                          _buildStatItem(
                              'حجم التداول',
                              _marketSummary?['volume'] ?? '680M سهم',
                              Icons.bar_chart_outlined),
                          Container(
                              height: 30,
                              width: 1,
                              color: AppColors.quantumGlassBorder),
                          _buildStatItem(
                              'حالة السوق',
                              _marketSummary?['status'] ?? 'مفتوح',
                              Icons.access_time_outlined,
                              isStatus: true),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Movers Section Header & Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حركة الأسهم الممتازة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.quantumSurface,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.quantumGlassBorder),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.quantumEmerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            tabs: const [
                              Tab(text: 'الأكثر ارتفاعاً 🚀'),
                              Tab(text: 'الأكثر انخفاضاً 🔻'),
                              Tab(text: 'الأكثر نشاطاً ⚡'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Movers List View
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 380,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMoversList(_gainers, isGainer: true),
                        _buildMoversList(_losers, isGainer: false),
                        _buildMoversList(_mostActive, isGainer: true),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionPill(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.quantumSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldShowcaseCard() {
    dynamic p21 = _goldData?['21k'] ?? _goldData?['price_21k'];
    dynamic p24 = _goldData?['24k'] ?? _goldData?['price_24k'];
    dynamic p18 = _goldData?['18k'] ?? _goldData?['price_18k'];

    if (_goldData?['gold_prices'] is Map) {
      final gp = _goldData!['gold_prices'] as Map;
      p21 ??= gp['karat_21'] ?? gp['21k'];
      p24 ??= gp['karat_24'] ?? gp['24k'];
      p18 ??= gp['karat_18'] ?? gp['18k'];
    } else if (_goldData?['gold_prices'] is List) {
      for (final item in _goldData!['gold_prices'] as List) {
        if (item is Map) {
          final k = item['key']?.toString() ?? item['karat']?.toString() ?? '';
          final p = item['price_per_gram'] ?? item['price'];
          if (k.contains('21')) p21 ??= p;
          if (k.contains('24')) p24 ??= p;
          if (k.contains('18')) p18 ??= p;
        }
      }
    }

    final p21Text = (p21 != null && p21 != 0) ? '$p21 ج.م' : '-';
    final p24Text = (p24 != null && p24 != 0) ? '$p24 ج.م' : '-';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MetalsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.quantumGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.quantumGlassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.diamond_rounded, size: 18, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text('الذهب', style: AppTypography.titleSmall),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.quantumGold, size: 10),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('عيار 21:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(p21Text, style: const TextStyle(color: AppColors.quantumGold, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('عيار 24:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(p24Text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.quantumSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('عرض كل الأعيرة والسبائك >', style: TextStyle(color: AppColors.quantumGold, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyShowcaseCard() {
    dynamic usdRate;
    dynamic eurRate;
    dynamic sarRate;

    final ratesList = _currencyData?['currency_rates'] ?? _currencyData?['rates'] ?? _currencyData?['data'];
    if (ratesList is List) {
      for (final item in ratesList) {
        if (item is Map) {
          final code = (item['code'] ?? item['symbol'] ?? item['currency'] ?? '').toString().toUpperCase();
          final r = item['rate_to_egp'] ?? item['buy_rate'] ?? item['rate'] ?? item['price'] ?? item['sell_rate'];
          if (code.contains('USD')) usdRate ??= r;
          if (code.contains('EUR')) eurRate ??= r;
          if (code.contains('SAR')) sarRate ??= r;
        }
      }
    } else if (_currencyData is Map) {
      usdRate ??= _currencyData?['USD'] ?? _currencyData?['usd'];
      eurRate ??= _currencyData?['EUR'] ?? _currencyData?['eur'];
      sarRate ??= _currencyData?['SAR'] ?? _currencyData?['sar'];
    }

    final usdText = (usdRate != null && usdRate != 0) ? '$usdRate ج.م' : '-';
    final eurText = (eurRate != null && eurRate != 0) ? '$eurRate ج.م' : '-';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CurrencyScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.quantumGlass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.quantumGlassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_exchange_rounded, size: 18, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text('العملات', style: AppTypography.titleSmall),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.info, size: 10),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('USD / EGP:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(usdText, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EUR / EGP:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                Text(eurText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.quantumSurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('عرض كافة أسعار الصرف >', style: TextStyle(color: AppColors.info, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

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
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HunterScreen())),
              child: const Text('عرض الكل',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'لا توجد فرص انفجارية حالياً',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HunterScreen())),
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

  Widget _explosiveRow(Map<String, dynamic> c) {
    final ticker = c['ticker']?.toString() ?? '—';
    final score = _toDouble(c['explosive_score']) ?? 0;
    final scoreColor = score >= 85
        ? const Color(0xFFFFD700)
        : score >= 70
            ? AppColors.success
            : score >= 55
                ? AppColors.primary
                : AppColors.warning;
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const HunterScreen())),
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
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
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

  Widget _buildIndexCard(dynamic item) {
    final name = item['name'] ?? item['symbol'] ?? 'مؤشر';
    final rawVal = item['value'] ?? item['current_price'] ?? 0.0;
    final double? valNum = rawVal is num
        ? rawVal.toDouble()
        : double.tryParse(rawVal.toString().replaceAll(',', ''));
    final String value = valNum != null
        ? valNum.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
        : rawVal.toString();
    final change = (item['change_percent'] ?? item['change'] ?? 0.0);
    final double changeNum = change is num
        ? change.toDouble()
        : double.tryParse(change.toString()) ?? 0.0;
    final bool isUp = changeNum >= 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUp
              ? AppColors.quantumEmerald.withValues(alpha: 0.4)
              : AppColors.quantumCrimson.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color:
                    isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                size: 20,
              ),
              Text(
                '${isUp ? '+' : ''}${changeNum.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isUp
                      ? AppColors.quantumEmerald
                      : AppColors.quantumCrimson,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatItem(String title, String value, IconData icon,
      {bool isStatus = false}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.quantumGold, size: 20),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isStatus ? AppColors.quantumEmerald : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildMoversList(List<dynamic> items, {required bool isGainer}) {
    if (items.isEmpty) {
      return Center(
        child: Text('لا توجد بيانات متاحة حالياً',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stock = items[index];
        final ticker = stock['ticker'] ?? stock['symbol'] ?? 'STOCK';
        final name = stock['name_ar'] ?? stock['name'] ?? ticker;
        final price =
            (stock['price'] ?? stock['current_price'] ?? stock['close'] ?? 0.0);
        final change = (stock['change_percent'] ?? stock['change'] ?? 0.0);
        final double changeNum = change is num
            ? change.toDouble()
            : double.tryParse(change.toString()) ?? 0.0;
        final bool isPositive = changeNum >= 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StockHistoryScreen(ticker: ticker),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.quantumGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.quantumGlassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.quantumSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.quantumGlassBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ticker,
                        style: const TextStyle(
                          color: AppColors.quantumGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticker,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price.toString()} ج.م',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPositive
                                    ? AppColors.quantumEmerald
                                    : AppColors.quantumCrimson)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${changeNum.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive
                                  ? AppColors.quantumEmerald
                                  : AppColors.quantumCrimson,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
      },
    );
  }
}
