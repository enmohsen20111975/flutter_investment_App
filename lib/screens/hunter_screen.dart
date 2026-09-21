// ============================================================================
// مساعد الاستثمار Flutter - Hunter Screen (الصياد - الفرص الانفجارية)
// Top explosive opportunities from /api/explosive/hunt
//
// Updates:
//   - Filter out non-equity instruments and Egyptian ISINs (EGS..., bonds)
//   - Removed deprecated 3 personas (gambler/balanced/conservative)
//   - Translate technical English reason phrases to clear professional Arabic
//   - Display Arabic company name, sector, momentum, volume surge, and breakout
//   - Tappable cards navigating directly to StockHistoryScreen
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stock_history_screen.dart';

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
    return api.getExplosiveOpportunities(
      market: _selectedMarket != 'ALL' ? _selectedMarket : null,
      limit: 30,
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
    if (score >= 55) return AppColors.primaryLight;
    if (score >= 40) return AppColors.warning;
    return AppColors.textMuted;
  }

  /// Exclude stocks with absurd momentum (bad data)
  bool _isBadData(Map<String, dynamic> cand) {
    final m5 = _toDouble(cand['momentum_5d'] ?? cand['indicators']?['momentum_5d']);
    if (m5 != null && m5.abs() > 200) return true;
    final m20 = _toDouble(cand['momentum_20d'] ?? cand['indicators']?['momentum_20d']);
    if (m20 != null && m20.abs() > 400) return true;
    return false;
  }

  /// Exclude non-stock instruments (Egyptian ISINs, bonds, treasury bills, right issues)
  bool _isNonEquityInstrument(Map<String, dynamic> cand) {
    final ticker = (cand['ticker'] ?? cand['symbol'] ?? '').toString().trim().toUpperCase();
    if (ticker.isEmpty) return true;

    // 1) Egyptian ISINs (EGS...), bonds (EGB...), or suffixes like -EGP
    // Examples: EGS48271C018-EGP, EGS30AJ1C016-EGP, EGB...
    if (ticker.startsWith('EGS') || ticker.startsWith('EGB') || ticker.contains('-EGP')) {
      return true;
    }

    // 2) Typical 12-character ISIN or instruments containing numbers and hyphens (except standard Saudi 4-digit numeric tickers)
    final isSaudiNumeric = RegExp(r'^\d{4}$').hasMatch(ticker);
    if (!isSaudiNumeric) {
      if (ticker.length >= 8 && RegExp(r'\d').hasMatch(ticker)) {
        return true;
      }
      if (ticker.contains('-') || ticker.contains('.')) {
        return true;
      }
    }

    // 3) Explicit is_isin flag if provided by backend
    if (cand['is_isin'] == true) {
      return true;
    }

    return false;
  }

  bool _matchesSelectedMarket(Map<String, dynamic> cand) {
    if (_selectedMarket == 'ALL') return true;

    final marketStr = (cand['market'] ?? cand['exchange'] ?? cand['market_code'] ?? '').toString().toUpperCase();
    if (marketStr.isNotEmpty && marketStr != _selectedMarket) {
      return false;
    }

    final ticker = (cand['ticker'] ?? cand['symbol'] ?? '').toString().trim();
    final isNumericTicker = RegExp(r'^\d{4}$').hasMatch(ticker);

    if (_selectedMarket == 'EGX') {
      if (isNumericTicker || marketStr == 'TADAWUL') return false;
    } else if (_selectedMarket == 'TADAWUL') {
      if (!isNumericTicker && marketStr != 'TADAWUL') return false;
    }

    return true;
  }

  /// تحويل العبارات والمصطلحات الفنية الإنجليزية إلى لغة استثمارية عربية واضحة ومفهومة للمستخدم
  String _translateReasonToArabic(String reasons) {
    if (reasons.isEmpty) return '';
    var text = reasons.trim();

    // 5d momentum
    text = text.replaceAllMapped(
        RegExp(r'5d momentum\s*([+-]?\d+\.?\d*%)', caseSensitive: false),
        (m) => 'زخم 5 أيام: ${m[1]}');
    text = text.replaceAllMapped(
        RegExp(r'20d trend\s*([+-]?\d+\.?\d*%)', caseSensitive: false),
        (m) => 'مسار 20 يوم: ${m[1]}');

    // Accumulation & volume
    text = text.replaceAllMapped(
        RegExp(r'volume\s*([\d\.]+[×x])\s*\(massive accumulation\)', caseSensitive: false),
        (m) => 'سيولة ${m[1]} أضعاف (تجميع ضخم 🚀)');
    text = text.replaceAllMapped(
        RegExp(r'volume\s*([\d\.]+[×x])\s*\(heavy accumulation\)', caseSensitive: false),
        (m) => 'سيولة ${m[1]} أضعاف (تجميع عالي 📈)');
    text = text.replaceAllMapped(
        RegExp(r'volume\s*([\d\.]+[×x])\s*\(accumulation\)', caseSensitive: false),
        (m) => 'سيولة ${m[1]} أضعاف (تجميع سيولة)');
    text = text.replaceAllMapped(
        RegExp(r'volume\s*([\d\.]+[×x])', caseSensitive: false),
        (m) => 'حجم تداول ${m[1]} أضعاف');

    // Breakouts and highs
    text = text.replaceAll(RegExp(r'breakout\s*\(new 20d high\)', caseSensitive: false), 'اختراق فني (قمة 20 يوم جديدة 🎯)');
    text = text.replaceAll(RegExp(r'breakout\s*\(new 52w high\)', caseSensitive: false), 'اختراق فني (قمة سنوية 52W 🌟)');
    text = text.replaceAllMapped(
        RegExp(r'near 20d high\s*\(([\d\.]+%)\)', caseSensitive: false),
        (m) => 'قريب من قمة 20 يوم بنسبة ${m[1]}');
    text = text.replaceAll(RegExp(r'near 20d high', caseSensitive: false), 'قريب من قمة 20 يوم');

    // Modifiers & patterns
    text = text.replaceAll(RegExp(r'\(surge\)', caseSensitive: false), '(قفزة سعرية سريعة ⚡)');
    text = text.replaceAll(RegExp(r'\(moderate surge\)', caseSensitive: false), '(صعود تدريجي)');
    text = text.replaceAll(RegExp(r'breakout', caseSensitive: false), 'اختراق صاعد');
    text = text.replaceAll(RegExp(r'consolidation', caseSensitive: false), 'مرحلة تجميع وتماسك');
    text = text.replaceAll(RegExp(r'oversold bounce', caseSensitive: false), 'ارتداد من تشبع بيعي');
    text = text.replaceAll(RegExp(r'golden cross', caseSensitive: false), 'تقاطع ذهبي إيجابي');

    // Format separator
    text = text.replaceAll('|', ' • ');

    return text;
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
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
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
                    .where((c) =>
                        !_isBadData(c) &&
                        _matchesSelectedMarket(c) &&
                        !_isNonEquityInstrument(c))
                    .toList()
                : const <dynamic>[];

            if (candidates.isEmpty) {
              return const StateView(
                empty: true,
                emptyMessage: 'لا توجد فرص انفجارية متاحة حالياً للأسهم المحددة',
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF162032), Color(0xFF0F172A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text('ملخص مسح الفرص الانفجارية',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.text, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryChip('تم مسح', '$scanned سهم'),
              _summaryChip('فرص قوية مكتشفة', '$totalCandidates', color: AppColors.warning),
              _summaryChip('أسهم نقية معروضة', '$shownCount سهم', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'اسحب للأسفل لتحديث المسح اللحظي · اضغط على أي سهم لفتح التحليل الكامل',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, {Color? color}) {
    final c = color ?? AppColors.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary)),
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
    final nameAr = cand['name_ar']?.toString();
    final sector = cand['sector']?.toString();
    final explosiveScore = _toDouble(cand['explosive_score']) ?? 0;
    final maestroScore = _toDouble(cand['maestro_score_proxy']) ??
        _toDouble(cand['maestro_score']) ??
        0;

    final indicators = cand['indicators'] is Map
        ? Map<String, dynamic>.from(cand['indicators'] as Map)
        : <String, dynamic>{};

    final currentPrice = _toDouble(cand['current_price'] ?? indicators['current_price']);
    final momentum5d = _toDouble(cand['momentum_5d'] ?? indicators['momentum_5d']);
    final volumeRatio = _toDouble(cand['volume_ratio'] ?? indicators['volume_ratio']);
    final isBreakout = cand['is_breakout'] == true || indicators['is_breakout'] == true;

    final rawReasons = cand['reasons']?.toString() ??
        cand['reasoning']?.toString() ??
        '';
    final translatedReasons = _translateReasonToArabic(rawReasons);

    final scoreColor = _scoreColor(explosiveScore);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StockHistoryScreen(ticker: ticker),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: explosiveScore >= 80
                ? scoreColor.withValues(alpha: 0.5)
                : AppColors.cardBorder,
            width: explosiveScore >= 85 ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: rank + ticker + name + explosive score ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$rankIndex',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(ticker,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                          if (sector != null && sector.isNotEmpty && sector != '—') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                sector,
                                style: const TextStyle(fontSize: 10, color: AppColors.primaryLight),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (nameAr != null && nameAr.isNotEmpty)
                        Text(
                          nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                // Explosive score circle
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: (explosiveScore / 100).clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: AppColors.surfaceMuted,
                      color: scoreColor,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${explosiveScore.toInt()}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: scoreColor)),
                        const Text('انفجار',
                            style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Row 2: maestro score + current price ──
            Row(children: [
              _infoBlock('تقييم Maestro', '${maestroScore.toInt()}/100',
                  color: AppColors.secondaryLight),
              const SizedBox(width: 12),
              if (currentPrice != null)
                _infoBlock('السعر الحالي', '${currentPrice.toStringAsFixed(2)} ج.م',
                    color: AppColors.text),
            ]),
            const SizedBox(height: 10),

            // ── Row 3: Technical Signals & Momentum Badges ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (momentum5d != null)
                  _signalBadge(
                    label: 'زخم 5 أيام: ${momentum5d >= 0 ? '+' : ''}${momentum5d.toStringAsFixed(1)}%',
                    icon: momentum5d >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: momentum5d >= 0 ? AppColors.success : AppColors.danger,
                  ),
                if (volumeRatio != null && volumeRatio > 1.0)
                  _signalBadge(
                    label: 'سيولة ${volumeRatio.toStringAsFixed(1)}x ضعف المعدل',
                    icon: Icons.waterfall_chart,
                    color: const Color(0xFFF59E0B),
                  ),
                if (isBreakout)
                  _signalBadge(
                    label: 'اختراق فني مؤكد 🎯',
                    icon: Icons.check_circle_outline,
                    color: AppColors.primaryLight,
                  ),
              ],
            ),

            // ── Row 4: Translated Arabic Reasons ──
            if (translatedReasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.3))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.insights, size: 15, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        translatedReasons,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _signalBadge({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
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
