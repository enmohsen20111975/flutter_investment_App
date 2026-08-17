// ============================================================================
// مساعد الاستثمار Flutter - Quantum Luxury Dashboard Screen
// Home / Market Overview with Live APIs & Offline-First Support
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../api/local_database.dart';
import '../models/types.dart';
import 'stock_history_screen.dart';

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
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
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
      // 1. Fetch Market Summary & Indices
      final summary = await GLMApiClient.instance.getMarketSummary();
      final indices = await GLMApiClient.instance.getMarketIndices();
      final movers = await GLMApiClient.instance.getStockMovementClassification();

      if (mounted) {
        setState(() {
          _marketSummary = summary;
          _indices = indices;
          _gainers = movers['top_gainers'] ?? summary['top_gainers'] ?? [];
          _losers = movers['top_losers'] ?? summary['top_losers'] ?? [];
          _mostActive = movers['most_active'] ?? summary['most_active'] ?? [];
          _isOffline = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Dashboard] Fetch error, using offline fallback: $e');
      // Offline Fallback from SQLite
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
                                      color: AppColors.quantumGold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.quantumGold.withOpacity(0.3)),
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
                    height: 120,
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
                            color: Colors.black.withOpacity(0.3),
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

  Widget _buildIndexCard(dynamic item) {
    final name = item['name'] ?? item['symbol'] ?? 'مؤشر';
    final value = (item['value'] ?? item['current_price'] ?? 0.0).toString();
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
          color: isUp ? AppColors.quantumEmerald.withOpacity(0.4) : AppColors.quantumCrimson.withOpacity(0.4),
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
        child: Text('لا توجد بيانات متاحة حالياً', style: TextStyle(color: Colors.white.withOpacity(0.5))),
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
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
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
                            color: (isPositive ? AppColors.quantumEmerald : AppColors.quantumCrimson).withOpacity(0.2),
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
