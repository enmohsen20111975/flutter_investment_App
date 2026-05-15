// ============================================================================
// مساعد الاستثمار Flutter - Stocks Screen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
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
  String _query = '';
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData('');
  }

  Future<void> _loadData(String search, {bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      final response = await api.getStocks(search);
      final serverStocks = (response['stocks'] as List?)?.map((e) => Stock.fromJson(e)).toList() ?? [];
      setState(() { _stocks = serverStocks; _loading = false; _refreshing = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
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
                // Search Bar
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
                const SizedBox(height: 16),

                StateView(loading: _loading, error: _error, onRetry: () => _loadData(_query)),

                if (!_loading && _error == null) ...[
                  const HeaderCard(icon: Icons.trending_up, title: 'الأسهم المصرية', subtitle: 'تتبع أسعار الأسهم لحظياً'),
                  const SizedBox(height: 16),
                  if (_stocks.isEmpty)
                    const StateView(empty: true, emptyMessage: 'لا توجد أسهم مطابقة للبحث')
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
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
    );
  }
}
