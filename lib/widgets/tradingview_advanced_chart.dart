// ============================================================================
// مساعد الاستثمار Flutter - TradingView Advanced Real-Time Chart
// الشارت المتقدم الرسمي لـ TradingView مع شريط الأدوات الكامل والمؤشرات باللغة العربية
// ============================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/colors.dart';

class TradingViewAdvancedChart extends StatefulWidget {
  final String ticker;
  final String? market;
  final String? customSymbol;
  final double? height;
  final bool darkTheme;
  final String initialInterval;
  final bool showHeader;
  final bool showTimeframes;
  final bool allowFullscreen;
  final VoidCallback? onToggleFullscreen;

  const TradingViewAdvancedChart({
    super.key,
    required this.ticker,
    this.market,
    this.customSymbol,
    this.height = 440,
    this.darkTheme = true,
    this.initialInterval = 'D',
    this.showHeader = true,
    this.showTimeframes = true,
    this.allowFullscreen = true,
    this.onToggleFullscreen,
  });

  /// تحويل رمز السهم إلى الصيغة الرسمية لـ TradingView
  static String resolveSymbol(String rawTicker, {String? market}) {
    final clean = rawTicker.trim().toUpperCase();
    if (clean.contains(':')) return clean;

    final m = (market ?? 'EGX').toUpperCase();
    if (m == 'EGX') {
      if (clean == 'EGX30' || clean == 'EGX 30') return 'EGX:EGX30';
      if (clean == 'EGX70' || clean == 'EGX 70') return 'EGX:EGX70';
      if (clean == 'EGX100' || clean == 'EGX 100') return 'EGX:EGX100';
      return 'EGX:$clean';
    } else if (m == 'TADAWUL' || RegExp(r'^\d{4}$').hasMatch(clean)) {
      return 'TADAWUL:$clean';
    } else if (m == 'CRYPTO' || clean == 'BTC' || clean == 'ETH' || clean.endsWith('USDT')) {
      if (clean.endsWith('USDT')) return 'BINANCE:$clean';
      return 'BINANCE:${clean}USDT';
    } else if (m == 'US') {
      return 'NASDAQ:$clean';
    } else if (clean == 'GOLD' || clean == 'XAUUSD') {
      return 'OANDA:XAUUSD';
    } else if (clean == 'USDEGP') {
      return 'FX_IDC:USDEGP';
    }
    return 'EGX:$clean';
  }

  /// التوقيت الزمني المناسب لكل سوق
  static String resolveTimezone(String? market) {
    final m = (market ?? 'EGX').toUpperCase();
    if (m == 'EGX') return 'Africa/Cairo';
    if (m == 'TADAWUL' || m == 'KSE' || m == 'QSE' || m == 'DFM') return 'Asia/Riyadh';
    if (m == 'US') return 'America/New_York';
    if (m == 'CRYPTO') return 'Etc/UTC';
    return 'Africa/Cairo';
  }

  @override
  State<TradingViewAdvancedChart> createState() => _TradingViewAdvancedChartState();
}

class _TradingViewAdvancedChartState extends State<TradingViewAdvancedChart> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  late String _currentInterval;
  late String _resolvedSymbol;

  static const List<Map<String, String>> _timeframeOptions = [
    {'label': '1 د', 'interval': '1'},
    {'label': '5 د', 'interval': '5'},
    {'label': '15 د', 'interval': '15'},
    {'label': '30 د', 'interval': '30'},
    {'label': '1 س', 'interval': '60'},
    {'label': '4 س', 'interval': '240'},
    {'label': 'يومي', 'interval': 'D'},
    {'label': 'أسبوعي', 'interval': 'W'},
  ];

  @override
  void initState() {
    super.initState();
    _currentInterval = widget.initialInterval;
    _resolvedSymbol = widget.customSymbol ??
        TradingViewAdvancedChart.resolveSymbol(widget.ticker, market: widget.market);
    _initController();
  }

  @override
  void didUpdateWidget(covariant TradingViewAdvancedChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSymbol = widget.customSymbol ??
        TradingViewAdvancedChart.resolveSymbol(widget.ticker, market: widget.market);
    if (newSymbol != _resolvedSymbol || oldWidget.darkTheme != widget.darkTheme) {
      _resolvedSymbol = newSymbol;
      _reloadChart();
    }
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.darkTheme ? const Color(0xFF0F172A) : Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (err) {
            // Only flag critical loading errors
            if (err.isForMainFrame ?? false) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      );

    _loadChartContent();
  }

  void _loadChartContent() {
    final theme = widget.darkTheme ? 'dark' : 'light';
    final timezone = TradingViewAdvancedChart.resolveTimezone(widget.market);
    final html = _generateHtml(
      symbol: _resolvedSymbol,
      theme: theme,
      interval: _currentInterval,
      timezone: timezone,
    );

    _controller.loadHtmlString(html, baseUrl: 'https://www.tradingview.com');
  }

  void _reloadChart() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _loadChartContent();
  }

  void _changeInterval(String interval) {
    if (interval == _currentInterval) return;
    setState(() {
      _currentInterval = interval;
    });
    _reloadChart();
  }

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: widget.darkTheme ? const Color(0xFF0F172A) : Colors.white,
          appBar: AppBar(
            backgroundColor: widget.darkTheme ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            title: Text(
              'شارت TradingView — $_resolvedSymbol',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _reloadChart,
                tooltip: 'تحديث الشارت',
              ),
            ],
          ),
          body: TradingViewAdvancedChart(
            ticker: widget.ticker,
            market: widget.market,
            customSymbol: _resolvedSymbol,
            darkTheme: widget.darkTheme,
            initialInterval: _currentInterval,
            allowFullscreen: false,
            showHeader: false,
            showTimeframes: true,
            height: null,
          ),
        ),
      ),
    );
  }

  String _generateHtml({
    required String symbol,
    required String theme,
    required String interval,
    required String timezone,
  }) {
    final bgColor = theme == 'dark' ? '#0f172a' : '#ffffff';
    final toolbarBg = theme == 'dark' ? '#131722' : '#f8fafc';

    return '''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>TradingView Chart</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background-color: $bgColor;
    }
    #tv_chart_container {
      width: 100%;
      height: 100%;
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
    }
  </style>
</head>
<body>
  <div id="tv_chart_container"></div>
  <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
  <script type="text/javascript">
    function initChart() {
      if (typeof TradingView === 'undefined') {
        setTimeout(initChart, 100);
        return;
      }
      try {
        new TradingView.widget({
          "autosize": true,
          "symbol": "$symbol",
          "interval": "$interval",
          "timezone": "$timezone",
          "theme": "$theme",
          "style": "1",
          "locale": "ar",
          "toolbar_bg": "$toolbarBg",
          "enable_publishing": false,
          "withdateranges": true,
          "hide_side_toolbar": false,
          "allow_symbol_change": true,
          "save_image": false,
          "container_id": "tv_chart_container",
          "hide_volume": false
        });
      } catch (err) {
        console.error('TradingView init error:', err);
      }
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initChart);
    } else {
      initChart();
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Container(
            color: widget.darkTheme ? const Color(0xFF0F172A) : Colors.white,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'تحميل شارت TradingView الأصلي ($_resolvedSymbol)...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (_hasError)
          Container(
            color: widget.darkTheme ? const Color(0xFF0F172A) : Colors.white,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 36),
                const SizedBox(height: 8),
                const Text(
                  'تعذر تحميل بيانات TradingView المباشرة',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _reloadChart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
      ],
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: widget.darkTheme ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (widget.showHeader) _buildTopHeader(),
            if (widget.showTimeframes) _buildTimeframeBar(),
            widget.height != null
                ? SizedBox(height: widget.height, child: content)
                : Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.darkTheme ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'TradingView Live',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _resolvedSymbol,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: _reloadChart,
            tooltip: 'تحديث',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          if (widget.allowFullscreen)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded, size: 20),
              onPressed: () {
                if (widget.onToggleFullscreen != null) {
                  widget.onToggleFullscreen!();
                } else {
                  _openFullscreen(context);
                }
              },
              tooltip: 'شاشة كاملة',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: widget.darkTheme ? const Color(0xFF131722) : const Color(0xFFF8FAFC),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _timeframeOptions.map((opt) {
          final isSelected = opt['interval'] == _currentInterval;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => _changeInterval(opt['interval']!),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (widget.darkTheme ? Colors.white10 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
