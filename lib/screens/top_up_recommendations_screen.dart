// ============================================================================
// مساعد الاستثمار Flutter - Top-Up Recommendations Screen
// شاشة توصيات زيادة المركز: تعرض الأسهم الرابحة >= 10% كـ cards
// APIs:
//   GET  /api/portfolio/holdings              → api.getPortfolioHoldings()
//   GET  /api/portfolio/intelligence?ticker=X → via api.dio (deep analysis)
//   POST /api/mobile/portfolio                → api.addToPortfolio(...)
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_localizations.dart';

class TopUpRecommendationsScreen extends StatefulWidget {
  const TopUpRecommendationsScreen({super.key});

  @override
  State<TopUpRecommendationsScreen> createState() =>
      _TopUpRecommendationsScreenState();
}

class _TopUpRecommendationsScreenState
    extends State<TopUpRecommendationsScreen> {
  List<Map<String, dynamic>> _winners = [];
  bool _loading = true;
  String? _error;
  final Set<String> _loadingIntelligence = {};
  final Set<String> _addedTickers = {};

  // Threshold for "top-up" candidates (default 10%)
  static const double _minPnlPct = 10.0;

  @override
  void initState() {
    super.initState();
    _loadHoldings();
  }

  // ──────────────────────────────────────────────────────────────────────
  // API calls
  // ──────────────────────────────────────────────────────────────────────
  Future<void> _loadHoldings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.getPortfolioHoldings();
      List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final list = data['holdings'] ??
            data['positions'] ??
            data['items'] ??
            data['portfolio']?['positions'] ??
            data['portfolio']?['items'] ??
            data['data'] ??
            const [];
        raw = list is List ? list : const [];
      } else {
        raw = const [];
      }

      final all = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Filter winners >= 10%
      final winners = all.where((h) {
        final pnlPct = _toDouble(h['unrealized_pnl_percent'] ??
            h['pnl_percent'] ??
            h['gain_percent'] ??
            h['return_percent']);
        return pnlPct >= _minPnlPct;
      }).toList()
        ..sort((a, b) {
          final pa = _toDouble(a['unrealized_pnl_percent'] ??
              a['pnl_percent'] ??
              a['gain_percent']);
          final pb = _toDouble(b['unrealized_pnl_percent'] ??
              b['pnl_percent'] ??
              b['gain_percent']);
          return pb.compareTo(pa);
        });

      if (!mounted) return;
      setState(() {
        _winners = winners;
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

  Future<Map<String, dynamic>> _fetchIntelligence(String ticker) async {
    try {
      final response = await api.dio.get(
        '/api/portfolio/intelligence',
        queryParameters: {'ticker': ticker},
      );
      final data = response.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('[TopUp] intelligence($ticker) failed: $e');
      return <String, dynamic>{};
    }
  }

  Future<void> _showDeepAnalysis(Map<String, dynamic> h) async {
    final ticker = _ticker(h);
    setState(() => _loadingIntelligence.add(ticker));
    try {
      final intel = await _fetchIntelligence(ticker);
      if (!mounted) return;
      _showIntelligenceSheet(ticker, intel);
    } catch (e) {
      _showSnack('فشل تحميل التحليل العميق: $e', AppColors.danger);
    } finally {
      if (mounted) {
        setState(() => _loadingIntelligence.remove(ticker));
      }
    }
  }

  Future<void> _addToPortfolio(Map<String, dynamic> h) async {
    final ticker = _ticker(h);
    final currentPrice = _toDouble(h['current_price']);
    final sharesController = TextEditingController(text: '');
    final priceController = TextEditingController(
        text: currentPrice > 0 ? currentPrice.toStringAsFixed(2) : '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text('إضافة مركز لـ $ticker',
              style: const TextStyle(
                  color: AppColors.text, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sharesController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.text),
                decoration: _inputDecoration('عدد الأسهم الإضافية'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.text),
                decoration: _inputDecoration('سعر الشراء (ج.م)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              onPressed: () {
                final shares = double.tryParse(sharesController.text) ?? 0;
                final price = double.tryParse(priceController.text) ?? 0;
                if (shares > 0 && price > 0) {
                  Navigator.pop(ctx, {
                    'ticker': ticker,
                    'shares': shares,
                    'price': price,
                  });
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    try {
      await api.addToPortfolio({
        'ticker': result['ticker'],
        'avg_price': result['price'],
        'shares': result['shares'],
      });
      if (!mounted) return;
      setState(() => _addedTickers.add(result['ticker'] as String));
      _showSnack('تمت إضافة المركز بنجاح', AppColors.success);
    } catch (e) {
      _showSnack('فشل إضافة المركز: $e', AppColors.danger);
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

  String _ticker(Map<String, dynamic> h) {
    return (h['stock_ticker'] ??
            h['ticker'] ??
            h['symbol'] ??
            h['stock_symbol'] ??
            '—')
        .toString();
  }

  String _name(Map<String, dynamic> h) {
    return (h['stock_name'] ??
            h['name'] ??
            h['company_name'] ??
            _ticker(h))
        .toString();
  }

  double _pnlPct(Map<String, dynamic> h) {
    return _toDouble(h['unrealized_pnl_percent'] ??
        h['pnl_percent'] ??
        h['gain_percent'] ??
        h['return_percent']);
  }

  double _currentPrice(Map<String, dynamic> h) {
    return _toDouble(h['current_price'] ?? h['price'] ?? h['last_price']);
  }

  double _targetPrice(Map<String, dynamic> h) {
    return _toDouble(h['target_price'] ??
        h['target'] ??
        h['target1'] ??
        h['target_price_1']);
  }

  String _fmt(double v, [int digits = 2]) => v.toStringAsFixed(digits);

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: BorderSide.none,
      ),
    );
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

  void _showIntelligenceSheet(String ticker, Map<String, dynamic> intel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        final entries = intel.entries.where((e) {
          return e.value is String ||
              e.value is num ||
              e.value is bool ||
              (e.value is List && (e.value as List).isNotEmpty) ||
              (e.value is Map && (e.value as Map).isNotEmpty);
        }).toList();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.psychology_rounded,
                              color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('التحليل العميق لـ $ticker',
                                  style: AppTypography.titleSmall),
                              Text('تحليل ذكي شامل للسهم',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: StateView(
                            empty: true,
                            emptyMessage: 'لا يتوفر تحليل عميق لهذا السهم'),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final e = entries[i];
                            return _intelRow(e.key, e.value);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _intelRow(String key, dynamic value) {
    String display;
    if (value is bool) {
      display = value ? 'نعم' : 'لا';
    } else if (value is num) {
      display = value is int
          ? value.toString()
          : value.toStringAsFixed(2);
    } else if (value is List) {
      display = value.take(5).join(' • ');
    } else if (value is Map) {
      display = value.entries
          .take(5)
          .map((e) => '${e.key}: ${e.value}')
          .join(' • ');
    } else {
      display = value.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              _prettyKey(key),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              display,
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  String _prettyKey(String k) {
    return k.replaceAll('_', ' ').replaceAll('-', ' ');
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
            'توصيات زيادة المركز',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadHoldings,
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
          SkeletonCard(height: 60),
          SizedBox(height: 12),
          SkeletonList(itemCount: 4, itemHeight: 140),
        ],
      );
    }

    if (_error != null) {
      return StateView(
        error: 'فشل تحميل توصيات زيادة المركز',
        onRetry: _loadHoldings,
      );
    }

    if (_winners.isEmpty) {
      return const StateView(
        empty: true,
        emptyMessage:
            'لا توجد أسهم رابحة >= 10% حالياً\nعندما تربح بعض أسهمك 10% أو أكثر ستظهر هنا كتوصية لزيادة المركز',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHoldings,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 12),
          ..._winners.map((h) => _buildWinnerCard(h)).toList(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.success, AppColors.neonLime],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فرص زيادة المركز',
                  style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_winners.length} سهم تجاوز ربحه 10%',
                  style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.trending_up_rounded,
              color: AppColors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildWinnerCard(Map<String, dynamic> h) {
    final ticker = _ticker(h);
    final name = _name(h);
    final pnlPct = _pnlPct(h);
    final currentPrice = _currentPrice(h);
    final target = _targetPrice(h);
    final isLoadingIntel = _loadingIntelligence.contains(ticker);
    final isAdded = _addedTickers.contains(ticker);
    final upsidePct =
        currentPrice > 0 && target > 0 ? ((target - currentPrice) / currentPrice) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  ticker,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _miniChip(
                            'السعر: ${_fmt(currentPrice)} ج.م',
                            AppColors.textSecondary),
                        if (target > 0)
                          _miniChip(
                              'الهدف: ${_fmt(target)} ج.م', AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${_fmt(pnlPct, 1)}%',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                    const Text('الربح الحالي',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          if (target > 0 && currentPrice > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('الصعود المتبقي: ',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(
                  '${upsidePct >= 0 ? '+' : ''}${_fmt(upsidePct, 1)}%',
                  style: TextStyle(
                    color: upsidePct >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_upward_rounded,
                    size: 12, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (currentPrice / (target > 0 ? target : 1)).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.surfaceMuted,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoadingIntel
                      ? null
                      : () => _showDeepAnalysis(h),
                  icon: isLoadingIntel
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.psychology_rounded, size: 16),
                  label: const Text('تحليل أعمق'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.base)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isAdded ? null : () => _addToPortfolio(h),
                  icon: isAdded
                      ? const Icon(Icons.check_rounded, size: 16)
                      : const Icon(Icons.add_circle_outline_rounded,
                          size: 16),
                  label: Text(isAdded ? 'تمت الإضافة' : 'إضافة للمحفظة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAdded ? AppColors.success : AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.base)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
