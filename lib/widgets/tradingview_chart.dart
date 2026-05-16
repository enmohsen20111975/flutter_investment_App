import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';

enum ChartType { candle, line, area }

enum ChartInterval {
  oneDay('1D', 1),
  oneWeek('1W', 7),
  oneMonth('1M', 30),
  threeMonths('3M', 90),
  sixMonths('6M', 180),
  oneYear('1Y', 365),
  all('ALL', 0);

  final String label;
  final int days;
  const ChartInterval(this.label, this.days);
}

class TradingViewChart extends StatefulWidget {
  final ChartType chartType;
  final ChartInterval interval;
  final List<Map<String, dynamic>>? candleData;
  final List<Map<String, dynamic>>? volumeData;
  final List<Map<String, dynamic>>? smaData;
  final Color? upColor;
  final Color? downColor;
  final bool darkTheme;
  final VoidCallback? onChartReady;

  const TradingViewChart({
    super.key,
    this.chartType = ChartType.candle,
    this.interval = ChartInterval.oneMonth,
    this.candleData,
    this.volumeData,
    this.smaData,
    this.upColor,
    this.downColor,
    this.darkTheme = false,
    this.onChartReady,
  });

  @override
  State<TradingViewChart> createState() => TradingViewChartState();
}

class TradingViewChartState extends State<TradingViewChart> {
  WebViewController? _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.darkTheme ? const Color(0xFF1A1D26) : Colors.white)
      ..loadFlutterAsset('assets/charts/tradingview.html')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _isReady = true;
            _sendCurrentState();
            widget.onChartReady?.call();
          },
        ),
      );
  }

  void _sendCurrentState() {
    if (!_isReady) return;
    updateChartType(widget.chartType);
    if (widget.candleData != null) {
      setData(widget.candleData!, widget.volumeData);
    }
    if (widget.smaData != null) {
      addSMA(widget.smaData!);
    }
  }

  void updateChartType(ChartType type) {
    _postMessage({'type': 'setChartType', 'chartType': type.name});
  }

  void updateInterval(ChartInterval interval) {
    _postMessage({'type': 'setInterval', 'interval': interval.label, 'days': interval.days});
  }

  void setData(List<Map<String, dynamic>> candles, [List<Map<String, dynamic>>? volumes]) {
    _postMessage({'type': 'setData', 'candles': candles, 'volumes': volumes ?? []});
  }

  void addSMA(List<Map<String, dynamic>> data, [String color = '#2962FF']) {
    _postMessage({'type': 'addSMA', 'data': data, 'color': color});
  }

  void fitContent() {
    _postMessage({'type': 'fitContent'});
  }

  void setTheme(bool dark) {
    _postMessage({'type': 'setTheme', 'dark': dark});
  }

  void _postMessage(Map<String, dynamic> msg) {
    if (!_isReady || _controller == null) return;
    final json = jsonEncode(msg);
    _controller!.runJavaScript("window.postMessage($json, '*')");
    if (kDebugMode) {
      debugPrint('[TradingView] postMessage: ${msg['type']}');
    }
  }

  @override
  void didUpdateWidget(covariant TradingViewChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartType != widget.chartType) {
      updateChartType(widget.chartType);
    }
    if (oldWidget.candleData != widget.candleData && widget.candleData != null) {
      setData(widget.candleData!, widget.volumeData);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: widget.darkTheme ? const Color(0xFF1A1D26) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: WebViewWidget(controller: _controller!),
    );
  }
}

class TradingViewChartWithControls extends StatefulWidget {
  final List<Map<String, dynamic>>? candleData;
  final List<Map<String, dynamic>>? volumeData;
  final List<Map<String, dynamic>>? smaData;
  final bool darkTheme;
  final ValueChanged<ChartInterval>? onIntervalChanged;
  final ValueChanged<ChartType>? onChartTypeChanged;
  final Future<void> Function(ChartInterval interval)? onReloadData;

  const TradingViewChartWithControls({
    super.key,
    this.candleData,
    this.volumeData,
    this.smaData,
    this.darkTheme = false,
    this.onIntervalChanged,
    this.onChartTypeChanged,
    this.onReloadData,
  });

  @override
  State<TradingViewChartWithControls> createState() => _TradingViewChartWithControlsState();
}

class _TradingViewChartWithControlsState extends State<TradingViewChartWithControls> {
  ChartType _chartType = ChartType.candle;
  ChartInterval _interval = ChartInterval.oneMonth;
  final GlobalKey<TradingViewChartState> _chartKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControls(),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: TradingViewChart(
            key: _chartKey,
            chartType: _chartType,
            interval: _interval,
            candleData: widget.candleData,
            volumeData: widget.volumeData,
            smaData: widget.smaData,
            darkTheme: widget.darkTheme,
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartType.values.map((type) {
                final selected = _chartType == type;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FilterChip(
                    selected: selected,
                    label: Text(
                      _chartTypeLabel(type),
                      style: TextStyle(fontSize: 11, color: selected ? AppColors.white : AppColors.textSecondary),
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                    onSelected: (_) {
                      setState(() => _chartType = type);
                      _chartKey.currentState?.updateChartType(type);
                      widget.onChartTypeChanged?.call(type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _chartTypeLabel(ChartType type) {
    switch (type) {
      case ChartType.candle:
        return 'شموع';
      case ChartType.line:
        return 'خط';
      case ChartType.area:
        return 'مساحة';
    }
  }
}
