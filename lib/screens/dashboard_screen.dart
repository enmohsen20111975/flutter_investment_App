// ============================================================================
// مساعد الاستثمار Flutter - Quantum Luxury Dashboard Screen
// Home / Market Overview with Live APIs & Offline-First Support
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../api/local_database.dart';
import '../widgets/app_card.dart';
import 'stock_history_screen.dart';
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

  bool _isLoading = true;
  bool _isOffline = false;
  Map<String, dynamic>? _marketSummary;
  List<dynamic> _indices = [];
  List<dynamic> _gainers = [];
  List<dynamic> _losers = [];
  List<dynamic> _mostActive = [];
  Map<String, dynamic>? _goldData;
  Map<String, dynamic>? _currencyData;

  late TabController _tabController;
  Timer? _refreshTimer;

  // Explosive-opportunities preview (GAP 5).
  Future<List<Map<String, dynamic>>>? _explosiveFuture;
  // 3-persona quick-switch (GAP 5).
  String _selectedPersona = 'balanced';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
    _explosiveFuture = _fetchExplosivePreview();
    // Auto refresh every 30s
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadDashboardData(isSilent: true));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() => _isLoading = true);
    }

    try {
      final summaryFuture = api.getMarketSummary();
      final indicesFuture = api.getMarketIndices();
      final moversFuture = api.getStockMovementClassification();
      final goldFuture = api.getGold();
      final currencyFuture = api.getCurrencyList();

      final summary = await summaryFuture;
      final indices = await indicesFuture;
      final movers = await moversFuture;
      final goldResult = await goldFuture.catchError((_) => <String, dynamic>{});
      final currencyResult = await currencyFuture.catchError((_) => <dynamic>[]);

      List<dynamic> gainers = movers['top_gainers'] ?? movers['gainers'] ?? summary['top_gainers'] ?? summary['gainers'] ?? [];
      List<dynamic> losers = movers['top_losers'] ?? movers['losers'] ?? summary['top_losers'] ?? summary['losers'] ?? [];
      List<dynamic> mostActive = movers['most_active'] ?? summary['most_active'] ?? summary['active'] ?? [];

      if (gainers.isEmpty || losers.isEmpty || mostActive.isEmpty) {
        try {
          final overview = await api.getMarketOverview();
          if (gainers.isEmpty && overview.topGainers != null) {
            gainers = overview.topGainers!.map((s) => {'ticker': s.ticker, 'symbol': s.ticker, 'name': s.name, 'price': s.currentPrice, 'current_price': s.currentPrice, 'change_percent': s.changePercent}).toList();
          }
          if (losers.isEmpty && overview.topLosers != null) {
            losers = overview.topLosers!.map((s) => {'ticker': s.ticker, 'symbol': s.ticker, 'name': s.name, 'price': s.currentPrice, 'current_price': s.currentPrice, 'change_percent': s.changePercent}).toList();
          }
          if (mostActive.isEmpty && overview.mostActive != null) {
            mostActive = overview.mostActive!.map((s) => {'ticker': s.ticker, 'symbol': s.ticker, 'name': s.name, 'price': s.currentPrice, 'current_price': s.currentPrice, 'change_percent': s.changePercent}).toList();
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
          _marketSummary = summary;
          _indices = indices;
          _gainers = gainers;
          _losers = losers;
          _mostActive = mostActive;
          _goldData = _safeAsMap(goldResult) ?? (goldResult is List && (goldResult as List).isNotEmpty ? {'gold_prices': goldResult} : null);
          _currencyData = _safeAsMap(currencyResult) ?? (currencyResult.isNotEmpty ? {'currency_rates': currencyResult} : null);
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
          _indices = localIndices;
          _gainers = localStocks.take(5).toList();
          _losers = localStocks.skip(5).take(5).toList();
          _mostActive = localStocks.take(8).toList();
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
          if (RegExp(r'^\d{4}$').hasMatch(ticker)) continue; // Filter out Saudi stocks from EGX preview
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.quantumGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.quantumGold.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isOffline ? Icons.wifi_off : Icons.fiber_manual_record,
                                          size: 10,
                                          color: _isOffline ? AppColors.quantumGold : AppColors.quantumEmerald,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isOffline ? 'وضع بدون إنترنت' : 'مباشر • EGX',
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
                              border: Border.all(color: AppColors.quantumGlassBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: AppColors.quantumEmerald),
                              onPressed: () => _loadDashboardData(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Mini Gold & Currency Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.diamond_rounded, size: 20, color: AppColors.warning),
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
                                    const Icon(Icons.currency_exchange_rounded, size: 20, color: AppColors.info),
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
                      // GAP 5: Explosive opportunities preview
                      _buildExplosivePreview(),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.quantumEmerald),
                  ),
                )
              else ...[
                // Indices Horizontal Cards (EGX30, EGX70, etc.)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 145,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _indices.isNotEmpty ? _indices.length : 3,
                      itemBuilder: (context, index) {
                        if (_indices.isEmpty) {
                          return _buildSampleIndexCard(index);
                        }
                        final item = _indices[index];
                        return _buildIndexCard(item);
                      },
                    ),
                  ),
                ),

                // Market Stats Banner (Turnover, Volume)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                          _buildStatItem('قيمة التداول اليومية', _marketSummary?['turnover'] ?? '2.45B ج.م', Icons.payments_outlined),
                          Container(height: 30, width: 1, color: AppColors.quantumGlassBorder),
                          _buildStatItem('حجم التداول', _marketSummary?['volume'] ?? '680M سهم', Icons.bar_chart_outlined),
                          Container(height: 30, width: 1, color: AppColors.quantumGlassBorder),
                          _buildStatItem('حالة السوق', _marketSummary?['status'] ?? 'مفتوح', Icons.access_time_outlined, isStatus: true),
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
                            border: Border.all(color: AppColors.quantumGlassBorder),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: AppColors.quantumEmerald,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.white70,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  Widget _buildMiniGold() {
    if (_goldData == null || _goldData!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('عيار 21', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text('-- ج.م', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
    }
    dynamic priceVal;
    String label = 'عيار 21';
    if (_goldData!['gold_prices'] is List) {
      final list = _goldData!['gold_prices'] as List;
      for (final item in list) {
        if (item is Map) {
          if (item['name_ar']?.toString().contains('21') == true || item['key'] == '21' || item['karat'] == '21') {
            priceVal = item['price_per_gram'] ?? item['price'];
            break;
          }
        }
      }
      if (priceVal == null && list.isNotEmpty && list.first is Map) {
        priceVal = list.first['price_per_gram'] ?? list.first['price'];
        label = list.first['name_ar'] ?? 'الذهب';
      }
    } else if (_goldData!['prices'] is List) {
      final list = _goldData!['prices'] as List;
      for (final item in list) {
        if (item is Map) {
          if (item['name_ar']?.toString().contains('21') == true || item['key'] == '21') {
            priceVal = item['price_per_gram'] ?? item['price'];
            break;
          }
        }
      }
    }
    priceVal ??= _goldData!['21k'] ?? _goldData!['price_21k'] ?? _goldData!['gram_21k'];

    final priceStr = priceVal != null ? '$priceVal ج.م' : '-- ج.م';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(priceStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildMiniCurrency() {
    if (_currencyData == null || _currencyData!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('USD / EGP', style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text('-- ج.م', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );
    }

    dynamic usdRate;
    if (_currencyData!['currency_rates'] is List) {
      final list = _currencyData!['currency_rates'] as List;
      for (final item in list) {
        if (item is Map && (item['code'] == 'USD' || item['symbol'] == 'USD')) {
          usdRate = item['rate'] ?? item['buy_rate'] ?? item['sell_rate'] ?? item['price'];
          break;
        }
      }
    } else if (_currencyData!['rates'] is Map) {
      usdRate = _currencyData!['rates']['USD'];
    }
    usdRate ??= _currencyData!['USD'] ?? _currencyData!['usd_egp'];

    final rateStr = usdRate != null ? '$usdRate ج.م' : '-- ج.م';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('USD / EGP', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(rateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
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
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
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
      const _PersonaPill('gambler', '🔥 المضارب', AppColors.danger),
      const _PersonaPill('balanced', '⚖️ المتوازن', AppColors.warning),
      const _PersonaPill('conservative', '🛡️ المحافظ', AppColors.info),
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

  Widget _buildIndexCard(dynamic item) {
    final name = item['name'] ?? item['symbol'] ?? 'مؤشر';
    final rawVal = item['value'] ?? item['current_price'] ?? 0.0;
    final double? valNum = rawVal is num ? rawVal.toDouble() : double.tryParse(rawVal.toString().replaceAll(',', ''));
    final String value = valNum != null
        ? valNum.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
        : rawVal.toString();
    final change = (item['change_percent'] ?? item['change'] ?? 0.0);
    final double changeNum = change is num ? change.toDouble() : double.tryParse(change.toString()) ?? 0.0;
    final bool isUp = changeNum >= 0;

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUp ? AppColors.quantumEmerald.withValues(alpha: 0.4) : AppColors.quantumCrimson.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                size: 20,
              ),
              Text(
                '${isUp ? '+' : ''}${changeNum.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
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

  Widget _buildSampleIndexCard(int index) {
    final names = ['EGX30', 'EGX70 EWI', 'EGX100 EWI'];
    final values = ['30,450.20', '7,210.15', '10,340.80'];
    final changes = [1.45, -0.62, 0.85];
    return _buildIndexCard({
      'name': names[index % 3],
      'value': values[index % 3],
      'change_percent': changes[index % 3],
    });
  }

  Widget _buildStatItem(String title, String value, IconData icon, {bool isStatus = false}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.quantumGold, size: 20),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
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
        child: Text('لا توجد بيانات متاحة حالياً', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final stock = items[index];
        final ticker = stock['ticker'] ?? stock['symbol'] ?? 'STOCK';
        final name = stock['name_ar'] ?? stock['name'] ?? ticker;
        final price = (stock['price'] ?? stock['current_price'] ?? stock['close'] ?? 0.0);
        final change = (stock['change_percent'] ?? stock['change'] ?? 0.0);
        final double changeNum = change is num ? change.toDouble() : double.tryParse(change.toString()) ?? 0.0;
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticker,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${price.toString()} ج.م',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isPositive ? AppColors.quantumEmerald : AppColors.quantumCrimson).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${isPositive ? '+' : ''}${changeNum.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: isPositive ? AppColors.quantumEmerald : AppColors.quantumCrimson,
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
