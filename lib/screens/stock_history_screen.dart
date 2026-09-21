// ============================================================================
// مساعد الاستثمار Flutter - Stock Details & TradingView Live Chart Screen
// Quantum Luxury Dark Theme with Live Chart, Orderbook, Disclosures,
// Deep Fundamentals, Flow Scores, Maestro Personas & Marketing Share System
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
import '../core/official_links.dart';

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
  Map<String, dynamic>? _comprehensive;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _flow;
  Map<String, dynamic>? _explosive;
  List<Map<String, dynamic>> _candles = [];
  List<Map<String, dynamic>> _volumes = [];
  Future<dynamic>? _newsFuture;
  StreamSubscription<String>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _refreshDetails();
    _cacheSubscription = ApiCacheManager.instance.updates.where((key) {
      return key == 'stock_news_${widget.ticker}' ||
          key.startsWith('stock_detail_${widget.ticker}') ||
          key.startsWith('stock_orderbook_${widget.ticker}') ||
          key.startsWith('stock_disclosures_${widget.ticker}') ||
          key.startsWith('stock_fundamentals_${widget.ticker}') ||
          key.startsWith('stock_recommendation_${widget.ticker}') ||
          key.startsWith('stock_comprehensive_${widget.ticker}') ||
          key.startsWith('stock_profile_${widget.ticker}') ||
          key.startsWith('stock_flow_${widget.ticker}');
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
    if (_tabController.index == 5 && _newsFuture == null && mounted) {
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
        GLMApiClient.instance
            .getStockComprehensive(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance
            .getStockProfile(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance
            .getStockFlow(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
        GLMApiClient.instance
            .getStockExplosive(widget.ticker)
            .catchError((_) => <String, dynamic>{}),
      ]).timeout(const Duration(seconds: 25));

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
      final comprehensive = results[6] is Map
          ? results[6] as Map<String, dynamic>
          : <String, dynamic>{};
      final profile = results[7] is Map
          ? results[7] as Map<String, dynamic>
          : <String, dynamic>{};
      final flow = results[8] is Map
          ? results[8] as Map<String, dynamic>
          : <String, dynamic>{};
      final explosive = results[9] is Map
          ? results[9] as Map<String, dynamic>
          : <String, dynamic>{};

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
            final d = (row['date'] ?? row['time'] ?? '').toString().split('T').first;
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
        // Cache to local database in background safely
        LocalDatabase.instance.insertStockHistory(widget.ticker, candles).catchError((e) {
          debugPrint('[StockHistoryScreen] cache error: $e');
        });
      }

      _stockQuote = quote;
      _orderBook = orderbook;
      _disclosures = disclosures;
      _fundamentals = fundamentals;
      _recommendation = rec;
      _comprehensive = comprehensive;
      _profile = profile;
      _flow = flow;
      _explosive = explosive;
      _candles = candles;
      _volumes = volumes;

      return {
        'quote': quote,
        'orderbook': orderbook,
        'disclosures': disclosures,
        'fundamentals': fundamentals,
        'recommendation': rec,
        'comprehensive': comprehensive,
        'profile': profile,
        'flow': flow,
        'explosive': explosive,
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
              content: Text('تمت إضافة ${widget.ticker} لقائمة المتابعة'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Watchlist] Toggle failed: $e');
    }
  }

  void _openShareModal() {
    final numPrice = (_stockQuote?['current_price'] ??
        _stockQuote?['last_price'] ??
        _stockQuote?['price'] ??
        _comprehensive?['price']?['current_price'] ??
        (_candles.isNotEmpty ? _candles.last['close'] : 0.0)) as num;
    final double priceVal = numPrice.toDouble();

    final change = _stockQuote?['change_percent'] ??
        _stockQuote?['change_pct'] ??
        _stockQuote?['price_change'] ??
        _stockQuote?['change'] ??
        _comprehensive?['price']?['change_percent'];
    final double? changeVal = change is num
        ? change.toDouble()
        : (change != null ? double.tryParse(change.toString()) : null);

    final name = _stockQuote?['name_ar'] ??
        _stockQuote?['name'] ??
        _comprehensive?['basic']?['name_ar'] ??
        _comprehensive?['basic']?['name'] ??
        widget.ticker;

    final sector = _stockQuote?['sector'] ??
        _comprehensive?['basic']?['sector'] ??
        '';

    final rec = _recommendation?['action'] ??
        _recommendation?['recommendation'] ??
        _comprehensive?['maestro']?['action'] ??
        _comprehensive?['professional']?['signal'];

    final conf = _recommendation?['confidence'] ??
        _comprehensive?['maestro']?['overall_score'] ??
        _comprehensive?['professional']?['score'];

    final buyPrice = (_comprehensive?['technical']?['support'] as num?)?.toDouble() ??
        (_comprehensive?['hunter']?['entry'] as num?)?.toDouble();

    final targetPrice = (_recommendation?['target_price'] as num?)?.toDouble() ??
        (_comprehensive?['hunter']?['target'] as num?)?.toDouble() ??
        (_flow?['target'] != null ? priceVal * (1 + ((_flow!['target'] as num).toDouble() / 100)) : null);

    final stopLoss = (_recommendation?['stop_loss'] as num?)?.toDouble() ??
        (_comprehensive?['hunter']?['stop_loss'] as num?)?.toDouble() ??
        (_flow?['stop_loss'] != null ? priceVal * (1 + ((_flow!['stop_loss'] as num).toDouble() / 100)) : null);

    final fairValue = (_stockQuote?['fair_value'] as num?)?.toDouble();

    final pe = (_fundamentals?['pe_ratio'] as num?)?.toDouble() ??
        (_comprehensive?['keyMetrics']?['pe_ratio'] as num?)?.toDouble() ??
        (_profile?['valuation']?['pe_ratio'] as num?)?.toDouble();

    final pb = (_fundamentals?['pb_ratio'] as num?)?.toDouble() ??
        (_comprehensive?['keyMetrics']?['pb_ratio'] as num?)?.toDouble() ??
        (_profile?['valuation']?['pb_ratio'] as num?)?.toDouble();

    final roe = (_fundamentals?['roe'] as num?)?.toDouble() ??
        (_comprehensive?['keyMetrics']?['roe'] as num?)?.toDouble() ??
        (_profile?['profitability']?['roe'] as num?)?.toDouble();

    final divYield = (_fundamentals?['dividend_yield'] as num?)?.toDouble() ??
        (_comprehensive?['keyMetrics']?['dividend_yield'] as num?)?.toDouble() ??
        (_profile?['dividends']?['dividend_yield'] as num?)?.toDouble();

    OfficialLinks.showShareModal(
      context,
      ticker: widget.ticker,
      name: name.toString(),
      price: priceVal,
      changePercent: changeVal,
      recommendation: rec?.toString(),
      confidence: conf is num ? conf : null,
      buyPrice: buyPrice,
      targetPrice: targetPrice,
      stopLoss: stopLoss,
      fairValue: fairValue,
      pe: pe,
      pb: pb,
      roe: roe,
      dividendYield: divYield,
      sector: sector.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final name = _stockQuote?['name_ar'] ??
            _stockQuote?['name'] ??
            _comprehensive?['basic']?['name_ar'] ??
            _comprehensive?['basic']?['name'] ??
            widget.ticker;

        final numPrice = (_stockQuote?['current_price'] ??
            _stockQuote?['last_price'] ??
            _stockQuote?['price'] ??
            _comprehensive?['price']?['current_price'] ??
            (_candles.isNotEmpty ? _candles.last['close'] : 0.0)) as num;
        final price = numPrice > 0 ? numPrice.toStringAsFixed(2) : '0.00';

        final change = _stockQuote?['change_percent'] ??
            _stockQuote?['change_pct'] ??
            _stockQuote?['price_change'] ??
            _stockQuote?['change'] ??
            _comprehensive?['price']?['change_percent'] ??
            0.0;
        final double changeNum = change is num
            ? change.toDouble()
            : double.tryParse(change.toString()) ?? 0.0;
        final bool isUp = changeNum >= 0;

        final rawHigh = _stockQuote?['high_price'] ??
            _stockQuote?['high'] ??
            _comprehensive?['price']?['high_price'];
        final num? highNum = rawHigh is num
            ? rawHigh
            : (rawHigh != null ? num.tryParse(rawHigh.toString()) : null);
        final highVal = (highNum != null && highNum > 0)
            ? highNum
            : (_candles.isNotEmpty
                ? _candles
                    .map((c) => (c['high'] as num?) ?? 0)
                    .reduce((a, b) => a > b ? a : b)
                : null);

        final rawLow = _stockQuote?['low_price'] ??
            _stockQuote?['low'] ??
            _comprehensive?['price']?['low_price'];
        final num? lowNum = rawLow is num
            ? rawLow
            : (rawLow != null ? num.tryParse(rawLow.toString()) : null);
        final lowVal = (lowNum != null && lowNum > 0)
            ? lowNum
            : (_candles.isNotEmpty
                ? _candles
                    .map((c) => (c['low'] as num?) ?? 999999)
                    .reduce((a, b) => a < b ? a : b)
                : null);

        final volVal = _stockQuote?['volume'] ??
            _comprehensive?['price']?['volume'] ??
            (_candles.isNotEmpty ? _candles.last['value'] : null);

        final highText = (highVal != null && highVal > 0)
            ? (highVal is num ? highVal.toStringAsFixed(2) : '$highVal')
            : '-';
        final lowText = (lowVal != null && lowVal > 0 && lowVal != 999999)
            ? (lowVal is num ? lowVal.toStringAsFixed(2) : '$lowVal')
            : '-';
        final volText = volVal != null
            ? (volVal is num && volVal >= 1000000
                ? '${(volVal / 1000000).toStringAsFixed(1)}M'
                : (volVal is num && volVal >= 1000
                    ? '${(volVal / 1000).toStringAsFixed(1)}K'
                    : '$volVal'))
            : '-';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.text),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.ticker,
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              // زر المشاركة الدعائي مع الروابط الرسمية
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppColors.primaryLight),
                tooltip: 'مشاركة التحليل والروابط الرسمية',
                onPressed: _openShareModal,
              ),
              IconButton(
                icon: Icon(
                  _isInWatchlist ? Icons.star : Icons.star_border,
                  color: _isInWatchlist ? AppColors.warning : AppColors.textSecondary,
                ),
                onPressed: _toggleWatchlist,
              ),
            ],
          ),
          body: () {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryLight));
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    const Text('حدث خطأ في تحميل تفاصيل السهم',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // شارات المؤشرات والامتثال الشرعي
                      _buildIdentityBadges(),

                      // بطاقة نقاط التدفق المالي الذكي (Flow Score Card)
                      if (_flow != null && _flow!['flow_score'] != null)
                        _buildFlowScoreBanner(),

                      // بطاقة الفرصة الانفجارية (Explosive Scanner Card)
                      if (_explosive != null && _explosive!['explosive_score'] != null)
                        _buildExplosiveBanner(),

                      // Top Quote Summary Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                              bottom: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5))),
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
                                    color: AppColors.text,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isUp ? AppColors.success : AppColors.danger)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isUp ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        color: isUp ? AppColors.success : AppColors.danger,
                                      ),
                                      Text(
                                        '${isUp ? '+' : ''}${changeNum.toStringAsFixed(2)}%',
                                        style: TextStyle(
                                          color: isUp ? AppColors.success : AppColors.danger,
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
                            final days = interval.days > 0 ? interval.days : 365;
                            try {
                              final res = await GLMApiClient.instance
                                  .getStockHistory(widget.ticker, days: days);
                              if (mounted && res.data.isNotEmpty) {
                                final newCandles = <Map<String, dynamic>>[];
                                final newVolumes = <Map<String, dynamic>>[];
                                for (final item in res.data) {
                                  if (item.date.isNotEmpty && item.close != null) {
                                    final d = item.date.split('T').first;
                                    newCandles.add({
                                      'time': d,
                                      'open': item.open ?? item.close,
                                      'high': item.high ?? item.close,
                                      'low': item.low ?? item.close,
                                      'close': item.close,
                                    });
                                    if (item.volume != null && item.volume! > 0) {
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
                      indicatorColor: AppColors.primaryLight,
                      indicatorWeight: 3,
                      labelColor: AppColors.primaryLight,
                      unselectedLabelColor: AppColors.textMuted,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'نظرة عامة والـ AI'),
                        Tab(text: 'التحليل الفني'),
                        Tab(text: 'البيانات والقوائم'),
                        Tab(text: 'عمق السوق'),
                        Tab(text: 'الإفصاحات'),
                        Tab(text: 'الأخبار'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewAndAiTab(),
                  _buildTechnicalTab(),
                  _buildFinancialsTab(),
                  _buildOrderBookTab(),
                  _buildDisclosuresTab(),
                  _buildStockNewsTab(),
                ],
              ),
            );
          }(),
        );
      },
    );
  }

  // ─── Header Badges (Index & Shariah & Health) ──────────────────────────────

  Widget _buildIdentityBadges() {
    final basic = _comprehensive?['basic'] ?? {};
    final isEgx30 = basic['is_egx30'] == true || _stockQuote?['egx30_member'] == true;
    final isEgx70 = basic['is_egx70'] == true || _stockQuote?['egx70_member'] == true;
    final isEgx100 = basic['is_egx100'] == true || _stockQuote?['egx100_member'] == true;
    final sector = basic['sector'] ?? _stockQuote?['sector'];
    final compliance = _stockQuote?['compliance_status'] ?? basic['compliance_status'];
    final hs = _profile?['health_score'];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (isEgx30)
            _buildBadge('EGX 30', AppColors.success.withValues(alpha: 0.15), AppColors.success),
          if (isEgx70)
            _buildBadge('EGX 70', AppColors.warning.withValues(alpha: 0.15), AppColors.warning),
          if (isEgx100)
            _buildBadge('EGX 100', Colors.white12, AppColors.textSecondary),
          if (sector != null && sector.toString().isNotEmpty)
            _buildBadge(sector.toString(), AppColors.card, AppColors.textSecondary),
          if (compliance == 'halal')
            _buildBadge('متوافق شرعاً', AppColors.success.withValues(alpha: 0.15), AppColors.success,
                icon: Icons.verified_user_outlined),
          if (compliance == 'doubtful')
            _buildBadge('غير مؤكد', AppColors.warning.withValues(alpha: 0.15), AppColors.warning,
                icon: Icons.help_outline),
          if (hs is Map && hs['score'] != null)
            _buildBadge('صحة مالية: ${hs['score']}/100 (${hs['label'] ?? ''})',
                AppColors.primaryLight.withValues(alpha: 0.15), AppColors.primaryLight,
                icon: Icons.favorite_border),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Flow Score Card Banner ────────────────────────────────────────────────

  Widget _buildFlowScoreBanner() {
    final flow = _flow!;
    final score = flow['flow_score'] ?? 0;
    final label = flow['label'] ?? '';
    final action = flow['action'] ?? '';
    final macro = flow['macro_flow'] ?? 0;
    final sectorFlow = flow['sector_flow'] ?? 0;
    final stockFlow = flow['stock_flow'] ?? 0;
    final target = flow['target'];
    final stopLoss = flow['stop_loss'];

    final Color statusColor = score >= 75
        ? AppColors.success
        : (score >= 50 ? AppColors.warning : AppColors.danger);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.15),
            AppColors.card,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text('نقاط التدفق',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                Text(
                  '$score',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$label ($action)',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (target != null)
                      Text(
                        'هدف: +$target%',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'سيولة عامة: $macro | قطاع: $sectorFlow | سهم: $stockFlow' +
                      (stopLoss != null ? ' | وقف: $stopLoss%' : ''),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Explosive Opportunity Banner ──────────────────────────────────────────

  Widget _buildExplosiveBanner() {
    final exp = _explosive!;
    final score = exp['explosive_score'] ?? 0;
    final label = exp['label'] ?? '';
    final pattern = exp['pattern'] ?? '';
    final volRatio = exp['volume_ratio'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'رادار الانفجار ($score/100) — $label : $pattern' +
                  (volRatio != null ? ' (حجم ${volRatio}x)' : ''),
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  // ─── Tab 1: Overview & AI Maestro ──────────────────────────────────────────

  Widget _buildOverviewAndAiTab() {
    final maestro = _comprehensive?['maestro'] ?? {};
    final hunter = _comprehensive?['hunter'] ?? {};
    final board = _comprehensive?['board'] ?? {};
    final prof = _comprehensive?['professional'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // زر مشاركة التحليل السريع
        InkWell(
          onTap: _openShareModal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF0EA5E9)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'مشاركة تقرير السهم وروابط المنصة الرسمية',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // تقييم المايسترو الشامل ومراحل التحليل (Maestro Orchestrator)
        _buildMaestroOrchestratorSection(maestro),

        const SizedBox(height: 16),

        // مستويات التداول المستهدفة
        _buildTradingLevelsCard(hunter),

        const SizedBox(height: 16),

        // تدفقات المستثمرين والمؤسسات (Board of Analysts)
        if (board.isNotEmpty) _buildInvestorFlowCard(board),

        const SizedBox(height: 16),

        // التقرير الذكي والملخص الاستراتيجي (AI Executive Report)
        _buildAiSummarySection(prof),
      ],
    );
  }

  Widget _buildMaestroOrchestratorSection(Map maestroData) {
    final m = maestroData['maestroAnalysis'] is Map
        ? maestroData['maestroAnalysis'] as Map
        : maestroData;

    final score = (m['maestroScore'] as num?)?.toDouble() ??
        (m['overall_score'] as num?)?.toDouble() ??
        (m['score'] as num?)?.toDouble() ??
        50.0;
    final rec = (m['recommendationAr'] ?? m['recommendation'] ?? m['action'] ?? 'حياد').toString();
    final confidence = (m['confidence'] as num?)?.toDouble() ?? 65.0;
    final riskReward = (m['riskReward'] as num?)?.toDouble();
    final strategy = m['entry'] is Map ? m['entry']['strategyAr']?.toString() : null;
    final warnings = (m['warningsAr'] is List)
        ? (m['warningsAr'] as List).map((w) => w.toString()).toList()
        : <String>[];
    final phases = m['phases'] is Map ? m['phases'] as Map : null;

    final isBuy = rec.contains('شراء') || rec.toLowerCase().contains('buy');
    final isSell = rec.contains('بيع') || rec.toLowerCase().contains('sell');
    final badgeColor = isBuy ? AppColors.success : (isSell ? AppColors.danger : AppColors.warning);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'تقييم المايسترو الشامل (Maestro Engine)',
                  style: TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  rec,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Score and Confidence
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${score.toInt()}/100',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: score >= 70
                            ? AppColors.success
                            : (score >= 50 ? AppColors.warning : AppColors.danger),
                      ),
                    ),
                    const Text('درجة التقييم',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نسبة الثقة في التحليل',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${confidence.toInt()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (confidence / 100).clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceMuted,
                        color: AppColors.primaryLight,
                        minHeight: 6,
                      ),
                    ),
                    if (riskReward != null && riskReward > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'معدل العائد إلى المخاطرة (R/R): ${riskReward.toStringAsFixed(2)}:1',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Analysis Phases if present
          if (phases != null && phases.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 8),
            const Text(
              'مراحل التحليل الأربعة (Analysis Phases):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPhaseChip('النظام', phases['regime']),
                const SizedBox(width: 6),
                _buildPhaseChip('الإطار الزمني', phases['timeframe']),
                const SizedBox(width: 6),
                _buildPhaseChip('السيولة', phases['volume']),
                const SizedBox(width: 6),
                _buildPhaseChip('الأخبار', phases['news']),
              ],
            ),
          ],

          // Strategy text
          if (strategy != null && strategy.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'استراتيجية الدخول: $strategy',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
              ),
            ),
          ],

          // Warnings
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(w,
                            style: const TextStyle(fontSize: 11, color: AppColors.warning)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseChip(String title, dynamic phaseData) {
    num score = 50;
    String status = '';
    if (phaseData is Map) {
      score = (phaseData['score'] as num?) ?? 50;
      status = (phaseData['phase'] ?? phaseData['status'] ?? '').toString();
    } else if (phaseData is num) {
      score = phaseData;
    }

    final color = score >= 65
        ? AppColors.success
        : (score >= 45 ? AppColors.primaryLight : AppColors.warning);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(
              '${score.toInt()}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
            if (status.isNotEmpty)
              Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 8, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradingLevelsCard(Map hunter) {
    final entry = (hunter['entry'] as num?)?.toDouble() ??
        (_comprehensive?['technical']?['support'] as num?)?.toDouble();
    final target = (hunter['target'] as num?)?.toDouble() ??
        (_recommendation?['target_price'] as num?)?.toDouble();
    final stopLoss = (hunter['stop_loss'] as num?)?.toDouble() ??
        (_recommendation?['stop_loss'] as num?)?.toDouble();
    final fairValue = (_stockQuote?['fair_value'] as num?)?.toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.crisis_alert_rounded, color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'أسعار ومستويات التداول المقترحة',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          Divider(color: AppColors.cardBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLevelItem('سعر الدخول/الدعم',
                  entry != null ? '${entry.toStringAsFixed(2)} ج.م' : '-', AppColors.primaryLight),
              _buildLevelItem('السعر المستهدف',
                  target != null ? '${target.toStringAsFixed(2)} ج.م' : '-', AppColors.success),
              _buildLevelItem('وقف الخسارة',
                  stopLoss != null ? '${stopLoss.toStringAsFixed(2)} ج.م' : '-', AppColors.danger),
              if (fairValue != null)
                _buildLevelItem('القيمة العادلة', '${fairValue.toStringAsFixed(2)} ج.م', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelItem(String label, String val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildInvestorFlowCard(Map board) {
    final instFlow = board['institutional_flow'] ?? board['institutions'];
    final retailFlow = board['retail_flow'] ?? board['retail'];
    final egFlow = board['egyptian_flow'];
    final arabFlow = board['arab_flow'];
    final foreignFlow = board['foreign_flow'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: AppColors.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'تدفقات المستثمرين والمؤسسات (Board of Analysts)',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (instFlow != null || retailFlow != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المؤسسات: ${instFlow ?? '-'}%',
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                Text('الأفراد: ${retailFlow ?? '-'}%',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          if (egFlow != null || arabFlow != null || foreignFlow != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('مصر: $egFlow', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('عرب: $arabFlow', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text('أجانب: $foreignFlow', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSummarySection(Map prof) {
    final summary = prof['summary'] ?? prof['executive_summary'] ?? _recommendation?['reason'];
    final strengths = prof['strengths'] as List? ?? [];
    final weaknesses = prof['weaknesses'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'التقرير والملخص الذكي (AI Analysis)',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 10),
            Text(
              summary.toString(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('نقاط القوة:',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(s.toString(),
                              style: const TextStyle(color: AppColors.text, fontSize: 11))),
                    ],
                  ),
                )),
          ],
          if (weaknesses.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('نقاط الحذر:',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            ...weaknesses.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(w.toString(),
                              style: const TextStyle(color: AppColors.text, fontSize: 11))),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ─── Tab 2: Technical Indicators ───────────────────────────────────────────

  Widget _buildTechnicalTab() {
    final tech = _comprehensive?['technical'] ?? _profile?['technical'] ?? {};
    final rsi = tech['rsi'] ?? tech['rsi_14'] ?? _stockQuote?['rsi'];
    final ma50 = tech['ma_50'] ?? tech['sma_50'] ?? _stockQuote?['ma_50'];
    final ma200 = tech['ma_200'] ?? tech['sma_200'] ?? _stockQuote?['ma_200'];
    final trend = tech['trend'] ?? 'neutral';
    final signal = tech['signal'] ?? tech['action'] ?? 'HOLD';
    final support = tech['support'] ?? _stockQuote?['support_level'];
    final resistance = tech['resistance'] ?? _stockQuote?['resistance_level'];
    final high52 = tech['high_52w'] ?? _fundamentals?['high_52w'] ?? _stockQuote?['high_52w'];
    final low52 = tech['low_52w'] ?? _fundamentals?['low_52w'] ?? _stockQuote?['low_52w'];

    final rsiVal = rsi is num ? rsi.toDouble() : (rsi != null ? double.tryParse(rsi.toString()) : null);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // مؤشر RSI
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مؤشر القوة النسبية (RSI 14)',
                      style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    rsiVal != null ? rsiVal.toStringAsFixed(1) : '-',
                    style: TextStyle(
                      color: rsiVal != null && (rsiVal > 70 || rsiVal < 30)
                          ? AppColors.warning
                          : AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: rsiVal != null ? (rsiVal / 100).clamp(0.0, 1.0) : 0.5,
                backgroundColor: Colors.white12,
                color: rsiVal != null && rsiVal > 70
                    ? AppColors.danger
                    : (rsiVal != null && rsiVal < 30 ? AppColors.success : AppColors.primaryLight),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تشبع بيعي (30)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text(
                    rsiVal != null && rsiVal > 70
                        ? 'منطقة تشبع شرائي (Overbought)'
                        : (rsiVal != null && rsiVal < 30
                            ? 'منطقة تشبع بيعي (Oversold)'
                            : 'منطقة معتدلة'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  const Text('تشبع شرائي (70)', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // بطاقات المؤشرات الفنية المنسقة
        _buildDataRow('الاتجاه الفني العام (Trend)', trend == 'bullish' ? 'صاعد ↗️' : (trend == 'bearish' ? 'هابط ↘️' : 'محايد ➡️')),
        _buildDataRow('إشارة التحليل الفني (Signal)', signal.toString()),
        _buildDataRow('المتوسط المتحرك 50 يوم (SMA 50)', ma50 != null ? '${(ma50 is num ? ma50.toStringAsFixed(2) : ma50)} ج.م' : '-'),
        _buildDataRow('المتوسط المتحرك 200 يوم (SMA 200)', ma200 != null ? '${(ma200 is num ? ma200.toStringAsFixed(2) : ma200)} ج.م' : '-'),
        _buildDataRow('مستوى الدعم الرئيسي (Support)', support != null ? '${(support is num ? support.toStringAsFixed(2) : support)} ج.م' : '-'),
        _buildDataRow('مستوى المقاومة الرئيسي (Resistance)', resistance != null ? '${(resistance is num ? resistance.toStringAsFixed(2) : resistance)} ج.م' : '-'),
        _buildDataRow('أعلى سعر خلال 52 أسبوع', high52 != null ? '$high52 ج.م' : '-'),
        _buildDataRow('أدنى سعر خلال 52 أسبوع', low52 != null ? '$low52 ج.م' : '-'),
      ],
    );
  }

  // ─── Tab 3: Deep Financials & Statements ───────────────────────────────────

  Widget _buildFinancialsTab() {
    final val = _profile?['valuation'] ?? _comprehensive?['keyMetrics'] ?? {};
    final prof = _profile?['profitability'] ?? {};
    final bs = _profile?['balance_sheet'] ?? {};
    final inc = _profile?['income_statement'] ?? {};
    final cf = _profile?['cash_flow'] ?? {};
    final div = _profile?['dividends'] ?? {};

    final pe = val['pe_ratio'] ?? _fundamentals?['pe_ratio'] ?? _stockQuote?['pe_ratio'];
    final pb = val['pb_ratio'] ?? _fundamentals?['pb_ratio'] ?? _stockQuote?['pb_ratio'];
    final ps = val['ps_ratio'];
    final eps = inc['eps'] ?? _fundamentals?['eps'] ?? _stockQuote?['eps'];
    final mcap = _stockQuote?['market_cap'] ?? _comprehensive?['keyMetrics']?['market_cap'];
    final divYield = div['dividend_yield'] ?? _fundamentals?['dividend_yield'] ?? _stockQuote?['dividend_yield'];

    final roe = prof['roe'] ?? _fundamentals?['roe'];
    final roa = prof['roa'];
    final grossMargin = prof['gross_margin'];
    final netMargin = prof['net_profit_margin'];

    final totalAssets = bs['total_assets'];
    final totalLiabilities = bs['total_liabilities'];
    final totalEquity = bs['total_equity'];
    final cash = bs['cash_and_equivalents'];
    final revenue = inc['revenue'];
    final netIncome = inc['net_income'];
    final opCashFlow = cf['operating_cash_flow'];
    final freeCashFlow = cf['free_cash_flow'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. مؤشرات التقييم
        const Text('مؤشرات التقييم (Valuation Multiples)',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildDataRow('مضاعف الربحية (P/E Ratio)', pe != null ? '${_safeNum(pe).toStringAsFixed(1)}' : '-'),
        _buildDataRow('مضاعف القيمة الدفترية (P/B Ratio)', pb != null ? '${_safeNum(pb).toStringAsFixed(1)}' : '-'),
        if (ps != null)
          _buildDataRow('مضاعف المبيعات (P/S Ratio)', '${_safeNum(ps).toStringAsFixed(1)}'),
        _buildDataRow('ربحية السهم (EPS)', eps != null ? '${_safeNum(eps).toStringAsFixed(2)} ج.م' : '-'),
        _buildDataRow('عائد التوزيعات السنوي', divYield != null ? '${_safeNum(divYield).toStringAsFixed(1)}%' : '-'),
        _buildDataRow('القيمة السوقية للشركة', _formatLargeNumber(mcap)),

        const SizedBox(height: 16),

        // 2. مؤشرات الربحية
        const Text('مؤشرات الربحية والتشغيل (Profitability)',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        _buildDataRow('العائد على حقوق المساهمين (ROE)', roe != null ? '${_safeNum(roe).toStringAsFixed(1)}%' : '-'),
        if (roa != null)
          _buildDataRow('العائد على الأصول (ROA)', '${_safeNum(roa).toStringAsFixed(1)}%'),
        if (grossMargin != null)
          _buildDataRow('هامش مجمل الربح (Gross Margin)', '${_safeNum(grossMargin).toStringAsFixed(1)}%'),
        if (netMargin != null)
          _buildDataRow('هامش صافي الربح (Net Margin)', '${_safeNum(netMargin).toStringAsFixed(1)}%'),

        const SizedBox(height: 16),

        // 3. القوائم المالية الهيكلية
        const Text('القوائم المالية الهيكلية (Financial Statements)',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (revenue != null) _buildDataRow('الإيرادات (Revenue)', _formatLargeNumber(revenue)),
        if (netIncome != null) _buildDataRow('صافي الدخل (Net Income)', _formatLargeNumber(netIncome)),
        if (totalAssets != null) _buildDataRow('إجمالي الأصول (Assets)', _formatLargeNumber(totalAssets)),
        if (totalLiabilities != null) _buildDataRow('إجمالي الالتزامات (Liabilities)', _formatLargeNumber(totalLiabilities)),
        if (totalEquity != null) _buildDataRow('حقوق المساهمين (Equity)', _formatLargeNumber(totalEquity)),
        if (cash != null) _buildDataRow('النقد وما يعادله (Cash)', _formatLargeNumber(cash)),
        if (opCashFlow != null) _buildDataRow('التدفق النقدي التشغيلي', _formatLargeNumber(opCashFlow)),
        if (freeCashFlow != null) _buildDataRow('التدفق النقدي الحر (FCF)', _formatLargeNumber(freeCashFlow)),
      ],
    );
  }

  double _safeNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v != null) return double.tryParse(v.toString()) ?? 0.0;
    return 0.0;
  }

  String _formatLargeNumber(dynamic v) {
    if (v == null) return '-';
    final n = _safeNum(v);
    if (n >= 1e12) return '${(n / 1e12).toStringAsFixed(2)} تريليون ج.م';
    if (n >= 1e9) return '${(n / 1e9).toStringAsFixed(2)} مليار ج.م';
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(2)} مليون ج.م';
    if (n > 0) return '${n.toStringAsFixed(0)} ج.م';
    return '-';
  }

  // ─── Tab 4: Orderbook ──────────────────────────────────────────────────────

  Widget _buildOrderBookTab() {
    if (_orderBook == null ||
        (_orderBook!.bids.isEmpty && _orderBook!.asks.isEmpty)) {
      return const Center(
          child: Text('لا توجد بيانات لدفتر الأوامر حالياً',
              style: TextStyle(color: AppColors.textMuted)));
    }

    final bids = _orderBook!.bids;
    final asks = _orderBook!.asks;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                          color: AppColors.success,
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
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م',
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold)),
                            Text('${item.volume}',
                                style: const TextStyle(color: AppColors.textSecondary)),
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
                          color: AppColors.danger,
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
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.price} ج.م',
                                style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold)),
                            Text('${item.volume}',
                                style: const TextStyle(color: AppColors.textSecondary)),
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

  // ─── Tab 5: Disclosures ────────────────────────────────────────────────────

  Widget _buildDisclosuresTab() {
    if (_disclosures.isEmpty) {
      return const Center(
          child: Text('لا توجد إفصاحات مسجلة',
              style: TextStyle(color: AppColors.textMuted)));
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
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
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(d.category,
                        style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    '${d.date.day}/${d.date.month}/${d.date.year}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(d.title,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              if (d.summary != null) ...[
                const SizedBox(height: 4),
                Text(d.summary!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Tab 6: News ───────────────────────────────────────────────────────────

  Widget _buildStockNewsTab() {
    if (_newsFuture == null) {
      return const Center(child: Text('اضغط على تبويب الأخبار لتحميلها'));
    }
    return FutureBuilder<dynamic>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: AppColors.danger)));
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
                Icon(Icons.newspaper_outlined, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('لا توجد أخبار متاحة لهذا السهم حالياً',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: news.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
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

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                  if (source.isNotEmpty || date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (source.isNotEmpty)
                          Text(source,
                              style: const TextStyle(fontSize: 10, color: AppColors.primaryLight)),
                        if (source.isNotEmpty && date.isNotEmpty)
                          const Text(' • ', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        if (date.isNotEmpty)
                          Text(date.split('T').first,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDataRow(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
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
      color: AppColors.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
