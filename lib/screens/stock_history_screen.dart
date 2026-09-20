// ============================================================================
// مساعد الاستثمار Flutter - Stock Details & TradingView Live Chart Screen
// Quantum Luxury Dark Theme with Live Chart, Orderbook, Disclosures & Fundamentals
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../api/cache_manager.dart';
import '../api/local_database.dart';
import '../models/types.dart';
import '../widgets/tradingview_chart.dart';
import '../widgets/upgrade_modal.dart';
import '../services/subscription_service.dart';
import '../core/app_localizations.dart';

class StockHistoryScreen extends StatefulWidget {
  final String ticker;
  const StockHistoryScreen({super.key, required this.ticker});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _detailsFuture = _loadStockDetailsData();
  bool _isInWatchlist = false;

  Map<String, dynamic>? _stockQuote;
  OrderBook? _orderBook;
  List<CompanyDisclosure> _disclosures = [];
  Map<String, dynamic>? _fundamentals;
  Map<String, dynamic>? _recommendation;
  List<Map<String, dynamic>> _candles = [];
  List<Map<String, dynamic>> _volumes = [];
  Future<dynamic>? _newsFuture;
  StreamSubscription<String>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _refreshDetails();
    _cacheSubscription = ApiCacheManager.instance.updates.where((key) {
      return key == 'stock_news_${widget.ticker}' ||
          key.startsWith('stock_detail_${widget.ticker}') ||
          key.startsWith('stock_orderbook_${widget.ticker}') ||
          key.startsWith('stock_disclosures_${widget.ticker}') ||
          key.startsWith('stock_fundamentals_${widget.ticker}') ||
          key.startsWith('stock_recommendation_${widget.ticker}');
    }).listen((key) {
      if (mounted) {
        if (key == 'stock_news_${widget.ticker}' && _newsFuture != null) {
          setState(() {
            _newsFuture = GLMApiClient.instance.getStockNews(widget.ticker);
          });
        } else {
          _refreshDetails();
        }
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.index == 3 && _newsFuture == null && mounted) {
      setState(() {
        _newsFuture = GLMApiClient.instance.getStockNews(widget.ticker);
      });
    }
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _refreshDetails() {
    setState(() {
      _detailsFuture = _loadStockDetailsData();
    });
  }

  Future<Map<String, dynamic>> _loadStockDetailsData() async {
    try {
      final results = await Future.wait([
        GLMApiClient.instance
            .getStockDetail(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance.getStockOrderBook(widget.ticker).catchError(
            (_) => OrderBook(symbol: widget.ticker, bids: [], asks: [])),
        GLMApiClient.instance
            .getCompanyDisclosures(widget.ticker)
            .catchError((_) => <CompanyDisclosure>[]),
        GLMApiClient.instance
            .getStockFundamentals(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance
            .getStockRecommendation(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance
            .getStockHistory(widget.ticker, days: 90)
            .catchError((_) => StockHistoryResponse(data: [], summary: null)),
      ]).timeout(const Duration(seconds: 15));

      final quote = results[0] is Map
          ? results[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final orderbook = results[1] as OrderBook;
      final disclosures = results[2] is List
          ? results[2] as List<CompanyDisclosure>
          : <CompanyDisclosure>[];
      final fundamentals = results[3] is Map
          ? results[3] as Map<String, dynamic>
          : <String, dynamic>{};
      final rec = results[4] is Map
          ? results[4] as Map<String, dynamic>
          : <String, dynamic>{};
      final historyRes = results[5] as StockHistoryResponse;

      final candles = <Map<String, dynamic>>[];
      final volumes = <Map<String, dynamic>>[];
      for (final item in historyRes.data) {
        if (item.date.isNotEmpty && item.close != null) {
          final d = item.date.split('T').first;
          candles.add({
            'time': d,
            'open': item.open ?? item.close,
            'high': item.high ?? item.close,
            'low': item.low ?? item.close,
            'close': item.close,
          });
          if (item.volume != null && item.volume! > 0) {
            volumes.add({
              'time': d,
              'value': item.volume,
              'color': (item.close ?? 0) >= (item.open ?? item.close ?? 0)
                  ? 'rgba(38, 166, 154, 0.5)'
                  : 'rgba(239, 83, 80, 0.5)',
            });
          }
        }
      }

      // If online history was empty, try local DB cache
      if (candles.isEmpty) {
        try {
          final localHistory =
              await LocalDatabase.instance.getStockHistory(widget.ticker);
          for (final row in localHistory) {
            final d = (row['date'] ?? '').toString().split('T').first;
            final c = (row['close'] as num?)?.toDouble();
            if (d.isNotEmpty && c != null) {
              final o = (row['open'] as num?)?.toDouble() ?? c;
              candles.add({
                'time': d,
                'open': o,
                'high': (row['high'] as num?)?.toDouble() ?? c,
                'low': (row['low'] as num?)?.toDouble() ?? c,
                'close': c,
              });
              final v = (row['volume'] as num?)?.toInt();
              if (v != null && v > 0) {
                volumes.add({
                  'time': d,
                  'value': v,
                  'color': c >= o
                      ? 'rgba(38, 166, 154, 0.5)'
                      : 'rgba(239, 83, 80, 0.5)',
                });
              }
            }
          }
        } catch (_) {}
      } else {
        // Cache to local database in background
        try {
          LocalDatabase.instance.insertStockHistory(widget.ticker, candles);
        } catch (_) {}
      }

      _stockQuote = quote;
      _orderBook = orderbook;
      _disclosures = disclosures;
      _fundamentals = fundamentals;
      _recommendation = rec;
      _candles = candles;
      _volumes = volumes;

      return {
        'quote': quote,
        'orderbook': orderbook,
        'disclosures': disclosures,
        'fundamentals': fundamentals,
        'recommendation': rec,
        'candles': candles,
        'volumes': volumes,
      };
    } catch (e) {
      debugPrint('[StockDetail] Error loading details: $e');
      return {};
    }
  }

  Future<void> _toggleWatchlist() async {
    final canAdd = SubscriptionService.instance.canAddToWatchlist(1);
    if (!canAdd) {
      UpgradeModal.show(context,
          feature: 'watchlist_unlimited',
          reason: 'إضافة أكثر من 3 أسهم لمتابعة المحفظة');
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
    final isAr = AppLocalizations.isArabic; // i18n
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final name =
            _stockQuote?['name_ar'] ?? _stockQuote?['name'] ?? widget.ticker;
        final numPrice = (_stockQuote?['current_price'] ??
            _stockQuote?['last_price'] ??
            _stockQuote?['price'] ??
            (_candles.isNotEmpty ? _candles.last['close'] : 0.0)) as num;
        final price = numPrice > 0 ? numPrice.toStringAsFixed(2) : '0.00';

        final change = _stockQuote?['change_percent'] ??
            _stockQuote?['change_pct'] ??
            _stockQuote?['price_change'] ??
            _stockQuote?['change'] ??
            0.0;
        final double changeNum = change is num
            ? change.toDouble()
            : double.tryParse(change.toString()) ?? 0.0;
        final bool isUp = changeNum >= 0;

        final highVal = _stockQuote?['high_price'] ??
            _stockQuote?['high'] ??
            (_candles.isNotEmpty
                ? _candles
                    .map((c) => (c['high'] as num?) ?? 0)
                    .reduce((a, b) => a > b ? a : b)
                : null);
        final lowVal = _stockQuote?['low_price'] ??
            _stockQuote?['low'] ??
            (_candles.isNotEmpty
                ? _candles
                    .map((c) => (c['low'] as num?) ?? 999999)
                    .reduce((a, b) => a < b ? a : b)
                : null);
        final volVal = _stockQuote?['volume'] ??
            (_candles.isNotEmpty ? _candles.last['value'] : null);

        final highText = highVal != null ? '$highVal' : '-';
        final lowText = (lowVal != null && lowVal != 999999) ? '$lowVal' : '-';
        final volText = volVal != null
            ? (volVal is num && volVal >= 1000000
                ? '${(volVal / 1000000).toStringAsFixed(1)}M'
                : (volVal is num && volVal >= 1000
                    ? '${(volVal / 1000).toStringAsFixed(1)}K'
                    : '$volVal'))
            : '-';

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
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.ticker,
                  style: const TextStyle(
                      color: AppColors.quantumGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isInWatchlist ? Icons.star : Icons.star_border,
                  color:
                      _isInWatchlist ? AppColors.quantumGold : Colors.white70,
                ),
                onPressed: _toggleWatchlist,
              ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.quantumEmerald));
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: AppColors.quantumCrimson),
                    const SizedBox(height: 12),
                    const Text('حدث خطأ في تحميل تفاصيل السهم',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.quantumEmerald,
                          foregroundColor: Colors.black),
                      onPressed: _refreshDetails,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Top Quote Summary Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.quantumSurface,
                          border: Border(
                              bottom: BorderSide(
                                  color: AppColors.quantumGlassBorder)),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isUp
                                            ? AppColors.quantumEmerald
                                            : AppColors.quantumCrimson)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUp
                                            ? Icons.arrow_drop_up
                                            : Icons.arrow_drop_down,
                                        color: isUp
                                            ? AppColors.quantumEmerald
                                            : AppColors.quantumCrimson,
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
                                ),
                              ],
                            ),
                            // Quick metrics
                            Row(
                              children: [
                                _buildQuickMetric('الأعلى', highText),
                                const SizedBox(width: 12),
                                _buildQuickMetric('الأدنى', lowText),
                                const SizedBox(width: 12),
                                _buildQuickMetric('الحجم', volText),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // TradingView Chart Widget Container
                      SizedBox(
                        height: 260,
                        child: TradingViewChartWithControls(
                          darkTheme: true,
                          candleData: _candles.isNotEmpty ? _candles : null,
                          volumeData: _volumes.isNotEmpty ? _volumes : null,
                          onReloadData: (interval) async {
                            final days =
                                interval.days > 0 ? interval.days : 365;
                            try {
                              final res = await GLMApiClient.instance
                                  .getStockHistory(widget.ticker, days: days);
                              if (mounted && res.data.isNotEmpty) {
                                final newCandles = <Map<String, dynamic>>[];
                                final newVolumes = <Map<String, dynamic>>[];
                                for (final item in res.data) {
                                  if (item.date.isNotEmpty &&
                                      item.close != null) {
                                    final d = item.date.split('T').first;
                                    newCandles.add({
                                      'time': d,
                                      'open': item.open ?? item.close,
                                      'high': item.high ?? item.close,
                                      'low': item.low ?? item.close,
                                      'close': item.close,
                                    });
                                    if (item.volume != null &&
                                        item.volume! > 0) {
                                      newVolumes.add({
                                        'time': d,
                                        'value': item.volume,
                                        'color': (item.close ?? 0) >=
                                                (item.open ?? item.close ?? 0)
                                            ? 'rgba(38, 166, 154, 0.5)'
                                            : 'rgba(239, 83, 80, 0.5)',
                                      });
                                    }
                                  }
                                }
                                setState(() {
                                  _candles = newCandles;
                                  _volumes = newVolumes;
                                });
                              }
                            } catch (_) {}
                          },
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
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'عمق السوق'),
                        Tab(text: 'البيانات المالية'),
                        Tab(text: 'الإفصاحات'),
                        Tab(text: 'الأخبار'),
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
                  _buildStockNewsTab(),
                  _buildRecommendationTab(),
                ],
              ),
            );
          }(),
        );
      },
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _buildOrderBookTab() {
    final bids = _orderBook?.bids ?? [];
    final asks = _orderBook?.asks ?? [];

    if (bids.isEmpty && asks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers_clear_outlined, size: 48, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'لا توجد عروض أو طلبات مسجلة حالياً',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'قد تكون السوق مغلقة أو لم يتم التداول على السهم في هذه الجلسة',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  child: Text('طلبات الشراء (Bids)',
                      style: TextStyle(
                          color: AppColors.quantumEmerald,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: bids.length,
                    itemBuilder: (context, index) {
                      final item = bids[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.quantumEmerald.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م',
                                style: const TextStyle(
                                    color: AppColors.quantumEmerald,
                                    fontWeight: FontWeight.bold)),
                            Text('${item.volume}',
                                style: const TextStyle(color: Colors.white70)),
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
                  child: Text('عروض البيع (Asks)',
                      style: TextStyle(
                          color: AppColors.quantumCrimson,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: asks.length,
                    itemBuilder: (context, index) {
                      final item = asks[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.quantumCrimson.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م',
                                style: const TextStyle(
                                    color: AppColors.quantumCrimson,
                                    fontWeight: FontWeight.bold)),
                            Text('${item.volume}',
                                style: const TextStyle(color: Colors.white70)),
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
    final pe = _fundamentals?['pe_ratio'] ?? _stockQuote?['pe_ratio'];
    final eps = _fundamentals?['eps'] ?? _stockQuote?['eps'];
    final mcap = _fundamentals?['market_cap'] ?? _stockQuote?['market_cap'];
    final divYield =
        _fundamentals?['dividend_yield'] ?? _stockQuote?['dividend_yield'];
    final high52 = _fundamentals?['high_52w'] ?? _stockQuote?['high_52w'];
    final low52 = _fundamentals?['low_52w'] ?? _stockQuote?['low_52w'];

    final peText = pe != null ? '$pe' : '-';
    final epsText = eps != null ? '$eps ج.م' : '-';
    final mcapText = mcap != null
        ? (mcap is num && mcap >= 1000000000
            ? '${(mcap / 1000000000).toStringAsFixed(2)}B ج.م'
            : (mcap is num && mcap >= 1000000
                ? '${(mcap / 1000000).toStringAsFixed(2)}M ج.م'
                : '$mcap ج.م'))
        : '-';
    final divYieldText = divYield != null ? '$divYield%' : '-';
    final high52Text = high52 != null ? '$high52 ج.م' : '-';
    final low52Text = low52 != null ? '$low52 ج.م' : '-';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDataRow('مضاعف الربحية (P/E)', peText),
        _buildDataRow('ربحية السهم (EPS)', epsText),
        _buildDataRow('القيمة السوقية', mcapText),
        _buildDataRow('عائد التوزيعات السنوي', divYieldText),
        _buildDataRow('أعلى سعر خلال 52 أسبوع', high52Text),
        _buildDataRow('أدنى سعر خلال 52 أسبوع', low52Text),
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
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDisclosuresTab() {
    if (_disclosures.isEmpty) {
      return Center(
          child: Text('لا توجد إفصاحات مسجلة',
              style: TextStyle(color: Colors.white.withOpacity(0.5))));
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.quantumGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(d.category,
                        style: const TextStyle(
                            color: AppColors.quantumGold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    '${d.date.day}/${d.date.month}/${d.date.year}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              if (d.summary != null) ...[
                const SizedBox(height: 4),
                Text(d.summary!,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }

  /// تبويب أخبار السهم — آخر الأخبار + الإفصاحات الخاصة بالسهم
  Widget _buildStockNewsTab() {
    if (_newsFuture == null) {
      return const Center(child: Text('اضغط على تبويب الأخبار لتحميلها'));
    }
    return FutureBuilder<dynamic>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(' خطأ: ${snapshot.error}'));
        }
        final raw = snapshot.data;
        List<dynamic> news = [];
        if (raw is List) {
          news = raw;
        } else if (raw is Map) {
          final listCandidate =
              raw['news'] ?? raw['data'] ?? raw['articles'] ?? raw['items'];
          if (listCandidate is List) {
            news = listCandidate;
          }
        }
        if (news.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('مفيش أخبار متاحة لهذا السهم دلوقتي',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: news.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = news[index] is Map
                ? Map<String, dynamic>.from(news[index] as Map)
                : <String, dynamic>{};
            final title = item['title']?.toString() ??
                item['headline']?.toString() ??
                'خبر';
            final source = item['source']?.toString() ?? '';
            final date = item['published_at']?.toString() ??
                item['date']?.toString() ??
                item['created_at']?.toString() ??
                '';
            final summary = item['summary']?.toString() ??
                item['description']?.toString() ??
                '';
            final url =
                item['url']?.toString() ?? item['link']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.article_outlined, color: Colors.blue),
                title: Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11)),
                      ),
                    if (source.isNotEmpty || date.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (source.isNotEmpty)
                              Flexible(
                                  child: Text(source,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey))),
                            if (source.isNotEmpty && date.isNotEmpty)
                              const Text(' • ',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            if (date.isNotEmpty)
                              Flexible(
                                  child: Text(date.split('T').first,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey))),
                          ],
                        ),
                      ),
                  ],
                ),
                onTap: url.isNotEmpty
                    ? () {
                        // ممكن فتح URL بـ url_launcher لو متاح
                      }
                    : null,
              ),
            );
          },
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
            const Icon(Icons.lock_outline,
                color: AppColors.quantumGold, size: 48),
            const SizedBox(height: 12),
            const Text(
              'توصيات الـ AI والتحليل الاحترافي مخصصة للمشتركين',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.quantumEmerald,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () => UpgradeModal.show(context,
                  feature: 'recommendations',
                  reason: 'عرض توصيات الأسهم المتقدمة'),
              child: const Text('ترقية الحساب الآن'),
            ),
          ],
        ),
      );
    }

    final action = _recommendation?['action'] ??
        _recommendation?['recommendation'] ??
        _recommendation?['signal'];
    final target = _recommendation?['target_price'] ??
        _recommendation?['target'];
    final stopLoss = _recommendation?['stop_loss'] ??
        _recommendation?['stop'];
    final reasons = _recommendation?['reasons'] as List? ??
        (_recommendation?['reason'] != null
            ? [_recommendation!['reason']]
            : null);

    if (action == null && target == null && stopLoss == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.psychology_alt_outlined,
                  size: 56, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'لا توجد توصية نشطة حالياً لهذا السهم',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                'يتم تحديث التوصيات دورياً بناءً على إغلاقات الجلسة ونماذج التحليل',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
                  const Text('توصية الذكاء الاصطناعي:',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.quantumEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(action?.toString() ?? 'HOLD',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ],
              ),
              const Divider(color: AppColors.quantumGlassBorder, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRecPriceMetric(
                      'السعر المستهدف',
                      target != null ? '$target ج.م' : '-',
                      AppColors.quantumEmerald),
                  _buildRecPriceMetric(
                      'إيقاف الخسارة',
                      stopLoss != null ? '$stopLoss ج.م' : '-',
                      AppColors.quantumCrimson),
                ],
              ),
            ],
          ),
        ),
        if (reasons != null && reasons.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('أسباب التوصية:',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 8),
          ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.quantumEmerald, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.toString(),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildRecPriceMetric(String title, String val, Color col) {
    return Column(
      children: [
        Text(title,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                color: col, fontWeight: FontWeight.bold, fontSize: 16)),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
