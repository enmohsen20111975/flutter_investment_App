// ============================================================================
// مساعد الاستثمار Flutter - TradingView Chart Widget
// Uses WebView + lightweight-charts for professional financial charts
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';

class TradingViewChart extends StatefulWidget {
  final String ticker;
  final String? stockName;
  final double height;

  const TradingViewChart({super.key, required this.ticker, this.stockName, this.height = 400});

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            setState(() { _isLoading = false; _hasError = true; });
          },
        ),
      )
      ..loadFlutterAsset('assets/charts/tradingview.html');
  }

  /// Send candlestick data to the chart
  void setCandleData(List<Map<String, dynamic>> candles) {
    final volumes = candles.map((c) => {
      'time': c['time'],
      'value': c['volume'] ?? 0,
      'color': (c['close'] ?? 0) >= (c['open'] ?? 0) ? 'rgba(34, 197, 94, 0.5)' : 'rgba(239, 68, 68, 0.5)',
    }).toList();

    _controller.runJavaScript('setData(${jsonEncode(candles)}, ${jsonEncode(volumes)})');
  }

  /// Add SMA line
  void addSMA(List<Map<String, dynamic>> data, [String color = '#2962FF']) {
    _controller.runJavaScript('addSMA(${jsonEncode(data)}, "$color")');
  }

  /// Fit chart content
  void fitContent() {
    _controller.runJavaScript('fitContent()');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.show_chart, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text('لا يمكن تحميل الرسم البياني', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
