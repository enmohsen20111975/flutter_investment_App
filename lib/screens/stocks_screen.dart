// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/bubble_buttons.dart';
import 'stock_history_screen.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key});

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  List<Stock> _stocks = [];
  Map<String, dynamic>? _movementData;
  String _query = '';
  bool _loading = true;
  bool _loadingMovement = false;
  String? _error;
  bool _showMovers = false;

  List<Map<String, dynamic>> get _gainers =>
      (_movementData?['gainers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _losers =>
      (_movementData?['losers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  List<Map<String, dynamic>> get _active =>
      (_movementData?['most_active'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Stagger the loading to prevent UI jank
      _loadStocks(_query);
      Future.delayed(const Duration(milliseconds: 400), _loadMovement);
    });
  }

  Future<void> _loadStocks([String? search]) async {
    try {
      setState(() { _loading = true; _error = null; });
      debugPrint('[Stocks] Loading stocks...');

      final response = await api.getStocks(search ?? '');
      final serverStocks = (response['stocks'] as List?)?.map((e) => Stock.fromJson(e)).toList() ?? [];

      debugPrint('[Stocks] Loaded ${serverStocks.length} stocks');
      if (mounted) setState(() { _stocks = serverStocks; _loading = false; });
    } catch (e) {
      debugPrint('[Stocks] Error loading stocks: $e');
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _loadMovement() async {
    try {
      setState(() { _loadingMovement = true; });

      final data = await api.getStockMovementClassification();
      if (mounted) setState(() { _movementData = data; _loadingMovement = false; });
    } catch (e) {
      debugPrint('[Stocks] Movement classification error (may be unavailable): $e');
      if (mounted) setState(() { _loadingMovement = false; });
    }
  }

  Future<void> _refreshAll() async {
    await _loadStocks(_query);
    await _loadMovement();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: BubbleFloatingButton(
        icon: Icons.refresh,
        label: 'تحديث',
        extended: true,
        onPressed: _refreshAll,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ابحث بالرمز أو الاسم...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textMuted), onPressed: () { setState(() => _query = ''); _loadStocks(''); }) : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: (v) => _loadStocks(v),
                ),
              ),
              const SizedBox(height: 12),
              if (_movementData != null || _loadingMovement) ...[
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    const Text('عرض الأسهم الأكثر حركة', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                BubbleActionMenu(
                  items: [
                    BubbleMenuItem(
                      icon: Icons.list,
                      label: 'كل الأسهم',
                      isActive: !_showMovers,
                      onPressed: () => setState(() => _showMovers = false),
                    ),
                    BubbleMenuItem(
                      icon: Icons.trending_up,
                      label: 'الأكثر حركة',
                      isActive: _showMovers,
                      onPressed: () => setState(() => _showMovers = true),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_loading)
                const StateView(loading: true)
              else if (_error != null && _stocks.isEmpty)
                StateView(error: _error, onRetry: () => _loadStocks(''))
              else ...[
                if (_showMovers) _buildMoversSection() else ...[
                  const HeaderCard(icon: Icons.trending_up, title: 'الأسهم المصرية', subtitle: 'تتبع أسعار الأسهم لحظياً'),
                  const SizedBox(height: 16),
                  if (_stocks.isEmpty)
                    const StateView(empty: true, emptyMessage: 'لا توجد أسهم متاحة حالياً')
                  else
                    ..._stocks.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DataRowWidget(
                        title: s.nameAr ?? s.name ?? s.ticker,
                        subtitle: s.ticker,
                        value: s.currentPrice != null ? '${s.currentPrice!.toStringAsFixed(2)} ج.م' : '-',
                        change: s.changePercent,
                        icon: Icons.trending_up,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockHistoryScreen(ticker: s.ticker))),
                      ),
                    )),
                ],
              ],
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
          const SectionHeader(title: 'الأكثر ارتفاعاً', icon: Icons.trending_up),
          const SizedBox(height: 8),
          ..._gainers.map((s) => _buildMoverCard(s, true)),
          const SizedBox(height: 16),
        ],
        if (_losers.isNotEmpty) ...[
          const SectionHeader(title: 'الأكثر انخفاضاً', icon: Icons.trending_down),
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
          const StateView(empty: true, emptyMessage: 'لا توجد بيانات حركة متاحة'),
      ],
    );
  }

  Widget _buildMoverCard(Map<String, dynamic> s, bool? isUp) {
    final ticker = s['ticker'] ?? s['symbol'] ?? '';
    final name = s['name_ar'] ?? s['name'] ?? '';
    final change = (s['change_percent'] as num?)?.toDouble() ?? 0;
    final price = (s['current_price'] as num?)?.toDouble() ?? 0;
    final color = isUp == null ? AppColors.info : isUp ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockHistoryScreen(ticker: ticker))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(
                isUp == null ? Icons.bar_chart : isUp ? Icons.trending_up : Icons.trending_down,
                color: color, size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: AppTypography.titleSmall),
                if (name.isNotEmpty) Text(name, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${price.toStringAsFixed(2)} ج.م', style: AppTypography.titleSmall),
                Text('${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
