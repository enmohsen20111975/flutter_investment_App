// ============================================================================
// مساعد الاستثمار Flutter - Hunter Screen (الصياد)
// Top explosive opportunities from /api/explosive/hunt
//
// Replaces the old generic-recs fallback (which hit /api/v2/recommend) and
// the hardcoded mock COMI/ETEL/SWDY data. The screen now:
//   - Calls getExplosiveOpportunities() → /api/explosive/hunt
//   - Renders a summary header (scanned / candidates / coverage counts)
//   - Renders each candidate as a card with explosive_score, maestro_score,
//     3-persona coverage badges, reasons, current price
//   - Defensive: client-side filter for |momentum_5d| > 200 (bad data)
//   - Error state with Arabic retry button — NO mock fallback
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HunterScreen extends StatefulWidget {
  final int marketVersion;

  const HunterScreen({super.key, this.marketVersion = 0});

  @override
  State<HunterScreen> createState() => _HunterScreenState();
}

class _HunterScreenState extends State<HunterScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedMarket = 'ALL';
  final List<String> _markets = ['ALL', 'EGX', 'TADAWUL', 'KSE', 'QSE'];
  Future<Map<String, dynamic>>? _payloadFuture;

  @override
  void initState() {
    super.initState();
    _loadActiveMarket().then((_) {
      if (mounted) _payloadFuture = _fetchOpportunities();
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant HunterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarket().then((_) => _refresh());
    }
  }

  Future<void> _loadActiveMarket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final market = prefs.getString('active_market') ?? 'EGX';
      if (mounted) {
        setState(() {
          _selectedMarket = market;
        });
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _fetchOpportunities() async {
    // Errors propagate — caller shows Arabic error UI with retry. NO mock.
    return api.getExplosiveOpportunities(
      market: _selectedMarket != 'ALL' ? _selectedMarket : null,
      limit: 20,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _payloadFuture = _fetchOpportunities();
    });
  }

  Color _scoreColor(num score) {
    if (score >= 85) return const Color(0xFFFFD700);
    if (score >= 70) return AppColors.success;
    if (score >= 55) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.textMuted;
  }

  /// Defensive: exclude stocks with absurd momentum (backend already filters
  /// but we double-check client-side as defense in depth).
  bool _isBadData(Map<String, dynamic> cand) {
    final m5 = _toDouble(cand['momentum_5d']);
    if (m5 != null && m5.abs() > 200) return true;
    final m20 = _toDouble(cand['momentum_20d']);
    if (m20 != null && m20.abs() > 400) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('الصياد - الفرص الانفجارية',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMarket,
                  isDense: true,
                  dropdownColor: AppColors.surface,
                  items: _markets
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text)),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedMarket = val);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('active_market', val);
                      } catch (_) {}
                      _refresh();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _payloadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5, itemHeight: 200);
            }
            if (snapshot.hasError) {
              return StateView(
                error: 'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت وحاول مرة أخرى.',
                onRetry: _refresh,
              );
            }
            final payload = snapshot.data ?? <String, dynamic>{};
            final rawCandidates = payload['top_candidates'];
            final List<dynamic> candidates = rawCandidates is List
                ? rawCandidates
                    .whereType<Map>()
                    .map((m) => Map<String, dynamic>.from(m))
                    .where((c) => !_isBadData(c))
                    .toList()
                : const <dynamic>[];

            if (candidates.isEmpty) {
              return const StateView(
                empty: true,
                emptyMessage: 'لا توجد فرص انفجارية متاحة حالياً',
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: candidates.length + 1, // +1 for summary header
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSummaryHeader(payload, candidates.length);
                  }
                  final cand = candidates[index - 1] is Map
                      ? Map<String, dynamic>.from(candidates[index - 1])
                      : <String, dynamic>{};
                  return _buildCandidateCard(cand, index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(Map<String, dynamic> payload, int shownCount) {
    final summary = payload['summary'];
    final summaryMap =
        summary is Map ? Map<String, dynamic>.from(summary) : <String, dynamic>{};
    final scanned = _toInt(summaryMap['scanned']);
    final totalCandidates = _toInt(summaryMap['total_explosive_candidates']);
    final newThresholds =
        summaryMap['coverage_new_thresholds'] is Map
            ? Map<String, dynamic>.from(summaryMap['coverage_new_thresholds'] as Map)
            : <String, dynamic>{};
    final gamblerBuys = _toInt(newThresholds['gambler_buys']);
    final balancedBuys = _toInt(newThresholds['balanced_buys']);
    final conservativeBuys = _toInt(newThresholds['conservative_buys']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.white, size: 22),
              const SizedBox(width: 8),
              Text('ملخص المسح', style: AppTypography.titleMedium.copyWith(color: AppColors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip('تم مسح', '$scanned سهم'),
              _summaryChip('فرص انفجارية', '$totalCandidates'),
              _summaryChip('مضارب (gambler)', '$gamblerBuys شراء', color: AppColors.danger),
              _summaryChip('متوازن (balanced)', '$balancedBuys شراء', color: AppColors.warning),
              _summaryChip('محافظ (conservative)', '$conservativeBuys شراء', color: AppColors.info),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'عرض $shownCount فرصة — تحديث بالسحب للأسفل',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, {Color? color}) {
    final c = color ?? AppColors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.white.withValues(alpha: 0.85))),
          Text(value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> cand, int rankIndex) {
    final ticker =
        cand['ticker']?.toString() ?? cand['symbol']?.toString() ?? '—';
    final explosiveScore = _toDouble(cand['explosive_score']) ?? 0;
    final maestroScore = _toDouble(cand['maestro_score_proxy']) ??
        _toDouble(cand['maestro_score']) ??
        0;
    final currentPrice = _toDouble(cand['current_price']);
    final reasons = cand['reasons']?.toString() ??
        cand['reasoning']?.toString() ??
        '';
    final personaPreds = cand['persona_predictions'];
    final personaMap = personaPreds is Map
        ? Map<String, dynamic>.from(personaPreds)
        : <String, dynamic>{};

    final scoreColor = _scoreColor(explosiveScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: explosiveScore >= 80
              ? scoreColor.withValues(alpha: 0.5)
              : AppColors.border,
          width: explosiveScore >= 85 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: rank + ticker + explosive score ──
          Row(children: [
            Text('#$rankIndex',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(ticker,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            // Explosive score circle
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: (explosiveScore / 100).clamp(0.0, 1.0),
                  strokeWidth: 4,
                  backgroundColor: AppColors.surfaceMuted,
                  color: scoreColor,
                ),
                Text('${explosiveScore.toInt()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: scoreColor)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          // ── Row 2: maestro score + current price ──
          Row(children: [
            _infoBlock('نتيجة Maestro', '${maestroScore.toInt()}',
                color: AppColors.primary),
            const SizedBox(width: 12),
            if (currentPrice != null)
              _infoBlock('السعر الحالي', currentPrice.toStringAsFixed(2),
                  color: AppColors.textSecondary),
          ]),
          const SizedBox(height: 12),
          // ── Row 3: 3-persona coverage badges ──
          const Text('تغطية الشخصيات',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              _personaBadge('gambler', 'المضارب', personaMap['gambler']),
              const SizedBox(width: 6),
              _personaBadge('balanced', 'المتوازن', personaMap['balanced']),
              const SizedBox(width: 6),
              _personaBadge('conservative', 'المحافظ', personaMap['conservative']),
            ],
          ),
          // ── Row 4: reasons text ──
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Text(reasons,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  /// Green badge if the persona would BUY, grey if not.
  Widget _personaBadge(String id, String labelAr, dynamic pred) {
    bool wouldBuy = false;
    String? rec;
    if (pred is Map) {
      wouldBuy = pred['would_buy'] == true || pred['would_buy'] == 1;
      rec = pred['recommendation']?.toString();
    }
    final color = wouldBuy ? AppColors.success : AppColors.textMuted;
    final icon = wouldBuy ? Icons.check_circle : Icons.remove_circle_outline;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(labelAr,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
            if (rec != null && rec.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(rec,
                  style: TextStyle(
                      fontSize: 9, color: color.withValues(alpha: 0.85))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value, {required Color color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
