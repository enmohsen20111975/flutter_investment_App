// ============================================================================
// مساعد الاستثمار Flutter - Dual-Track Predictions Screen
// نظام التوقعات المزدوجة: مسار التحليل الكامل + مسار السيولة
// APIs:
//   GET  /api/predictions/dual-track/stats
//   GET  /api/predictions/dual-track/list?market=EGX&track=all
//   POST /api/predictions/dual-track/threshold
//   POST /api/predictions/dual-track/backtest?execute=1
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_localizations.dart';

class DualTrackScreen extends StatefulWidget {
  const DualTrackScreen({super.key});

  @override
  State<DualTrackScreen> createState() => _DualTrackScreenState();
}

class _DualTrackScreenState extends State<DualTrackScreen> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _tickers = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  // Tabs: الكل / تحليل كامل / سيولة
  String _selectedTrack = 'all'; // all | full | liquidity
  String _selectedMarket = 'EGX';

  static const List<Map<String, String>> _markets = [
    {'code': 'EGX', 'label': 'مصر'},
    {'code': 'TADAWUL', 'label': 'السعودية'},
    {'code': 'KSE', 'label': 'الكويت'},
    {'code': 'QSE', 'label': 'قطر'},
    {'code': 'DFM', 'label': 'دبي'},
    {'code': 'ADX', 'label': 'أبوظبي'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ──────────────────────────────────────────────────────────────────────
  // API calls — defensive parsing (no mock data; empty on failure).
  // ──────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _fetchStats() async {
    try {
      final response = await api.dio.get(
        '/api/predictions/dual-track/stats',
        queryParameters: {'market': _selectedMarket},
      );
      final data = response.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[DualTrack] stats fetch failed: $e');
      return <String, dynamic>{};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList() async {
    try {
      final response = await api.dio.get(
        '/api/predictions/dual-track/list',
        queryParameters: {
          'market': _selectedMarket,
          'track': _selectedTrack,
        },
      );
      final data = response.data;
      List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final list = data['tickers'] ??
            data['predictions'] ??
            data['items'] ??
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
      debugPrint('[DualTrack] list fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_fetchStats(), _fetchList()]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _tickers = results[1] as List<Map<String, dynamic>>;
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

  Future<void> _runBacktest() async {
    setState(() => _actionLoading = true);
    try {
      await api.dio.post(
        '/api/predictions/dual-track/backtest',
        queryParameters: {'execute': 1},
      );
      _showSnack('تم تشغيل الـ Backtest بنجاح', AppColors.success);
      await _loadAll();
    } catch (e) {
      _showSnack('فشل تشغيل الـ Backtest: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _recomputeThreshold() async {
    setState(() => _actionLoading = true);
    try {
      await api.dio.post(
        '/api/predictions/dual-track/threshold',
        data: {'market': _selectedMarket},
      );
      _showSnack('تمت إعادة حساب الـ Threshold', AppColors.success);
      await _loadAll();
    } catch (e) {
      _showSnack('فشل إعادة حساب الـ Threshold: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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

  Map<String, dynamic> _extractTrack(String key) {
    if (_stats == null) return <String, dynamic>{};
    final m = _stats!;
    final dynamic direct = m[key];
    if (direct is Map) return Map<String, dynamic>.from(direct);
    // Try nested under "tracks"
    final tracks = m['tracks'];
    if (tracks is Map) {
      final t = tracks[key];
      if (t is Map) return Map<String, dynamic>.from(t);
    }
    return <String, dynamic>{};
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
            'التوقعات المزدوجة',
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
        bottomNavigationBar: _buildActionButtons(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonCard(height: 140),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonCard(height: 120)),
              SizedBox(width: 8),
              Expanded(child: SkeletonCard(height: 120)),
            ],
          ),
          SizedBox(height: 12),
          SkeletonCard(height: 60),
          SizedBox(height: 12),
          SkeletonList(itemCount: 5, itemHeight: 80),
        ],
      );
    }

    if (_error != null && _stats == null) {
      return StateView(
        error: 'فشل تحميل إحصائيات التوقعات المزدوجة',
        onRetry: _loadAll,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _buildMarketSelector(),
          const SizedBox(height: 12),
          _buildCombinedEfficiencyCard(),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTrackCard(
                  'track_a',
                  'المسار A',
                  'تحليل كامل',
                  Icons.analytics_rounded,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTrackCard(
                  'track_b',
                  'المسار B',
                  'سيولة',
                  Icons.water_drop_rounded,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildThresholdsCard(),
          const SizedBox(height: 16),
          _buildTrackTabs(),
          const SizedBox(height: 8),
          _buildTickersList(),
          const SizedBox(height: 16),
          _buildDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildMarketSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('السوق:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedMarket,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surface,
              items: _markets.map((m) {
                return DropdownMenuItem<String>(
                  value: m['code'],
                  child: Text(
                    '${m['label']} (${m['code']})',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v == null || v == _selectedMarket) return;
                setState(() => _selectedMarket = v);
                _loadAll();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedEfficiencyCard() {
    final combined = _stats?['combined_efficiency'] ??
        _stats?['combined'] ??
        _stats?['efficiency'];
    final value = _toDouble(combined is Map ? combined['value'] : combined);
    final label = combined is Map ? combined['label']?.toString() : null;

    // Track totals to enrich hero card
    final trackA = _extractTrack('track_a');
    final trackB = _extractTrack('track_b');
    final totalA = _toInt(trackA['total'] ?? trackA['total_predictions']);
    final totalB = _toInt(trackB['total'] ?? trackB['total_predictions']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppColors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الكفاءة المدمجة',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text('مؤشر دقة المسارين معاً',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  label ?? 'من إجمالي التوقعات',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('توقعات المسار A', '$totalA', AppColors.white),
              _miniStat('توقعات المسار B', '$totalB', AppColors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTrackCard(
    String key,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final track = _extractTrack(key);
    final hitRate = _toDouble(track['hit_rate'] ?? track['win_rate']);
    final total = _toInt(track['total'] ?? track['total_predictions']);
    final wins = _toInt(track['wins'] ?? track['won'] ?? track['win_count']);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${hitRate.toStringAsFixed(1)}%',
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (hitRate / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _trackMiniStat('الإجمالي', '$total'),
              _trackMiniStat('ناجحة', '$wins'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 10)),
        Text(value,
            style: const TextStyle(
                color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildThresholdsCard() {
    final dynamic raw = _stats?['thresholds'] ?? _stats?['dynamic_thresholds'];
    Map<String, dynamic> thresholds;
    if (raw is Map) {
      thresholds = Map<String, dynamic>.from(raw);
    } else {
      thresholds = <String, dynamic>{};
    }

    if (thresholds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              const Text('العتبات الديناميكية (Thresholds)',
                  style: AppTypography.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: thresholds.entries.map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${e.key}: ',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    Text('${e.value}',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTabs() {
    final tabs = <Map<String, dynamic>>[
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_rounded},
      {'key': 'full', 'label': 'تحليل كامل', 'icon': Icons.analytics_rounded},
      {'key': 'liquidity', 'label': 'سيولة', 'icon': Icons.water_drop_rounded},
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = tabs[index];
          final key = t['key'] as String;
          final active = _selectedTrack == key;
          return GestureDetector(
            onTap: () {
              if (_selectedTrack == key) return;
              setState(() => _selectedTrack = key);
              _loadAll();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(t['icon'] as IconData,
                      size: 14,
                      color: active ? AppColors.white : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    t['label'] as String,
                    style: TextStyle(
                      color: active ? AppColors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTickersList() {
    if (_tickers.isEmpty) {
      return const StateView(
        empty: true,
        emptyMessage: 'لا توجد توقعات في هذا المسار حالياً',
      );
    }
    return Column(
      children: _tickers.map((t) => _buildTickerCard(t)).toList(),
    );
  }

  Widget _buildTickerCard(Map<String, dynamic> t) {
    final ticker = t['ticker']?.toString() ??
        t['symbol']?.toString() ??
        t['stock']?.toString() ??
        '—';
    final name = t['name']?.toString() ??
        t['stock_name']?.toString() ??
        t['company_name']?.toString() ??
        '';
    final track = t['track']?.toString() ?? '';
    final confidence = _toDouble(t['confidence'] ?? t['score'], -1);
    final signal = t['signal']?.toString() ??
        t['recommendation']?.toString() ??
        '';
    final hitRate = _toDouble(t['hit_rate'] ?? t['win_rate'], -1);

    final isFullTrack = track.toLowerCase().contains('a') ||
        track.toLowerCase().contains('full');
    final trackColor = isFullTrack ? AppColors.primary : AppColors.secondary;
    final isBuy = signal.toUpperCase().contains('BUY') ||
        signal.toUpperCase().contains('STRONG');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: trackColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              ticker,
              style: TextStyle(
                color: trackColor,
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
                    Flexible(
                      child: Text(
                        name.isEmpty ? ticker : name,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (track.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: trackColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          track.toUpperCase(),
                          style: TextStyle(
                            color: trackColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (confidence >= 0) ...[
                      Text(
                        'الثقة: ${confidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (hitRate >= 0) ...[
                      Text(
                        'نسبة النجاح: ${hitRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: AppColors.success, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (signal.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isBuy ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _translateSignal(signal),
                style: TextStyle(
                  color: isBuy ? AppColors.success : AppColors.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _translateSignal(String signal) {
    final s = signal.toUpperCase();
    if (s.contains('STRONG') && s.contains('BUY')) return 'شراء قوي';
    if (s.contains('STRONG') && s.contains('SELL')) return 'بيع قوي';
    if (s.contains('BUY')) return 'شراء';
    if (s.contains('SELL')) return 'بيع';
    if (s.contains('HOLD')) return 'احتفاظ';
    return signal;
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'تنبيه: هذه التوقعات لأغراض إعلامية فقط ولا تُعتبر توصية استثمارية ملزمة. '
              'يُرجى إجراء بحثك الخاص قبل اتخاذ أي قرار استثماري.',
              style: TextStyle(
                color: AppColors.warning.withValues(alpha: 0.95),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _actionLoading ? null : _recomputeThreshold,
                icon: _actionLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.tune_rounded, size: 18),
                label: const Text('إعادة حساب Threshold'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _runBacktest,
                icon: _actionLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('تشغيل Backtest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
