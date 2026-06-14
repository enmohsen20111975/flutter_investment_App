// ============================================================================
// مساعد الاستثمار Flutter - Crypto Detail Screen
// Shows crypto detail with OHLC chart, indicators, and signals
// Uses: GET /api/crypto/:id, GET /api/crypto/ohlc
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/json_helpers.dart';
import '../widgets/state_view.dart';

class CryptoDetailScreen extends StatefulWidget {
  final String coinId;
  final String coinName;
  const CryptoDetailScreen(
      {super.key, required this.coinId, required this.coinName});

  @override
  State<CryptoDetailScreen> createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  Future<CryptoDetailData?>? _dataFuture;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<CryptoDetailData?> _fetchData() async {
    try {
      final results = await Future.wait([
        api.getCryptoDetail(widget.coinId),
        api.getCryptoOHLC(coinId: widget.coinId, days: _selectedDays),
      ]);

      final detail = results[0] as Map<String, dynamic>;
      final ohlcResponse = results[1] as Map<String, dynamic>;

      final ohlcv = (ohlcResponse['ohlcv'] as List?) ?? [];
      final ohlcData = ohlcv.map((e) => CryptoOHLCPoint.fromJson(e)).toList();

      return CryptoDetailData(
        detail: detail,
        ohlcData: ohlcData,
        indicators: ohlcResponse['indicators'] as Map<String, dynamic>?,
        signals: ohlcResponse['signals'] as Map<String, dynamic>?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchData();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          title: Text(widget.coinName),
        ),
        body: FutureBuilder<CryptoDetailData?>(
          future: _dataFuture,
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
                    : 'لا توجد بيانات متاحة',
                onRetry: _refresh,
              );
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceHeader(data),
                    const SizedBox(height: 16),
                    _buildTimeSelector(),
                    const SizedBox(height: 12),
                    if (data.ohlcData.isEmpty)
                      const StateView(
                          empty: true,
                          emptyMessage: 'لا يوجد بيانات رسم بياني متاحة')
                    else
                      _buildChart(data.ohlcData),
                    const SizedBox(height: 16),
                    if (data.indicators != null) ...[
                      const SectionHeader(
                          title: 'المؤشرات الفنية', icon: Icons.analytics),
                      const SizedBox(height: 8),
                      _buildIndicators(data.indicators!),
                      const SizedBox(height: 16),
                    ],
                    if (data.signals != null) ...[
                      const SectionHeader(
                          title: 'الإشارات', icon: Icons.lightbulb_outline),
                      const SizedBox(height: 8),
                      _buildSignals(data.signals!),
                      const SizedBox(height: 16),
                    ],
                    if (data.detail != null) ...[
                      const SectionHeader(
                          title: 'بيانات السوق', icon: Icons.bar_chart),
                      const SizedBox(height: 8),
                      _buildMarketData(data.detail!),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceHeader(CryptoDetailData data) {
    final currentPrice = parseDouble(data.indicators?['currentPrice'] ??
            data.detail?['current_price']) ??
        0;
    final change24h = parseDouble(data.indicators?['priceChange24h'] ??
            data.detail?['price_change_percentage_24h']) ??
        0;
    final changePercent = parseDouble(
            data.indicators?['priceChangePercent24h'] ??
                data.detail?['price_change_percentage_24h']) ??
        0;
    final isPositive = change24h >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          isPositive ? AppColors.success : AppColors.danger,
          isPositive
              ? AppColors.success.withValues(alpha: 0.8)
              : AppColors.danger.withValues(alpha: 0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('\$${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                  color: AppColors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)} (${changePercent.toStringAsFixed(2)}%)',
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          {'label': '7 أيام', 'days': 7},
          {'label': '30 يوم', 'days': 30},
          {'label': '90 يوم', 'days': 90},
        ]
            .map((period) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    selected: _selectedDays == period['days'],
                    label: Text(period['label'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: _selectedDays == period['days']
                                ? AppColors.white
                                : AppColors.textSecondary)),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                        color: _selectedDays == period['days']
                            ? AppColors.primary
                            : AppColors.border),
                    onSelected: (_) {
                      setState(() => _selectedDays = period['days'] as int);
                      _refresh();
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildChart(List<CryptoOHLCPoint> ohlcData) {
    final closes = ohlcData.map((p) => p.close).toList();
    final maxPrice = closes.reduce((a, b) => a > b ? a : b);
    final minPrice = closes.reduce((a, b) => a < b ? a : b);
    final isUp = closes.last >= closes.first;
    final chartColor = isUp ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('أعلى: \$${maxPrice.toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.success)),
              Text('أدنى: \$${minPrice.toStringAsFixed(2)}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter:
                  _CryptoLineChartPainter(prices: closes, color: chartColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicators(Map<String, dynamic> ind) {
    final widgets = <Widget>[];

    final rsi = (ind['rsi'] as num?)?.toDouble();
    if (rsi != null) {
      widgets.add(_buildIndicatorCard(
          'RSI',
          rsi.toStringAsFixed(1),
          rsi > 70
              ? 'ذروة شراء'
              : rsi < 30
                  ? 'ذروة بيع'
                  : 'محايد',
          rsi > 70
              ? AppColors.danger
              : rsi < 30
                  ? AppColors.success
                  : AppColors.info));
    }

    final sma = ind['sma'] as Map<String, dynamic>?;
    if (sma != null) {
      final sma20 = (sma['sma20'] as num?)?.toDouble();
      final sma50 = (sma['sma50'] as num?)?.toDouble();
      if (sma20 != null) {
        widgets.add(_buildIndicatorCard('SMA 20',
            '\$${sma20.toStringAsFixed(2)}', 'متوسط 20 يوم', AppColors.info));
      }
      if (sma50 != null) {
        widgets.add(_buildIndicatorCard('SMA 50',
            '\$${sma50.toStringAsFixed(2)}', 'متوسط 50 يوم', AppColors.info));
      }
    }

    final macd = ind['macd'] as Map<String, dynamic>?;
    if (macd != null) {
      final macdVal = (macd['macd'] as num?)?.toDouble();
      final signal = (macd['signal'] as num?)?.toDouble();
      if (macdVal != null && signal != null) {
        widgets.add(_buildIndicatorCard(
            'MACD',
            macdVal.toStringAsFixed(2),
            macdVal > signal ? 'صاعد ↑' : 'هابط ↓',
            macdVal > signal ? AppColors.success : AppColors.danger));
      }
    }

    final bb = ind['bollingerBands'] as Map<String, dynamic>?;
    if (bb != null) {
      final upper = (bb['upper'] as num?)?.toDouble();
      final lower = (bb['lower'] as num?)?.toDouble();
      if (upper != null && lower != null) {
        widgets.add(_buildIndicatorCard(
            'بولينجر',
            '${lower.toStringAsFixed(0)} - ${upper.toStringAsFixed(0)}',
            'النطاق',
            AppColors.warning));
      }
    }

    final sr = ind['supportResistance'] as Map<String, dynamic>?;
    if (sr != null) {
      final resistance = (sr['resistance'] as num?)?.toDouble();
      final support = (sr['support'] as num?)?.toDouble();
      if (resistance != null) {
        widgets.add(_buildIndicatorCard('مقاومة',
            '\$${resistance.toStringAsFixed(2)}', '', AppColors.danger));
      }
      if (support != null) {
        widgets.add(_buildIndicatorCard(
            'دعم', '\$${support.toStringAsFixed(2)}', '', AppColors.success));
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widgets,
    );
  }

  Widget _buildIndicatorCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
          if (subtitle.isNotEmpty)
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSignals(Map<String, dynamic> sig) {
    final overall = sig['overall'] as Map<String, dynamic>?;
    final signalsList = (sig['signals'] as List?) ?? [];

    return Column(
      children: [
        if (overall != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getActionColor(overall['recommendation'] ?? ''),
                _getActionColor(overall['recommendation'] ?? '')
                    .withValues(alpha: 0.8),
              ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التوصية',
                        style: TextStyle(fontSize: 12, color: AppColors.white)),
                    Text(
                      _getActionAr(overall['recommendation'] ?? ''),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ثقة: ${parseInt(overall['confidence']) ?? 0}%',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('شراء: ${parseInt(overall['buySignals']) ?? 0}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.white)),
                        const SizedBox(width: 8),
                        Text('بيع: ${parseInt(overall['sellSignals']) ?? 0}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...signalsList.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(_getActionIcon(s['type'] ?? ''),
                      color: _getActionColor(s['type'] ?? ''), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['reason'] ?? '',
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text('قوة: ${s['strength'] ?? '-'}',
                            style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildMarketData(Map<String, dynamic> d) {
    final items = <MapEntry<String, String>>[];

    if (marketCap != null) {
      items.add(MapEntry('القيمة السوقية', '\$${_formatLargeNumber(marketCap)}'));
    }
    final volume = (d['total_volume'] as num?)?.toDouble();
    if (volume != null) {
      items.add(MapEntry('حجم التداول', '\$${_formatLargeNumber(volume)}'));
    }
    final rank = (d['market_cap_rank'] as num?)?.toInt();
    if (rank != null) {
      items.add(MapEntry('الترتيب', '#$rank'));
    }
    final high24 = (d['high_24h'] as num?)?.toDouble();
    if (high24 != null) {
      items.add(MapEntry('أعلى 24 ساعة', '\$${high24.toStringAsFixed(2)}'));
    }
    final low24 = (d['low_24h'] as num?)?.toDouble();
    if (low24 != null) {
      items.add(MapEntry('أدنى 24 ساعة', '\$${low24.toStringAsFixed(2)}'));
    }
    final change7d =
        (d['price_change_percentage_7d_in_currency'] as num?)?.toDouble();
    if (change7d != null) {
      items.add(MapEntry('تغير 7 أيام', '${change7d.toStringAsFixed(2)}%'));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: AppTypography.bodyMedium),
                      Text(e.value, style: AppTypography.titleSmall),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _formatLargeNumber(double value) {
    if (value >= 1e12) return '${(value / 1e12).toStringAsFixed(2)}T';
    if (value >= 1e9) return '${(value / 1e9).toStringAsFixed(2)}B';
    if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(2)}M';
    if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(2)}K';
    return value.toStringAsFixed(2);
  }

  Color _getActionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('buy')) return AppColors.success;
    if (a.contains('sell')) return AppColors.danger;
    if (a.contains('hold') || a.contains('neutral')) return AppColors.warning;
    return AppColors.info;
  }

  IconData _getActionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('buy')) return Icons.trending_up;
    if (a.contains('sell')) return Icons.trending_down;
    return Icons.remove;
  }

  String _getActionAr(String action) {
    final a = action.toLowerCase();
    if (a.contains('strong_buy')) return 'شراء قوي';
    if (a.contains('buy')) return 'شراء';
    if (a.contains('strong_sell')) return 'بيع قوي';
    if (a.contains('sell')) return 'بيع';
    if (a.contains('hold')) return 'احتفاظ';
    return action;
  }
}

class CryptoDetailData {
  final Map<String, dynamic>? detail;
  final List<CryptoOHLCPoint> ohlcData;
  final Map<String, dynamic>? indicators;
  final Map<String, dynamic>? signals;

  CryptoDetailData(
      {this.detail, required this.ohlcData, this.indicators, this.signals});
}

class CryptoOHLCPoint {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  CryptoOHLCPoint(
      {required this.timestamp,
      required this.open,
      required this.high,
      required this.low,
      required this.close});

  factory CryptoOHLCPoint.fromJson(Map<String, dynamic> json) =>
      CryptoOHLCPoint(
        timestamp: parseInt(json['timestamp']) ?? 0,
        open: parseDouble(json['open']) ?? 0,
        high: parseDouble(json['high']) ?? 0,
        low: parseDouble(json['low']) ?? 0,
        close: parseDouble(json['close']) ?? 0,
      );
}

class _CryptoLineChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _CryptoLineChartPainter({required this.prices, required this.color});

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
    const padding = 10.0;

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
    canvas.drawCircle(points.first, 4, dotPaint);
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
