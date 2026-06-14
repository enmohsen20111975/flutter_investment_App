// ============================================================================
// مساعد الاستثمار Flutter - Metals Screen (Gold & Silver)
// Shows real-time gold/silver prices, historical charts, and gold weight calculator.
// Uses: GET /api/metals/gold, GET /api/metals/gold/history
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class MetalsScreen extends StatefulWidget {
  const MetalsScreen({super.key});

  @override
  State<MetalsScreen> createState() => _MetalsScreenState();
}

class _MetalsScreenState extends State<MetalsScreen> {
  Future<GoldResponse?>? _goldPricesFuture;
  Future<List<GoldHistoryPoint>>? _historyFuture;

  String _selectedKarat = '24';
  int _selectedDays = 30;

  // Calculator controller
  final _weightCtrl = TextEditingController();
  String _calcKarat = '24';
  double _calcResult = 0;

  @override
  void initState() {
    super.initState();
    _goldPricesFuture = _fetchGoldPrices();
    _historyFuture = _fetchGoldHistory();
  }

  Future<GoldResponse?> _fetchGoldPrices() async {
    try {
      final data = await api.getGold();
      return GoldResponse.fromJson(data);
    } catch (e) {
      debugPrint('[Metals] Error fetching prices: $e');
      return null;
    }
  }

  Future<List<GoldHistoryPoint>> _fetchGoldHistory() async {
    try {
      final list =
          await api.getGoldHistory(karat: _selectedKarat, days: _selectedDays);
      return list
          .map((e) => GoldHistoryPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Metals] Error fetching history: $e');
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _goldPricesFuture = _fetchGoldPrices();
      _historyFuture = _fetchGoldHistory();
      _weightCtrl.clear();
      _calcResult = 0;
    });
  }

  void _calculateGoldValue(List<GoldPrice> karats, double silverPrice) {
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    if (weight <= 0) {
      setState(() => _calcResult = 0);
      return;
    }

    double pricePerGram = 0;
    if (_calcKarat == 'silver') {
      pricePerGram = silverPrice;
    } else {
      final kp = karats.firstWhere((k) => k.key == _calcKarat,
          orElse: () => GoldPrice(key: '', nameAr: '', pricePerGram: 0));
      pricePerGram = kp.pricePerGram;
    }

    setState(() {
      _calcResult = weight * pricePerGram;
    });
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('الذهب والمعادن',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<GoldResponse?>(
          future: _goldPricesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return StateView(
                error: snapshot.hasError
                    ? snapshot.error.toString()
                    : 'حدث خطأ أثناء تحميل بيانات الذهب',
                onRetry: _refresh,
              );
            }

            final goldData = snapshot.data!;
            final prices = goldData.prices;
            final karats = prices?.karats ?? [];
            final silver = prices?.silver;
            final ounce = prices?.ounce;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeaderCard(
                      icon: Icons.diamond_outlined,
                      title: 'الذهب والمعادن الثمينة',
                      subtitle:
                          'أسعار المعادن الثمينة والعيارات المختلفة لحظة بلحظة',
                      gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                    ),
                    const SizedBox(height: 16),

                    // Ounce and Silver Header Cards
                    Row(
                      children: [
                        if (ounce != null)
                          Expanded(
                            child: _buildOunceCard(ounce),
                          ),
                        if (silver != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSilverCard(silver),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Karats Grid
                    if (karats.isNotEmpty) ...[
                      const SectionHeader(
                          title: 'عيارات الذهب (سعر الجرام)',
                          icon: Icons.grid_view),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: karats.length,
                        itemBuilder: (context, index) {
                          return _buildKaratCard(karats[index]);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Chart Section
                    const SectionHeader(
                        title: 'المخطط التاريخي للأسعار',
                        icon: Icons.show_chart),
                    const SizedBox(height: 8),
                    _buildChartSection(karats),
                    const SizedBox(height: 20),

                    // Weight Calculator
                    const SectionHeader(
                        title: 'حاسبة قيمة المعادن',
                        icon: Icons.calculate_outlined),
                    const SizedBox(height: 8),
                    _buildCalculatorSection(karats, silver?.pricePerGram ?? 0),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOunceCard(GoldOunce ounce) {
    final isUp = (ounce.change ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGold,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أوقية الذهب',
                  style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Icon(Icons.stars, color: AppColors.textDark, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${ounce.price.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isUp ? Colors.green[800] : Colors.red[800], size: 14),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${ounce.change?.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUp ? Colors.green[800] : Colors.red[800]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSilverCard(SilverPrice silver) {
    final isUp = (silver.change ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('جرام الفضة',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              Icon(Icons.circle, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${silver.pricePerGram.toStringAsFixed(1)} ج.م',
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.trending_up : Icons.trending_down,
                  color: isUp ? AppColors.success : AppColors.danger, size: 14),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${silver.change?.toStringAsFixed(1)} ج.م',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isUp ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKaratCard(GoldPrice karat) {
    final isUp = (karat.change ?? 0) >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(karat.nameAr,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            '${karat.pricePerGram.toStringAsFixed(0)} ج.م',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isUp ? AppColors.success : AppColors.danger, size: 12),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${karat.change?.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUp ? AppColors.success : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<GoldPrice> karats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Selectors Row
          Row(
            children: [
              // Karat Selector Dropdown
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppColors.surfaceMuted,
                      value: _selectedKarat,
                      items: karats
                          .map((k) => DropdownMenuItem(
                                value: k.key,
                                child: Text(k.nameAr,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.text)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedKarat = val;
                            _historyFuture = _fetchGoldHistory();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Timeframe selectors
              ...[7, 30, 90].map((days) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ChoiceChip(
                      label: Text('$days يوم',
                          style: const TextStyle(fontSize: 11)),
                      selected: _selectedDays == days,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceMuted,
                      labelStyle: TextStyle(
                          color: _selectedDays == days
                              ? AppColors.white
                              : AppColors.textSecondary),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedDays = days;
                            _historyFuture = _fetchGoldHistory();
                          });
                        }
                      },
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 20),

          // FutureBuilder for History Chart
          SizedBox(
            height: 200,
            child: FutureBuilder<List<GoldHistoryPoint>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                final points = snapshot.data ?? [];
                if (points.isEmpty) {
                  return const Center(
                      child: Text('لا توجد بيانات رسم بياني متاحة',
                          style: TextStyle(color: AppColors.textMuted)));
                }

                final prices = points.map((e) => e.price).toList();
                final maxPrice = prices.reduce((a, b) => a > b ? a : b);
                final minPrice = prices.reduce((a, b) => a < b ? a : b);
                final isUp = prices.last >= prices.first;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('أعلى: ${maxPrice.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.success)),
                        Text('أدنى: ${minPrice.toStringAsFixed(0)} ج.م',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.danger)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _GoldChartPainter(
                            prices: prices,
                            color: isUp ? AppColors.success : AppColors.danger),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorSection(List<GoldPrice> karats, double silverPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Weight TextField
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'الوزن (بالجرام)',
                    hintText: 'مثال: 10',
                    prefixIcon: Icon(Icons.line_weight_outlined),
                  ),
                  onChanged: (_) => _calculateGoldValue(karats, silverPrice),
                ),
              ),
              const SizedBox(width: 10),
              // Karat Selector Dropdown
              Expanded(
                flex: 1,
                child: Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppColors.surfaceMuted,
                      value: _calcKarat,
                      items: [
                        ...karats.map((k) => DropdownMenuItem(
                            value: k.key,
                            child: Text(k.nameAr,
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.text)))),
                        const DropdownMenuItem(
                            value: 'silver',
                            child: Text('فضة جرام',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.text))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _calcKarat = val;
                          });
                          _calculateGoldValue(karats, silverPrice);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calculation Result
          if (_calcResult > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.gradientGold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('القيمة التقريبية المعادلة',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 6),
                  Text(
                    '${_calcResult.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Line chart painter for gold history
class _GoldChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _GoldChartPainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    const padding = 8.0;

    final points = <Offset>[];
    for (int i = 0; i < prices.length; i++) {
      final x = padding +
          (i / (prices.length - 1).clamp(1, prices.length)) *
              (size.width - padding * 2);
      final y = size.height -
          padding -
          ((prices[i] - min) / range) * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.first, 4.5, dotPaint);
    canvas.drawCircle(points.last, 4.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
