// ============================================================================
// مساعد الاستثمار Flutter - Stock Details & TradingView Live Chart Screen
// Quantum Luxury Dark Theme with Live Chart, Orderbook, Disclosures & Fundamentals
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/tradingview_chart.dart';
import '../widgets/upgrade_modal.dart';
import '../services/subscription_service.dart';

class StockHistoryScreen extends StatefulWidget {
  final String ticker;
  const StockHistoryScreen({super.key, required this.ticker});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isInWatchlist = false;
  Map<String, dynamic>? _stockQuote;
  OrderBook? _orderBook;
  List<CompanyDisclosure> _disclosures = [];
  Map<String, dynamic>? _fundamentals;
  Map<String, dynamic>? _recommendation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStockDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStockDetails() async {
    setState(() => _isLoading = true);
    try {
      final quote = await GLMApiClient.instance.getStockDetail(widget.ticker);
      final orderbook = await GLMApiClient.instance.getStockOrderBook(widget.ticker);
      final disclosures = await GLMApiClient.instance.getCompanyDisclosures(widget.ticker);
      final fundamentals = await GLMApiClient.instance.getStockFundamentals(widget.ticker);
      final rec = await GLMApiClient.instance.getStockRecommendation(widget.ticker);

      if (mounted) {
        setState(() {
          _stockQuote = quote;
          _orderBook = orderbook;
          _disclosures = disclosures;
          _fundamentals = fundamentals;
          _recommendation = rec;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[StockDetail] Error loading details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleWatchlist() async {
    final canAdd = SubscriptionService.instance.canAddToWatchlist(1);
    if (!canAdd) {
      UpgradeModal.show(context, feature: 'watchlist_unlimited', reason: 'إضافة أكثر من 3 أسهم لمتابعة المحفظة');
      return;
    }
    setState(() => _isInWatchlist = !_isInWatchlist);
    try {
      if (_isInWatchlist) {
        await GLMApiClient.instance.addToWatchlist({'symbol': widget.ticker});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تمت إضافة ${widget.ticker} لـ قائمة المتابعة'),
              backgroundColor: AppColors.quantumEmerald,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Watchlist] Toggle failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _stockQuote?['name_ar'] ?? _stockQuote?['name'] ?? widget.ticker;
    final price = (_stockQuote?['price'] ?? _stockQuote?['current_price'] ?? 29.50);
    final change = (_stockQuote?['change_percent'] ?? _stockQuote?['price_change'] ?? 1.85);
    final double changeNum = change is num ? change.toDouble() : double.tryParse(change.toString()) ?? 0.0;
    final bool isUp = changeNum >= 0;

    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.ticker,
              style: const TextStyle(color: AppColors.quantumGold, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isInWatchlist ? Icons.star : Icons.star_border,
              color: _isInWatchlist ? AppColors.quantumGold : Colors.white70,
            ),
            onPressed: _toggleWatchlist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Top Quote Summary Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.quantumSurface,
                          border: Border(bottom: BorderSide(color: AppColors.quantumGlassBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$price ج.م',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
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
                                ),
                              ],
                            ),
                            // Quick metrics
                            Row(
                              children: [
                                _buildQuickMetric('الأعلى', '${_stockQuote?['high'] ?? 30.10}'),
                                const SizedBox(width: 12),
                                _buildQuickMetric('الأدنى', '${_stockQuote?['low'] ?? 28.90}'),
                                const SizedBox(width: 12),
                                _buildQuickMetric('الحجم', '${_stockQuote?['volume'] ?? '1.2M'}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // TradingView Chart Widget Container
                      const SizedBox(
                        height: 220,
                        child: TradingViewChartWithControls(
                          darkTheme: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.quantumEmerald,
                      labelColor: AppColors.quantumEmerald,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'عمق السوق'),
                        Tab(text: 'البيانات المالية'),
                        Tab(text: 'الإفصاحات'),
                        Tab(text: 'التحليل والـ AI'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderBookTab(),
                  _buildFundamentalsTab(),
                  _buildDisclosuresTab(),
                  _buildRecommendationTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildOrderBookTab() {
    final bids = _orderBook?.bids ?? [];
    final asks = _orderBook?.asks ?? [];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          // Bids (طلبات الشراء - أخضر)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('طلبات الشراء (Bids)', style: TextStyle(color: AppColors.quantumEmerald, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final item = bids[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.quantumEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م', style: const TextStyle(color: AppColors.quantumEmerald, fontWeight: FontWeight.bold)),
                            Text('${item.volume}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Asks (عروض البيع - أحمر)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('عروض البيع (Asks)', style: TextStyle(color: AppColors.quantumCrimson, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: asks.length,
                    itemBuilder: (context, index) {
                      final item = asks[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.quantumCrimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م', style: const TextStyle(color: AppColors.quantumCrimson, fontWeight: FontWeight.bold)),
                            Text('${item.volume}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalsTab() {
    final pe = _fundamentals?['pe_ratio'] ?? '12.4';
    final eps = _fundamentals?['eps'] ?? '2.40 ج.م';
    final mcap = _fundamentals?['market_cap'] ?? '15.2B ج.م';
    final divYield = _fundamentals?['dividend_yield'] ?? '6.5%';
    final high52 = _fundamentals?['high_52w'] ?? '34.00 ج.م';
    final low52 = _fundamentals?['low_52w'] ?? '22.50 ج.م';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDataRow('مضاعف الربحية (P/E)', '$pe'),
        _buildDataRow('ربحية السهم (EPS)', '$eps'),
        _buildDataRow('القيمة السوقية', '$mcap'),
        _buildDataRow('عائد التوزيعات السنوي', '$divYield'),
        _buildDataRow('أعلى سعر خلال 52 أسبوع', '$high52'),
        _buildDataRow('أدنى سعر خلال 52 أسبوع', '$low52'),
      ],
    );
  }

  Widget _buildDataRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.quantumGlassBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDisclosuresTab() {
    if (_disclosures.isEmpty) {
      return Center(child: Text('لا توجد إفصاحات مسجلة', style: TextStyle(color: Colors.white.withOpacity(0.5))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _disclosures.length,
      itemBuilder: (context, index) {
        final d = _disclosures[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.quantumGlassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.quantumGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(d.category, style: const TextStyle(color: AppColors.quantumGold, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    '${d.date.day}/${d.date.month}/${d.date.year}',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              if (d.summary != null) ...[
                const SizedBox(height: 4),
                Text(d.summary!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationTab() {
    final hasAccess = SubscriptionService.instance.hasAccess('recommendations');
    if (!hasAccess) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.quantumGold, size: 48),
            const SizedBox(height: 12),
            const Text(
              'توصيات الـ AI والتحليل الاحترافي مخصصة للمشتركين',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.quantumEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => UpgradeModal.show(context, feature: 'recommendations', reason: 'عرض توصيات الأسهم المتقدمة'),
              child: const Text('ترقية الحساب الآن'),
            ),
          ],
        ),
      );
    }

    final action = _recommendation?['action'] ?? 'BUY';
    final target = _recommendation?['target_price'] ?? 34.00;
    final stopLoss = _recommendation?['stop_loss'] ?? 27.00;
    final reasons = _recommendation?['reasons'] as List? ?? ['مؤشرات فنية إيجابية', 'نمو الأرباح الربع سنوي'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.quantumEmerald),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('توصية الذكاء الاصطناعي:', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.quantumEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(action, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const Divider(color: AppColors.quantumGlassBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRecPriceMetric('السعر المستهدف', '$target ج.م', AppColors.quantumEmerald),
                  _buildRecPriceMetric('إيقاف الخسارة', '$stopLoss ج.م', AppColors.quantumCrimson),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('أسباب التوصية:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ...reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.quantumEmerald, size: 16),
                  const SizedBox(width: 8),
                  Text(r.toString(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecPriceMetric(String title, String val, Color col) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.quantumSurface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
