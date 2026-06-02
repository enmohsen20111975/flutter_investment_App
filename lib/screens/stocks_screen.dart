// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
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
  bool _refreshing = false;
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
    _loadData('');
  }

  Future<void> _loadData(String search, {bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      
      debugPrint('[Stocks] Loading stocks with query: $search');
      
      final results = await Future.wait([
        api.getStocks(search),
        api.getStockMovementClassification(),
      ]);
      
      final response = results[0] as Map<String, dynamic>;
      final serverStocks = (response['stocks'] as List?)?.map((e) => Stock.fromJson(e)).toList() ?? [];
      _movementData = results[1] as Map<String, dynamic>;
      
      debugPrint('[Stocks] Loaded ${serverStocks.length} stocks');
      debugPrint('[Stocks] Movement data: ${_gainers.length} gainers, ${_losers.length} losers');
      
      setState(() { _stocks = serverStocks; _loading = false; _refreshing = false; });
    } catch (e) {
      debugPrint('[Stocks] Error loading data: $e');
      setState(() { _error = 'فشل تحميل البيانات. اسحب للتحديث.'; _loading = false; _refreshing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { setState(() => _refreshing = true); await _loadData(_query, silent: true); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
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
                      suffixIcon: _query.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textMuted), onPressed: () { setState(() => _query = ''); _loadData(''); }) : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: (v) => _loadData(v),
                  ),
                ),
                const SizedBox(height: 12),

                if (_movementData != null && (_gainers.isNotEmpty || _losers.isNotEmpty)) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilterChip(
                          selected: !_showMovers,
                          label: Text('كل الأسهم', style: TextStyle(fontSize: 12, color: !_showMovers ? AppColors.white : AppColors.textSecondary)),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onSelected: (_) => setState(() => _showMovers = false),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: FilterChip(
                          selected: _showMovers,
                          label: Text('الأكثر حركة', style: TextStyle(fontSize: 12, color: _showMovers ? AppColors.white : AppColors.textSecondary)),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onSelected: (_) => setState(() => _showMovers = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (_loading)
                  const StateView(loading: true)
                else if (_error != null && _stocks.isEmpty)
                  StateView(error: _error, onRetry: () => _loadData(_query))
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
