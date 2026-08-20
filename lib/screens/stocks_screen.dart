// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// FutureBuilder Powered Data Fetching & Market Classification
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
  Future<Map<String, dynamic>?>? _movementFuture;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _showMovers = true;
  String _activeMarket = 'EGX';
  String _movementFilter = 'gainers';

  @override
  void initState() {
    super.initState();
    _refreshData();
    _loadActiveMarketAndData();
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarketAndData();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveMarketAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final market = prefs.getString('active_market') ?? 'EGX';
    if (mounted && market != _activeMarket) {
      setState(() {
        _activeMarket = market;
        _refreshData();
      });
    }
  }

  void _refreshData() {
    setState(() {
      _stocksFuture = _fetchStocks(_query, _activeMarket);
      _movementFuture = _fetchMovement(_activeMarket);
    });
  }

  Future<List<Stock>> _fetchStocks([String? search, String? market]) async {
    final targetMarket = market ?? _activeMarket;
    final response = await api.getStocks(search: search ?? '', market: targetMarket);
    final list = (response['stocks'] as List?)
            ?.map((e) => Stock.fromJson(e))
            .toList() ??
        <Stock>[];
    if (targetMarket == 'ALL') return list;
    return list.where((s) {
      final isNumeric = RegExp(r'^\d{4}$').hasMatch(s.ticker);
      if (targetMarket == 'EGX') {
        if (isNumeric) return false;
      } else if (targetMarket == 'TADAWUL') {
        if (!isNumeric) return false;
      }
      return true;
    }).toList();
  }

  Future<Map<String, dynamic>?> _fetchMovement([String? market]) async {
    try {
      final data = await api.getStockMovementClassification(market: market);
      final rawWrapper = data['data'];
      final wrapper = rawWrapper is Map ? Map<String, dynamic>.from(rawWrapper) : null;
      if (wrapper != null || data.isNotEmpty) return wrapper ?? data;
      return await _fetchMovementFallback(market ?? 'EGX');
    } catch (e) {
      debugPrint('[Stocks] Movement classification error: $e');
      return await _fetchMovementFallback(market ?? 'EGX');
    }
  }

  Future<Map<String, dynamic>> _fetchMovementFallback(String market) async {
    try {
      final overview = await api.getMarketOverview(market);
      return {
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
    } catch (e) {
      debugPrint('[Stocks] Movement fallback failed: $e');
      return {};
    }
  }

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

  void _onSearchChanged(String value) {
    _query = value;
    setState(() {
      _stocksFuture = _fetchStocks(_query, _activeMarket);
    });
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
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          })
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
            // Content FutureBuilder
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => _refreshData(),
                child: CustomScrollView(
                  slivers: [
                    if (_showMovers) _buildMoversSliver(),
                    _buildStocksListSliver(),
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
    return FutureBuilder<Map<String, dynamic>?>(
      future: _movementFuture ??= _fetchMovement(_activeMarket),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final gainers = (data['gainers'] as List?) ?? [];
        final losers = (data['losers'] as List?) ?? [];
        final active = (data['most_active'] as List?) ?? [];

        final movers = _movementFilter == 'gainers'
            ? gainers
            : _movementFilter == 'losers'
                ? losers
                : active;

        if (movers.isEmpty) {
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
        }

        return SliverToBoxAdapter(
          child: SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: movers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = movers[i] is Map ? movers[i] as Map : {};
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
                              color: isUp ? AppColors.success : AppColors.danger),
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
      },
    );
  }

  Widget _buildStocksListSliver() {
    return FutureBuilder<List<Stock>>(
      future: _stocksFuture ??= _fetchStocks(_query, _activeMarket),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    const Text('حدث خطأ في جلب بيانات الأسهم', style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final stocks = snapshot.data ?? [];
        if (stocks.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _query.isEmpty
                      ? 'لا توجد أسهم متاحة'
                      : 'لا توجد نتائج لـ "$_query"',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _StockCard(stock: stocks[index]),
            childCount: stocks.length,
          ),
        );
      },
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
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
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
