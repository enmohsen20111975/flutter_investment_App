// ============================================================================
// مساعد الاستثمار Flutter - Metals Screen (Gold & Silver)
// Shows gold karats, ounce price, silver price, and gold price history chart
// Uses: GET /api/market/gold, GET /api/market/gold/history
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class MetalsScreen extends StatefulWidget {
  const MetalsScreen({super.key});

  @override
  State<MetalsScreen> createState() => _MetalsScreenState();
}

class _MetalsScreenState extends State<MetalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoldResponse? _gold;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  // Gold history
  List<GoldHistoryPoint> _goldHistory = [];
  bool _loadingHistory = false;
  String _selectedKarat = '24';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      final gold = await api.getGold();
      setState(() { _gold = gold; _loading = false; _refreshing = false; });
      // Load gold history after prices
      _loadGoldHistory();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
    }
  }

  Future<void> _loadGoldHistory() async {
    setState(() { _loadingHistory = true; });
    try {
      final response = await api.getGoldHistory(karat: _selectedKarat, days: 30);
      final data = (response['data'] as List?) ?? [];
      setState(() {
        _goldHistory = data.map((e) => GoldHistoryPoint.fromJson(e)).toList();
        _loadingHistory = false;
      });
    } catch (_) {
      setState(() { _loadingHistory = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const HeaderCard(icon: Icons.star, title: 'الذهب والمعادن', subtitle: 'أسعار مباشرة من السوق'),
              const SizedBox(height: 16),
              StateView(loading: _loading, error: _error, onRetry: () => _loadData()),
              if (!_loading && _error == null) ...[
                // Gold Ounce
                if (_gold?.prices?.ounce != null) ...[
                  const SectionHeader(title: 'أسعار الأونصة', icon: Icons.attach_money),
                  const SizedBox(height: 8),
                  InfoCard(
                    title: 'سعر الأونصة',
                    value: _gold!.prices!.ounce!.price.toStringAsFixed(2),
                    subtitle: _gold!.prices!.ounce!.nameAr ?? 'أونصة ذهب',
                    tone: 'warning',
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 16),
                ],
                // Karats
                if (_gold?.prices?.karats != null && _gold!.prices!.karats!.isNotEmpty) ...[
                  const SectionHeader(title: 'أسعار العيارات', icon: Icons.diamond),
                  const SizedBox(height: 8),
                  ..._gold!.prices!.karats!.map((k) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DataRowWidget(
                      title: k.nameAr,
                      value: '${k.pricePerGram.toStringAsFixed(2)} ج.م/جرام',
                      change: k.change,
                      icon: Icons.diamond,
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
                // Silver
                if (_gold?.prices?.silver != null) ...[
                  const SectionHeader(title: 'أسعار الفضة', icon: Icons.circle),
                  const SizedBox(height: 8),
                  DataRowWidget(
                    title: 'سعر الفضة للجرام',
                    value: '${_gold!.prices!.silver!.pricePerGram.toStringAsFixed(2)} ج.م/جرام',
                    change: _gold!.prices!.silver!.change,
                    icon: Icons.circle,
                  ),
                  const SizedBox(height: 16),
                ],
                // Bullion
                if (_gold?.prices?.bullion != null && _gold!.prices!.bullion!.isNotEmpty) ...[
                  const SectionHeader(title: 'السبائك', icon: Icons.work),
                  const SizedBox(height: 8),
                  ..._gold!.prices!.bullion!.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DataRowWidget(title: b.nameAr, value: '${b.price.toStringAsFixed(2)} ج.م', change: b.change, icon: Icons.work),
                  )),
                  const SizedBox(height: 16),
                ],
                // Gold Price History
                const SectionHeader(title: 'سجل أسعار الذهب - آخر 30 يوم', icon: Icons.history),
                const SizedBox(height: 8),
                // Karat selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['24', '21', '18'].map((karat) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        selected: _selectedKarat == karat,
                        label: Text('عيار $karat', style: TextStyle(fontSize: 12, color: _selectedKarat == karat ? AppColors.white : AppColors.textSecondary)),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: _selectedKarat == karat ? AppColors.primary : AppColors.border),
                        onSelected: (_) {
                          setState(() => _selectedKarat = karat);
                          _loadGoldHistory();
                        },
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loadingHistory)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)))
                else if (_goldHistory.isNotEmpty)
                  _buildGoldHistoryChart()
                else
                  const StateView(empty: true, emptyMessage: 'لا يوجد سجل أسعار متاح'),
              ],
              const SizedBox(height: 90),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldHistoryChart() {
    final prices = _goldHistory.map((p) => p.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final range = maxPrice - minPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أعلى: ${maxPrice.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              Text('أدنى: ${minPrice.toStringAsFixed(0)} ج.م', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          // Simple line chart
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SimpleLineChartPainter(
                prices: prices,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Date range
          if (_goldHistory.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_goldHistory.last.date, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                Text(_goldHistory.first.date, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          const SizedBox(height: 12),
          // Recent prices list
          const Divider(),
          const SizedBox(height: 8),
          ..._goldHistory.take(7).map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(point.date, style: AppTypography.bodySmall),
                Text('${point.price.toStringAsFixed(2)} ج.م', style: AppTypography.titleSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (point.change ?? 0) >= 0 ? AppColors.successLight : AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(point.change ?? 0) >= 0 ? '+' : ''}${point.change?.toStringAsFixed(2) ?? '0'}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: (point.change ?? 0) >= 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// Gold History Point model
class GoldHistoryPoint {
  final String date;
  final double price;
  final double? change;
  GoldHistoryPoint({required this.date, required this.price, this.change});
  factory GoldHistoryPoint.fromJson(Map<String, dynamic> json) => GoldHistoryPoint(
        date: (json['date'] as String?)?.substring(0, 10) ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        change: (json['change'] as num?)?.toDouble(),
      );
}

// Simple line chart painter
class _SimpleLineChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SimpleLineChartPainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final padding = 10.0;

    final points = <Offset>[];
    for (int i = 0; i < prices.length; i++) {
      final x = padding + (i / (prices.length - 1).clamp(1, prices.length)) * (size.width - padding * 2);
      final y = size.height - padding - ((prices[i] - min) / range) * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    // Draw fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Draw dots for first and last
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(points.first, 4, dotPaint);
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
