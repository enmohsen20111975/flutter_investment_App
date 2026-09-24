// ============================================================================
// مساعد الاستثمار Flutter - Prediction Tracking Screen
// شاشة تتبّع التوقعات النشطة والمغلقة: جدول + إحصائيات + فلاتر
// APIs:
//   GET /api/predictions/tracking/list
//   GET /api/predictions/tracking/stats
//   GET /api/predictions/performance-dashboard → api.getPerformanceDashboard
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_localizations.dart';

class PredictionTrackingScreen extends StatefulWidget {
  const PredictionTrackingScreen({super.key});

  @override
  State<PredictionTrackingScreen> createState() =>
      _PredictionTrackingScreenState();
}

class _PredictionTrackingScreenState
    extends State<PredictionTrackingScreen> {
  List<Map<String, dynamic>> _predictions = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _dashboard = {};
  bool _loading = true;
  String? _error;

  // Filter: all | active | closed_win | closed_stop | expired
  String _filter = 'all';

  static const List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'active', 'label': 'نشطة'},
    {'key': 'closed_win', 'label': 'رابحة'},
    {'key': 'closed_stop', 'label': 'وقف خسارة'},
    {'key': 'expired', 'label': 'منتهية'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ──────────────────────────────────────────────────────────────────────
  // API calls
  // ──────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchList() async {
    try {
      final response = await api.dio.get(
        '/api/predictions/tracking/list',
        queryParameters: {'status': _filter},
      );
      final data = response.data;
      List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final list = data['predictions'] ??
            data['items'] ??
            data['tracking'] ??
            data['data'] ??
            data['results'] ??
            const [];
        raw = list is List ? list : const [];
      } else {
        raw = const [];
      }
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[PredictionTracking] list fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      final response =
          await api.dio.get('/api/predictions/tracking/stats');
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[PredictionTracking] stats fetch failed: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _fetchList(),
        _fetchStats(),
        // Best-effort dashboard; tolerate failure
        api.getPerformanceDashboard(days: 30).catchError((_) {
          return <String, dynamic>{};
        }),
      ]);
      if (!mounted) return;
      setState(() {
        _predictions = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _dashboard = results[2] as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────
  double _toDouble(dynamic v, [double def = 0]) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? def;
    return def;
  }

  int _toInt(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  String _fmt(dynamic v, [int digits = 2]) {
    return _toDouble(v).toStringAsFixed(digits);
  }

  String _ticker(Map<String, dynamic> p) {
    return (p['ticker'] ??
            p['symbol'] ??
            p['stock'] ??
            p['stock_ticker'] ??
            '—')
        .toString();
  }

  String _signal(Map<String, dynamic> p) {
    return (p['signal'] ??
            p['signal_type'] ??
            p['recommendation'] ??
            p['action'] ??
            '')
        .toString();
  }

  double _entry(Map<String, dynamic> p) =>
      _toDouble(p['entry_price'] ?? p['entry'] ?? p['price']);

  double _target(Map<String, dynamic> p) =>
      _toDouble(p['target_price'] ?? p['target'] ?? p['target1']);

  double _stop(Map<String, dynamic> p) =>
      _toDouble(p['stop_loss'] ?? p['stop'] ?? p['stop_loss_price']);

  String _status(Map<String, dynamic> p) {
    return (p['status'] ?? p['state'] ?? 'active').toString().toLowerCase();
  }

  // ──────────────────────────────────────────────────────────────────────
  // Status → color / Arabic label
  // ──────────────────────────────────────────────────────────────────────
  ({Color color, String label, IconData icon}) _statusVisual(String status) {
    if (status.contains('win') ||
        status.contains('success') ||
        status.contains('closed_win')) {
      return (
        color: AppColors.success,
        label: 'رابحة',
        icon: Icons.check_circle_rounded,
      );
    }
    if (status.contains('stop') || status.contains('closed_stop')) {
      return (
        color: AppColors.danger,
        label: 'وقف خسارة',
        icon: Icons.cancel_rounded,
      );
    }
    if (status.contains('expired') || status.contains('expired')) {
      return (
        color: AppColors.warning,
        label: 'منتهية',
        icon: Icons.schedule_rounded,
      );
    }
    if (status.contains('pending') || status.contains('wait')) {
      return (
        color: AppColors.info,
        label: 'بانتظار التنفيذ',
        icon: Icons.hourglass_top_rounded,
      );
    }
    return (
      color: AppColors.primary,
      label: 'نشطة',
      icon: Icons.bolt_rounded,
    );
  }

  String _translateSignal(String signal) {
    final s = signal.toUpperCase();
    if (s.contains('STRONG') && s.contains('BUY')) return 'شراء قوي';
    if (s.contains('STRONG') && s.contains('SELL')) return 'بيع قوي';
    if (s.contains('BUY')) return 'شراء';
    if (s.contains('SELL')) return 'بيع';
    if (s.contains('HOLD')) return 'احتفاظ';
    return signal.isEmpty ? '—' : signal;
  }

  bool _matchesFilter(Map<String, dynamic> p) {
    if (_filter == 'all') return true;
    final s = _status(p);
    if (_filter == 'active') {
      return s.contains('active') || s.contains('open') || s.isEmpty;
    }
    if (_filter == 'closed_win') return s.contains('win') || s.contains('success');
    if (_filter == 'closed_stop') return s.contains('stop');
    if (_filter == 'expired') return s.contains('expired');
    return true;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.isArabic;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'تتبّع التوقعات',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadAll,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonCard(height: 100),
          SizedBox(height: 12),
          SkeletonCard(height: 50),
          SizedBox(height: 12),
          SkeletonList(itemCount: 6, itemHeight: 130),
        ],
      );
    }

    if (_error != null && _predictions.isEmpty && _stats.isEmpty) {
      return StateView(
        error: 'فشل تحميل بيانات التتبّع',
        onRetry: _loadAll,
      );
    }

    final filtered =
        _predictions.where(_matchesFilter).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 12),
          _buildDashboardFreshness(),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const StateView(
                empty: true, emptyMessage: 'لا توجد توقعات في هذا الفلتر')
          else
            ...filtered.map(_buildPredictionCard).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final winRate = _toDouble(_stats['win_rate'] ?? _stats['winRate']);
    final total = _toInt(_stats['total'] ??
        _stats['total_predictions'] ??
        _stats['count']);
    final wins = _toInt(_stats['wins'] ?? _stats['won'] ?? _stats['win_count']);
    final losses = _toInt(_stats['losses'] ?? _stats['lost'] ?? _stats['loss_count']);
    final pending = _toInt(_stats['pending'] ?? _stats['active']);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 2 columns on narrow phones, 3 on wider
        final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        final stats = <_StatSpec>[
          _StatSpec('نسبة النجاح', '${_fmt(winRate, 1)}%',
              AppColors.success, Icons.emoji_events_rounded),
          _StatSpec('الإجمالي', '$total', AppColors.primary,
              Icons.list_alt_rounded),
          _StatSpec('رابحة', '$wins', AppColors.success,
              Icons.check_circle_outline_rounded),
          _StatSpec('خاسرة', '$losses', AppColors.danger,
              Icons.cancel_outlined),
          _StatSpec('معلقة', '$pending', AppColors.info,
              Icons.hourglass_top_rounded),
          _StatSpec(
              'فشل',
              '${total - wins - losses - pending}',
              AppColors.textMuted,
              Icons.help_outline_rounded),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats
              .map((s) => SizedBox(
                    width: (constraints.maxWidth -
                            (crossAxisCount - 1) * 8) /
                        crossAxisCount,
                    child: _statCard(s),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _statCard(_StatSpec s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(s.icon, size: 14, color: s.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(s.value,
                    style: TextStyle(
                        color: s.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardFreshness() {
    final info = _dashboard['freshness_info'];
    if (info is! Map) return const SizedBox.shrink();
    final freshnessLabel = info['freshness_label']?.toString();
    final latest = info['latest_prediction_date']?.toString();
    final today = info['predictions_today'];
    final last7d = info['predictions_last_7d'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (freshnessLabel != null && freshnessLabel.isNotEmpty)
                  Text('آخر تحديث: $freshnessLabel',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                if (latest != null && latest.isNotEmpty)
                  Text('أحدث توقع: $latest',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          if (today != null || last7d != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (today != null)
                  Text('اليوم: $today',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                if (last7d != null)
                  Text('آخر 7 أيام: $last7d',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final key = f['key'] as String;
          final active = _filter == key;
          return GestureDetector(
            onTap: () {
              if (_filter == key) return;
              setState(() => _filter = key);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Center(
                child: Text(
                  f['label'] as String,
                  style: TextStyle(
                    color:
                        active ? AppColors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> p) {
    final ticker = _ticker(p);
    final signal = _signal(p);
    final entry = _entry(p);
    final target = _target(p);
    final stop = _stop(p);
    final status = _status(p);
    final visual = _statusVisual(status);
    final confidence = _toDouble(p['confidence'] ?? p['score'], -1);
    final rr = entry > 0 && stop > 0 && target > 0
        ? ((target - entry) / (entry - stop).abs())
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: visual.color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  ticker,
                  style: TextStyle(
                    color: visual.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(ticker,
                            style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        if (signal.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _signalColor(signal)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _translateSignal(signal),
                              style: TextStyle(
                                  color: _signalColor(signal),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(visual.icon, size: 12, color: visual.color),
                        const SizedBox(width: 4),
                        Text(visual.label,
                            style: TextStyle(
                                color: visual.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                        if (confidence >= 0) ...[
                          const SizedBox(width: 10),
                          Text('الثقة: ${confidence.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (rr > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('R:R',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 9)),
                      Text(_fmt(rr, 2),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _priceCell('الدخول', _fmt(entry), AppColors.text),
              const SizedBox(width: 8),
              _priceCell('الهدف', _fmt(target), AppColors.success),
              const SizedBox(width: 8),
              _priceCell('وقف الخسارة', _fmt(stop), AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Color _signalColor(String signal) {
    final s = signal.toUpperCase();
    if (s.contains('BUY')) return AppColors.success;
    if (s.contains('SELL')) return AppColors.danger;
    if (s.contains('HOLD')) return AppColors.warning;
    return AppColors.textMuted;
  }

  Widget _priceCell(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 2),
            Text('$value ج.م',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StatSpec {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatSpec(this.label, this.value, this.color, this.icon);
}
