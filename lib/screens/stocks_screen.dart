// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import 'stock_history_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, this.marketVersion = 0});

  final int marketVersion;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  Future<List<Stock>>? _stocksFuture;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showMovers = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  static const int _pageSize = 20;
  List<Stock> _allStocks = <Stock>[];
  List<Stock> _displayedStocks = <Stock>[];
  bool _hasMore = true;

  List<Map<String, dynamic>> get _gainers =>
      (_movementData?['gainers'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get _losers =>
      (_movementData?['losers'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      <Map<String, dynamic>>[];
  List<Map<String, dynamic>> get _active =>
      (_movementData?['most_active'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      <Map<String, dynamic>>[];

  Map<String, dynamic>? _movementData;
  String _activeMarket = 'EGX';
  String _movementFilter = 'gainers';

  String get _marketTitle {
    switch (_activeMarket) {
      case 'TADAWUL':
        return 'أسهم السعودية';
      case 'KSE':
        return 'أسهم الكويت';
      case 'QSE':
        return 'أسهم قطر';
      case 'DFM':
        return 'أسهم دبي';
      case 'ADX':
        return 'أسهم أبوظبي';
      case 'BSE':
        return 'أسهم البحرين';
      default:
        return 'الأسهم المصرية';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadActiveMarket().then((_) {
      _loadStocks(_query);
      _loadMovement();
    });
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarket().then((_) {
        _loadStocks(_query);
        _loadMovement();
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Stock>> _fetchStocks([String? search, String? market]) async {
    final response = await api.getStocks(search: search ?? '', market: market);
    return (response['stocks'] as List?)
            ?.map((e) => Stock.fromJson(e))
            .toList() ??
        <Stock>[];
  }

  Future<Map<String, dynamic>?> _fetchMovement([String? market]) async {
    try {
      final data = await api.getStockMovementClassification(market: market);
      final rawWrapper = data['data'];
      final wrapper = rawWrapper is Map ? Map<String, dynamic>.from(rawWrapper) : null;
      return wrapper ?? data;
    } catch (e) {
      debugPrint(
          '[Stocks] Movement classification error (may be unavailable): $e');
      return null;
    }
  }

  Future<void> _loadActiveMarket() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeMarket = prefs.getString('active_market') ?? 'EGX';
      });
    }
  }

  Future<void> _loadStocks([String? search]) async {
    _query = search ?? _query;
    _currentPage = 1;
    _hasMore = true;
    _allStocks = <Stock>[];
    _displayedStocks = <Stock>[];
    _stocksFuture = _fetchStocks(_query, _activeMarket);
    _stocksFuture!.then((stocks) {
      _allStocks = stocks;
      _displayedStocks = stocks.take(_pageSize).toList();
      _hasMore = stocks.length > _pageSize;
      if (mounted) setState(() {});
    }).catchError((e) {
      debugPrint('[Stocks] Load failed: $e');
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadMoreStocks() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    final start = (_currentPage - 1) * _pageSize;
    final end = start + _pageSize;
    final nextBatch = _allStocks.skip(start).take(_pageSize).toList();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _displayedStocks.addAll(nextBatch);
    _hasMore = end < _allStocks.length;
    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadMovement() async {
    final data = await _fetchMovement(_activeMarket);
    if (mounted) {
      if (data != null &&
          (data['gainers'] is List || data['losers'] is List || data['most_active'] is List)) {
        setState(() => _movementData = data);
      } else {
        _fetchMovementFallback(_activeMarket);
      }
    }
  }

  Future<void> _fetchMovementFallback(String market) async {
    try {
      final overview = await api.getMarketOverview(market);
      final topMovers = <String, dynamic>{
        'gainers': (overview.topGainers ?? [])
            .map((s) => <String, dynamic>{
                  'ticker': s.ticker,
                  'price': s.currentPrice,
                  'change_percent': s.changePercent,
                })
            .toList(),
        'losers': (overview.topLosers ?? [])
            .map((s) => <String, dynamic>{
                  'ticker': s.ticker,
                  'price': s.currentPrice,
                  'change_percent': s.changePercent,
                })
            .toList(),
        'most_active': (overview.mostActive ?? [])
            .map((s) => <String, dynamic>{
                  'ticker': s.ticker,
                  'price': s.currentPrice,
                  'change_percent': s.changePercent,
                })
            .toList(),
      };
      if (mounted) {
        setState(() => _movementData = topMovers);
      }
    } catch (e) {
      debugPrint('[Stocks] Movement fallback failed: $e');
    }
  }

  void _onSearchChanged(String value) {
    _searchCtrl.text = value;
    _query = value;
    _loadStocks(value);
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
          title: Text(_marketTitle,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.surface,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن سهم...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _onSearchChanged(''))
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            // Movement toggle + filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.surface,
              child: Row(children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'gainers', label: Text('المرتفعة')),
                      ButtonSegment(value: 'losers', label: Text('المنخفضة')),
                      ButtonSegment(
                          value: 'active', label: Text('الأكثر نشاطاً')),
                    ],
                    selected: {_movementFilter},
                    onSelectionChanged: (val) {
                      setState(() => _movementFilter = val.first);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                      _showMovers ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showMovers = !_showMovers),
                ),
              ]),
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  await _loadStocks(_query);
                  await _loadMovement();
                },
                child: CustomScrollView(
                  slivers: [
                    if (_showMovers) _buildMoversSliver(),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= _displayedStocks.length) {
                            if (_hasMore) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _loadMoreStocks());
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppColors.primary)),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          final stock = _displayedStocks[index];
                          return _StockCard(stock: stock);
                        },
                        childCount:
                            _displayedStocks.length + (_hasMore ? 1 : 0),
                      ),
                    ),
                    if (_displayedStocks.isEmpty &&
                        !_stocksFuture.toString().contains('waiting'))
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _query.isEmpty
                                  ? 'لا توجد أسهم متاحة'
                                  : 'لا توجد نتائج لـ "$_query"',
                              style:
                                  const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoversSliver() {
    if (_movementData == null) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          ),
        ),
      );
    }
    final movers = _movementFilter == 'gainers'
        ? _gainers
        : _movementFilter == 'losers'
            ? _losers
            : _active;
    if (movers.isEmpty)
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _movementFilter == 'gainers'
                ? 'لا توجد أسهم مرتفعة حالياً'
                : _movementFilter == 'losers'
                    ? 'لا توجد أسهم منخفضة حالياً'
                    : 'لا توجد بيانات نشاط حالياً',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: movers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final m = movers[i];
            final ticker =
                m['ticker']?.toString() ?? m['symbol']?.toString() ?? '';
            final price =
                double.tryParse((m['price'] ?? m['last'] ?? '0').toString()) ??
                    0;
            final change =
                double.tryParse((m['change_percent'] ?? '0').toString()) ?? 0;
            final isUp = change >= 0;
             return Container(
               width: 120,
               padding: const EdgeInsets.all(10),
               decoration: BoxDecoration(
                 color: AppColors.surface,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppColors.border),
               ),
               child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(ticker,
                         style: const TextStyle(
                             fontWeight: FontWeight.w700, fontSize: 13),
                         overflow: TextOverflow.ellipsis,
                         maxLines: 1),
                     const SizedBox(height: 4),
                     Text(price.toStringAsFixed(2),
                         style: const TextStyle(fontSize: 12)),
                     const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(
                           horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: (isUp ? AppColors.success : AppColors.danger)
                             .withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                           '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                           style: TextStyle(
                               fontSize: 11,
                               fontWeight: FontWeight.w600,
                               color:
                                   isUp ? AppColors.success : AppColors.danger),
                           overflow: TextOverflow.ellipsis,
                           maxLines: 1,
                         ),
                     ),
                   ],
                 ),
             );
          },
        ),
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final Stock stock;
  const _StockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final change = stock.priceChange ?? 0;
    final changePercent = stock.changePercent ?? 0;
    final isUp = change >= 0;
    final price = stock.currentPrice?.toStringAsFixed(2) ?? '0';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StockHistoryScreen(ticker: stock.ticker))),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isUp ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isUp ? Icons.trending_up : Icons.trending_down,
                color: isUp ? AppColors.success : AppColors.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(stock.nameAr ?? stock.name ?? stock.ticker,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (stock.ticker.isNotEmpty)
                  Text(stock.ticker,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (changePercent != 0)
              Text('${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isUp ? AppColors.success : AppColors.danger)),
          ]),
        ]),
      ),
    );
  }
}
