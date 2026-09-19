// ============================================================================
// مساعد الاستثمار Flutter - Stock Search & Instant Inspection Dialog
// فحص وتحليل أي سهم + شارت TradingView
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../screens/stock_history_screen.dart';
import '../screens/trading_chart_screen.dart';

class StockSearchDialog extends StatefulWidget {
  const StockSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const StockSearchDialog(),
    );
  }

  @override
  State<StockSearchDialog> createState() => _StockSearchDialogState();
}

class _StockSearchDialogState extends State<StockSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allStocks = [];
  List<Map<String, dynamic>> _filteredStocks = [];
  bool _isLoading = true;

  static const List<Map<String, dynamic>> _popularStocks = [
    {'ticker': 'COMI', 'name_ar': 'البنك التجاري الدولي', 'sector': 'بنوك'},
    {'ticker': 'FWRY', 'name_ar': 'فوري لتكنولوجيا البنوك', 'sector': 'تكنولوجيا'},
    {'ticker': 'HRHO', 'name_ar': 'إي إف جي القابضة', 'sector': 'خدمات مالية'},
    {'ticker': 'SWDY', 'name_ar': 'السويدي إليكتريك', 'sector': 'صناعي'},
    {'ticker': 'EKHO', 'name_ar': 'المصرية الكويتية القابضة', 'sector': 'استثمار'},
    {'ticker': 'ABUK', 'name_ar': 'أبو قير للأسمدة', 'sector': 'كيماويات'},
    {'ticker': 'AMOC', 'name_ar': 'الإسكندرية للزيوت المعدنية', 'sector': 'بتروكيماويات'},
    {'ticker': 'TMGH', 'name_ar': 'مجموعة طلعت مصطفى', 'sector': 'عقارات'},
    {'ticker': 'ETEL', 'name_ar': 'المصرية للاتصالات', 'sector': 'اتصالات'},
    {'ticker': 'ESRS', 'name_ar': 'حديد عز', 'sector': 'مواد أساسية'},
  ];

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStocks() async {
    try {
      final res = await GLMApiClient.instance.getStocks(search: '', market: 'EGX');
      final dynamic rawStocks = res['stocks'];
      final list = (rawStocks is List && rawStocks.isNotEmpty) ? rawStocks : null;
      if (mounted && list != null && list.isNotEmpty) {
        final mapped = list.map((item) {
          if (item is Map) {
            return {
              'ticker': item['ticker']?.toString() ?? item['symbol']?.toString() ?? '',
              'name_ar': item['name_ar']?.toString() ?? item['name']?.toString() ?? '',
              'sector': item['sector']?.toString() ?? 'سوق رئيسي',
              'price': item['close'] ?? item['price'] ?? item['current_price'] ?? item['last_price'],
              'change_percent': item['change_percent'] ?? item['change'],
            };
          }
          return <String, dynamic>{};
        }).where((m) => (m['ticker'] as String? ?? '').isNotEmpty).toList();

        setState(() {
          _allStocks = mapped;
          _filteredStocks = mapped;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allStocks = _popularStocks;
        _filteredStocks = _popularStocks;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredStocks = _allStocks.isNotEmpty ? _allStocks : _popularStocks;
      });
      return;
    }
    setState(() {
      _filteredStocks = _allStocks.where((s) {
        final ticker = (s['ticker'] ?? '').toString().toLowerCase();
        final nameAr = (s['name_ar'] ?? '').toString().toLowerCase();
        final sector = (s['sector'] ?? '').toString().toLowerCase();
        return ticker.contains(q) || nameAr.contains(q) || sector.contains(q);
      }).toList();
    });
  }

  void _openAnalysis(String ticker, String? nameAr) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StockHistoryScreen(ticker: ticker),
      ),
    );
  }

  void _openTradingView(String ticker, String? nameAr) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TradingChartScreen(ticker: ticker, displayName: nameAr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        margin: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: AppColors.quantumBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.quantumGlassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.quantumEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.search_rounded, color: AppColors.quantumEmerald, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فحص وتحليل أي سهم',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'ابحث بالرمز أو الاسم للانتقال للتحليل أو شارت TradingView',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.quantumSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.quantumEmerald.withValues(alpha: 0.4)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'ابحث برمز السهم (COMI, FWRY) أو الاسم (طلعت مصطفى)...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.quantumEmerald),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),

            // Popular Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _popularStocks.take(6).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ActionChip(
                        backgroundColor: AppColors.quantumGlass,
                        side: const BorderSide(color: AppColors.quantumGlassBorder),
                        label: Text(
                          item['ticker']!,
                          style: const TextStyle(color: AppColors.quantumGold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          _searchController.text = item['ticker']!;
                          _onSearchChanged(item['ticker']!);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const Divider(color: Colors.white12, height: 16),

            // List of Stocks
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
                  : _filteredStocks.isEmpty
                      ? const Center(
                          child: Text('لم يتم العثور على أسهم تطابق بحثك',
                              style: TextStyle(color: Colors.white54, fontSize: 13)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredStocks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final s = _filteredStocks[idx];
                            final ticker = s['ticker']?.toString() ?? '';
                            final nameAr = s['name_ar']?.toString() ?? ticker;
                            final sector = s['sector']?.toString() ?? '';
                            final price = s['price'];
                            final change = s['change_percent'];

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.quantumSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.quantumGlassBorder),
                              ),
                              child: Row(
                                children: [
                                  // Ticker badge
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.quantumEmerald, Color(0xFF0F5A47)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      ticker,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nameAr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          sector,
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        if (price != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'السعر: $price ج.م ${change != null ? "($change%)" : ""}',
                                            style: TextStyle(
                                              color: (change is num && change >= 0)
                                                  ? AppColors.quantumEmerald
                                                  : Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Action Buttons
                                  Column(
                                    children: [
                                      // Full Inspection
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.quantumEmerald,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.analytics_rounded, size: 14),
                                        label: const Text(
                                          'تحليل وفحص',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _openAnalysis(ticker, nameAr),
                                      ),
                                      const SizedBox(height: 6),
                                      // TradingView
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.quantumGold,
                                          side: BorderSide(color: AppColors.quantumGold.withValues(alpha: 0.6)),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.candlestick_chart, size: 13),
                                        label: const Text(
                                          'TradingView',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _openTradingView(ticker, nameAr),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
