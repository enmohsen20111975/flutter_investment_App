// ============================================================================
// مساعد الاستثمار Flutter - Dashboard Screen
// Single /api/mobile/dashboard endpoint with live updates
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/mobile_api.dart';
import '../models/json_helpers.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/market_status_banner.dart';
import '../services/polling_service.dart';

class DashboardScreen extends StatefulWidget {
  final int marketVersion;

  const DashboardScreen({super.key, this.marketVersion = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  Future<Map<String, dynamic>>? _dashboardFuture;
  Map<String, dynamic>? _dashboardData;
  late TabController _topMoversTabController;
  StreamSubscription<Map<String, dynamic>>? _pollingSubscription;

  @override
  void initState() {
    super.initState();
    _topMoversTabController = TabController(length: 3, vsync: this);
    _dashboardFuture = _fetchDashboard();
    _startPolling();
  }

  @override
  void dispose() {
    _topMoversTabController.dispose();
    _pollingSubscription?.cancel();
    super.dispose();
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

  Future<Map<String, dynamic>> _fetchDashboard() async {
    try {
      final data = await mobileApi.getDashboard();
      _dashboardData = data;
      return data;
    } catch (e) {
      debugPrint('[Dashboard] Fetch failed: $e');
      return {};
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _dashboardFuture = _fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  children: [
                    const MarketStatusBanner(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HeaderCard(
                            icon: Icons.dashboard_rounded,
                            title: 'نظرة عامة على السوق',
                            subtitle: 'آخر تحديث للبيانات',
                          ),
                          const SizedBox(height: 16),
                          _buildIndicesRow(),
                          const SizedBox(height: 16),
                          _buildMarketSummary(),
                          const SizedBox(height: 16),
                          _buildTopMovers(),
                          if (_dashboardData?['gold_prices'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle('أسعار الذهب', Icons.diamond),
                            const SizedBox(height: 8),
                            _buildGoldPrices(),
                          ],
                          if (_dashboardData?['currency_rates'] != null) ...[
                            const SizedBox(height: 16),
                            _buildSectionTitle(
                                'أسعار العملات', Icons.currency_exchange),
                            const SizedBox(height: 8),
                            _buildCurrencyRates(),
                          ],
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildIndicesRow() {
    final indices =
        _dashboardData?['indices'] ?? _dashboardData?['market_indices'];
    if (indices is! List || indices.isEmpty) {
      if (_dashboardData != null) return const SizedBox.shrink();
      return const SkeletonBox(height: 100);
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: indices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final idx = indices[i] is Map
              ? Map<String, dynamic>.from(indices[i])
              : <String, dynamic>{};
          final name = idx['name']?.toString() ?? '';
          final value = parseDouble(idx['value']) ?? 0;
          final change = parseDouble(idx['change_percent'] ?? idx['change']);
          final isPositive = change != null && change >= 0;
          return Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(value.toStringAsFixed(1),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              if (change != null)
                Text('${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isPositive ? AppColors.success : AppColors.danger)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildMarketSummary() {
    final summary =
        _dashboardData?['market_summary'] ?? _dashboardData?['summary'];
    if (summary is! Map) return const SizedBox.shrink();
    final s = Map<String, dynamic>.from(summary);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _buildSummaryBadge('🟢', '${s['advances'] ?? s['gainers'] ?? 0}', 'مرتفع'),
        _buildSummaryBadge('🔴', '${s['declines'] ?? s['losers'] ?? 0}', 'منخفض'),
        _buildSummaryBadge('⚪', '${s['unchanged'] ?? 0}', 'بدون تغيير'),
      ]),
    );
  }

  Widget _buildSummaryBadge(String emoji, String count, String label) {
    return Column(children: [
      Text('$emoji $count',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ]);
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

  Widget _buildGoldPrices() {
    final rawGold = _dashboardData?['gold_prices'] ?? _dashboardData?['gold'];
    if (rawGold == null) return const SizedBox.shrink();

    List<Map<String, dynamic>> gold = [];
    if (rawGold is List) {
      gold = rawGold.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (rawGold is Map) {
      final map = Map<String, dynamic>.from(rawGold);
      if (map.containsKey('karat_24')) {
        gold.add({'karat': 'عيار 24', 'price': parseDouble(map['karat_24'])});
      }
      if (map.containsKey('karat_21')) {
        gold.add({'karat': 'عيار 21', 'price': parseDouble(map['karat_21'])});
      }
      if (map.containsKey('karat_18')) {
        gold.add({'karat': 'عيار 18', 'price': parseDouble(map['karat_18'])});
      }
      if (map.containsKey('silver') && parseDouble(map['silver']) != 0) {
        gold.add({'karat': 'فضة', 'price': parseDouble(map['silver'])});
      }
    }

    if (gold.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: gold.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = gold[i];
          final karat = g['karat']?.toString() ?? '';
          final price = parseDouble(g['price']);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              Text(karat,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
              if (price != null)
                Text('${price.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(fontSize: 12)),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildCurrencyRates() {
    final rawRates =
        _dashboardData?['currency_rates'] ?? _dashboardData?['currencies'] ?? _dashboardData?['rates'];
    List<Map<String, dynamic>> ratesList = [];
    if (rawRates is List) {
      ratesList = rawRates.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } else if (rawRates is Map) {
      rawRates.forEach((key, value) {
        if (value is Map) {
          ratesList.add({
            'code': key,
            'buy': value['buy'] ?? value['buy_rate'] ?? value['rate_to_egp'] ?? value['rate'],
            'sell': value['sell'] ?? value['sell_rate'] ?? value['rate_to_egp'] ?? value['rate'],
          });
        } else {
          ratesList.add({
            'code': key,
            'buy': value,
            'sell': value,
          });
        }
      });
    }

    if (ratesList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ratesList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = ratesList[i];
          final name = r['code']?.toString() ?? r['currency']?.toString() ?? '';
          final buy = parseDouble(r['buy'] ?? r['price'] ?? r['buy_rate'] ?? r['rate_to_egp'] ?? r['rate']);
          final sell = parseDouble(r['sell'] ?? r['sell_rate'] ?? r['rate_to_egp'] ?? r['rate']);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (buy != null)
                  Text('شراء: ${buy.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
                if (sell != null)
                  Text('بيع: ${sell.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted)),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
