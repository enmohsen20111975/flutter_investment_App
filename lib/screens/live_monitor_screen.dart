// ============================================================================
// مساعد الاستثمار Flutter - Live Monitor Screen
// Real-time-ish price ticker with auto-refresh and animated changes
// API: /api/market/live-data?market=EGX
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen>
    with TickerProviderStateMixin {
  String _selectedMarket = 'EGX';
  final List<String> _markets = const ['EGX', 'TADAWUL', 'KSE', 'QSE', 'DFM'];

  List<_LiveQuote> _quotes = [];
  Map<String, double> _previousPrices = {};
  bool _loading = true;
  String? _error;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  bool _autoRefresh = true;
  String _filter = 'all'; // all | gainers | losers

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _bootstrap();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final m = prefs.getString('active_market') ?? 'EGX';
    if (mounted) {
      setState(() {
        _selectedMarket = _markets.contains(m) ? m : 'EGX';
      });
    }
    await _fetchQuotes();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    if (!_autoRefresh) return;
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchQuotes();
    });
  }

  Future<void> _fetchQuotes() async {
    try {
      final data = await api.getMarketLiveQuotes(market: _selectedMarket);
      final raw = data['quotes'] ??
          data['stocks'] ??
          data['data'] ??
          data['items'] ??
          (data['market_data'] is Map
              ? data['market_data']['stocks']
              : null);
      final newQuotes = <_LiveQuote>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            newQuotes.add(_LiveQuote.fromMap(Map<String, dynamic>.from(e)));
          }
        }
      }
      // Cache previous prices for animation
      final newPrev = <String, double>{};
      for (final q in newQuotes) {
        if (q.currentPrice != null) {
          newPrev[q.ticker] = q.currentPrice!;
        }
      }
      if (mounted) {
        setState(() {
          _previousPrices = {
            for (final q in _quotes) if (q.currentPrice != null) q.ticker: q.currentPrice!,
          };
          _quotes = newQuotes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'تعذر تحميل الأسعار اللحظية';
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _fetchQuotes();
  }

  Future<void> _changeMarket(String market) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_market', market);
    setState(() {
      _selectedMarket = market;
      _loading = true;
      _quotes = [];
      _previousPrices = {};
    });
    await _fetchQuotes();
    _startPolling();
  }

  void _toggleAutoRefresh() {
    setState(() => _autoRefresh = !_autoRefresh);
    if (_autoRefresh) {
      _startPolling();
    } else {
      _timer?.cancel();
    }
  }

  List<_LiveQuote> get _filteredQuotes {
    switch (_filter) {
      case 'gainers':
        return _quotes.where((q) => (q.changePercent ?? 0) > 0).toList()
          ..sort((a, b) =>
              (b.changePercent ?? 0).compareTo(a.changePercent ?? 0));
      case 'losers':
        return _quotes.where((q) => (q.changePercent ?? 0) < 0).toList()
          ..sort((a, b) =>
              (a.changePercent ?? 0).compareTo(b.changePercent ?? 0));
      default:
        return _quotes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radar_rounded,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('المراقبة اللحظية',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('أسعار حية متحركة',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _autoRefresh
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill_rounded,
                              color: AppColors.white,
                            ),
                            onPressed: _toggleAutoRefresh,
                            tooltip: _autoRefresh ? 'إيقاف' : 'تشغيل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: AppColors.white),
                            onPressed: _refresh,
                          ),
                        ],
                      ),
                      _buildMarketChips(),
                    ],
                  ),
                ),
              ),
            ),
            // Status bar
            SliverToBoxAppBar(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final alpha = 0.4 + 0.6 * _pulseCtrl.value;
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _autoRefresh
                                ? AppColors.success.withValues(alpha: alpha)
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _autoRefresh ? 'مباشر — تحديث كل 15 ثانية' : 'متوقف',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${_quotes.length} سهم',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAppBar(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'الكل',
                      active: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'الصاعدون',
                      active: _filter == 'gainers',
                      color: AppColors.success,
                      onTap: () => setState(() => _filter = 'gainers'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'الهابطون',
                      active: _filter == 'losers',
                      color: AppColors.danger,
                      onTap: () => setState(() => _filter = 'losers'),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading && _quotes.isEmpty)
              const SliverToBoxAdapter(
                child: SkeletonList(itemCount: 6, itemHeight: 80),
              )
            else if (_error != null && _quotes.isEmpty)
              SliverFillRemaining(
                child: StateView(error: _error, onRetry: _refresh),
              )
            else if (_filteredQuotes.isEmpty)
              const SliverFillRemaining(
                child: StateView(
                  empty: true,
                  emptyMessage: 'لا توجد أسعار لحظية متاحة',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                sliver: SliverList.builder(
                  itemCount: _filteredQuotes.length,
                  itemBuilder: (context, index) {
                    final q = _filteredQuotes[index];
                    final prev = _previousPrices[q.ticker];
                    return RepaintBoundary(
                      child: _LiveQuoteRow(
                        quote: q,
                        previousPrice: prev,
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

  Widget _buildMarketChips() {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _markets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final m = _markets[index];
          final active = m == _selectedMarket;
          return GestureDetector(
            onTap: () => _changeMarket(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.white
                    : AppColors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// A simple sliver-to-box-app-bar wrapper that just renders its child as a sliver
class SliverToBoxAppBar extends StatelessWidget {
  final Widget child;
  const SliverToBoxAppBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: child);
  }
}

// ============================================================================
// Filter Chip
// ============================================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
              color: active ? c : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppColors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ============================================================================
// Live Quote Row with animation
// ============================================================================
class _LiveQuoteRow extends StatefulWidget {
  final _LiveQuote quote;
  final double? previousPrice;

  const _LiveQuoteRow({
    required this.quote,
    required this.previousPrice,
  });

  @override
  State<_LiveQuoteRow> createState() => _LiveQuoteRowState();
}

class _LiveQuoteRowState extends State<_LiveQuoteRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashCtrl;
  Color? _flashColor;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant _LiveQuoteRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = oldWidget.quote.currentPrice;
    final cur = widget.quote.currentPrice;
    if (prev != null && cur != null && prev != cur) {
      _flashColor = cur > prev ? AppColors.success : AppColors.danger;
      _flashCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quote;
    final change = q.changePercent ?? 0;
    final isUp = change >= 0;
    final changeColor = isUp ? AppColors.success : AppColors.danger;
    return AnimatedBuilder(
      animation: _flashCtrl,
      builder: (_, child) {
        final alpha = (1 - _flashCtrl.value) * 0.25;
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _flashColor != null && alpha > 0
                ? _flashColor!.withValues(alpha: alpha)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              q.ticker.isNotEmpty
                  ? q.ticker.substring(0, q.ticker.length.clamp(0, 2))
                  : '?',
              style: TextStyle(
                color: changeColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.ticker,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                if (q.displayName.isNotEmpty &&
                    q.displayName != q.ticker)
                  Text(q.displayName,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                q.currentPrice != null
                    ? q.currentPrice!.toStringAsFixed(2)
                    : '--',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12, color: changeColor),
                  const SizedBox(width: 2),
                  Text(
                    '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: changeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Live Quote Model
// ============================================================================
class _LiveQuote {
  final String ticker;
  final String displayName;
  final double? currentPrice;
  final double? changePercent;
  final int? volume;

  _LiveQuote({
    required this.ticker,
    required this.displayName,
    required this.currentPrice,
    required this.changePercent,
    required this.volume,
  });

  factory _LiveQuote.fromMap(Map<String, dynamic> m) {
    final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString();
    final name = (m['name'] ?? m['company'] ?? '').toString();
    final nameAr = (m['name_ar'] ?? m['nameAr'] ?? '').toString();
    return _LiveQuote(
      ticker: ticker,
      displayName: nameAr.isNotEmpty ? nameAr : (name.isNotEmpty ? name : ticker),
      currentPrice: _toDouble(m['current_price'] ??
          m['price'] ??
          m['last_price'] ??
          m['lastPrice']),
      changePercent: _toDouble(m['change_percent'] ??
          m['changePercent'] ??
          m['change'] ??
          m['pct_change']),
      volume: _toInt(m['volume'] ?? m['value']),
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
