import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// StockSparkline — رسم بياني مصغر لسهم (آخر 30 يوم)
/// يتصل بـ /api/stocks/sparkline?ticker=X&days=30
class StockSparkline extends StatefulWidget {
  final String ticker;
  final double height;
  final double width;
  final int days;

  const StockSparkline({
    super.key,
    required this.ticker,
    this.height = 32,
    this.width = 100,
    this.days = 30,
  });

  @override
  State<StockSparkline> createState() => _StockSparklineState();
}

class _StockSparklineState extends State<StockSparkline> {
  List<double> _prices = [];
  bool _loading = true;
  double _changePct = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'https://invist.m2y.net',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final res = await dio.get('/api/stocks/sparkline', queryParameters: {
        'ticker': widget.ticker,
        'days': widget.days,
      });
      if (res.statusCode == 200 && res.data['prices'] != null) {
        final prices = (res.data['prices'] as List).cast<double>();
        if (prices.isNotEmpty && prices.length > 1) {
          final first = prices.first;
          final last = prices.last;
          setState(() {
            _prices = prices;
            _changePct = first > 0 ? ((last - first) / first) * 100 : 0;
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: widget.height,
        width: widget.width,
        child: const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1))),
      );
    }

    if (_prices.length < 2) {
      return SizedBox(height: widget.height, width: widget.width);
    }

    final isUp = _changePct >= 0;
    final color = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CustomPaint(
        painter: _SparklinePainter(_prices, color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _SparklinePainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() || 1.0;
    final w = size.width;
    final h = size.height;

    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * w;
      final y = h - ((prices[i] - min) / range) * h;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.25), color.withOpacity(0)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, gradient);

    // Line
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
