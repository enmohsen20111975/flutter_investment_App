// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/bubble_buttons.dart';
import 'stock_history_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, this.marketVersion = 0});

  final int marketVersion;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  Future<List<Stock>>? _stocksFuture;
  Future<Map<String, dynamic>?>? _movementFuture;
  String _query = '';
  bool _showMovers = false;

  List<Map<String, dynamic>> get _gainers =>
      (_movementData?['gainers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _losers =>
      (_movementData?['losers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _active =>
      (_movementData?['most_active'] as List?)?.cast<Map<String, dynamic>>() ??
      [];

  Map<String, dynamic>? _movementData;
  String _activeMarket = 'EGX';

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
      _stocksFuture = _fetchStocks(_query);
      _movementFuture = _fetchMovement();
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadActiveMarket() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _activeMarket = prefs.getString('active_market') ?? 'EGX';
      });
    }
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarket().then((_) {
        _stocksFuture = _fetchStocks(_query);
        _movementFuture = _fetchMovement();
        if (mounted) setState(() {});
      });
    }
  }

  Future<List<Stock>> _fetchStocks([String? search, String? market]) async {
    final response = await api.getStocks(search: search ?? '', market: market);
    return (response['stocks'] as List?)
            ?.map((e) => Stock.fromJson(e))
            .toList() ??
        [];
  }

  Future<Map<String, dynamic>?> _fetchMovement([String? market]) async {
    try {
      return await api.getStockMovementClassification(market: market);
    } catch (e) {
      debugPrint(
          '[Stocks] Movement classification error (may be unavailable): $e');
      return null;
    }
  }

  Future<void> _loadStocks([String? search]) async {
    _stocksFuture = _fetchStocks(search ?? '', _activeMarket);
  }

  Future<void> _loadMovement() async {
    _movementFuture = _fetchMovement(_activeMarket);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: BubbleFloatingButton(
        icon: Icons.refresh,
        label: 'تحديث',
        extended: true,
        onPressed: () {
          setState(() {
            _stocksFuture = null;
          });
          _loadStocks(_query);
        },
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {
            _stocksFuture = null;
          });
          await _loadStocks(_query);
          await _loadMovement();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث بالرمز أو الاسم...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textMuted),
                            onPressed: () {
                              setState(() => _query = '');
                              _loadStocks('');
                            })
                        : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: (v) => _loadStocks(v),
                ),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>?>(
                future: _movementFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border)),
                      child: const Row(
                        children: [
                          SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('جاري تحميل بيانات الحركة...',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    _movementData = snapshot.data;
                    return Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.trending_up,
                                size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('عرض الأسهم الأكثر حركة',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BubbleActionMenu(
                          items: [
                            BubbleMenuItem(
                              icon: Icons.list,
                              label: 'كل الأسهم',
                              isActive: !_showMovers,
                              onPressed: () =>
                                  setState(() => _showMovers = false),
                            ),
                            BubbleMenuItem(
                              icon: Icons.trending_up,
                              label: 'الأكثر حركة',
                              isActive: _showMovers,
                              onPressed: () =>
                                  setState(() => _showMovers = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              FutureBuilder<List<Stock>>(
                future: _stocksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'فشل تحميل الأسهم: ${snapshot.error}',
                        onRetry: () => _loadStocks(''));
                  }
                  final stocks = snapshot.data ?? [];
                  if (stocks.isEmpty) {
                    return const StateView(
                        empty: true, emptyMessage: 'لا توجد أسهم متاحة حالياً');
                  }
                  if (_showMovers) return _buildMoversSection();
                  return Column(
                    children: [
                      HeaderCard(
                          icon: Icons.trending_up,
                          title: _marketTitle,
                          subtitle: 'السوق النشط: $_activeMarket'),
                      const SizedBox(height: 16),
                      ...stocks.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DataRowWidget(
                              title: s.nameAr ?? s.name ?? s.ticker,
                              subtitle: s.ticker,
                              value: s.currentPrice != null
                                  ? '${s.currentPrice!.toStringAsFixed(2)} ج.م'
                                  : '-',
                              change: s.changePercent,
                              icon: Icons.trending_up,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => StockHistoryScreen(
                                          ticker: s.ticker))),
                            ),
                          )),
                    ],
                  );
                },
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoversSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_gainers.isNotEmpty) ...[
          const SectionHeader(
              title: 'الأكثر ارتفاعاً', icon: Icons.trending_up),
          const SizedBox(height: 8),
          ..._gainers.map((s) => _buildMoverCard(s, true)),
          const SizedBox(height: 16),
        ],
        if (_losers.isNotEmpty) ...[
          const SectionHeader(
              title: 'الأكثر انخفاضاً', icon: Icons.trending_down),
          const SizedBox(height: 8),
          ..._losers.map((s) => _buildMoverCard(s, false)),
          const SizedBox(height: 16),
        ],
        if (_active.isNotEmpty) ...[
          const SectionHeader(title: 'الأكثر تداولاً', icon: Icons.bar_chart),
          const SizedBox(height: 8),
          ..._active.map((s) => _buildMoverCard(s, null)),
        ],
        if (_gainers.isEmpty && _losers.isEmpty && _active.isEmpty)
          const StateView(
              empty: true, emptyMessage: 'لا توجد بيانات حركة متاحة'),
      ],
    );
  }

  Widget _buildMoverCard(Map<String, dynamic> s, bool? isUp) {
    final ticker = s['ticker'] ?? s['symbol'] ?? '';
    final name = s['name_ar'] ?? s['name'] ?? '';
    final change = (s['change_percent'] as num?)?.toDouble() ?? 0;
    final price = (s['current_price'] as num?)?.toDouble() ?? 0;
    final color = isUp == null
        ? AppColors.info
        : isUp
            ? AppColors.success
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => StockHistoryScreen(ticker: ticker))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(
                isUp == null
                    ? Icons.bar_chart
                    : isUp
                        ? Icons.trending_up
                        : Icons.trending_down,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: AppTypography.titleSmall),
                if (name.isNotEmpty)
                  Text(name,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${price.toStringAsFixed(2)} ج.م',
                    style: AppTypography.titleSmall),
                Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
