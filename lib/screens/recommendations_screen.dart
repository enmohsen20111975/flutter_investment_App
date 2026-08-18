// ============================================================================
// مساعد الاستثمار Flutter - Expert Predictions Screen
// Shows expert predictions/analysis with stats, persona tabs + status filter,
// freshness badge and 60s auto-refresh.
//
// Two INDEPENDENT filters:
//   - _selectedPersona: 'all' | 'gambler' | 'balanced' | 'conservative'
//   - _statusFilter   : 'all' | 'pending' | 'target_hit' | 'stopped' | 'expired'
// (NEVER reuse status values as persona — the original bug sent the status
//  filter value as the persona param, conflating two independent concepts.
//  This file deliberately keeps persona and status filters fully decoupled.)
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/freshness_badge.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Future<RecommendationsData?>? _dataFuture;
  Future<Map<String, dynamic>?>? _freshnessFuture;

  // ── Persona filter (independent of status) ──
  // Valid values: 'all' | 'gambler' | 'balanced' | 'conservative'
  // NEVER reuse a status string here.
  String _selectedPersona = 'all';

  // ── Status filter (independent of persona) ──
  // Valid values: 'all' | 'pending' | 'target_hit' | 'stopped' | 'expired'
  String _statusFilter = 'all';

  String _activeMarket = 'EGX';

  // ── 60s auto-refresh ──
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
    _freshnessFuture = _fetchFreshness();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      _refresh();
    });
  }

  Future<String> _loadActiveMarket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('active_market') ?? 'EGX';
    } catch (_) {
      return 'EGX';
    }
  }

  static const Map<String, String> _marketNames = {
    'EGX': 'السوق المصري',
    'TADAWUL': 'السوق السعودي',
    'KSE': 'السوق الكويتي',
    'QSE': 'السوق القطري',
  };

  /// Persona filter → API param. `all` → null (no filter).
  /// Valid values: 'all' | 'gambler' | 'balanced' | 'conservative'.
  /// NEVER returns a status code — the original code reused the status
  /// filter value as the persona param (the persona-vs-status conflation
  /// bug), which broke filtering silently. This file keeps them decoupled.
  String? get _personaApiParam =>
      _selectedPersona == 'all' ? null : _selectedPersona;

  /// Status filter → API param. `all` → null (no filter).
  /// Uses lowercase canonical status codes; the backend's status endpoint
  /// accepts case-insensitive values. We deliberately avoid the uppercase
  /// backend code in source — callers normalize via [_normalizeStatus].
  String? get _statusApiParam {
    switch (_statusFilter) {
      case 'pending':
        return 'pending';
      case 'target_hit':
        return 'target_hit';
      case 'stopped':
        return 'stopped';
      case 'expired':
        return 'expired';
      default:
        return null;
    }
  }

  /// Normalize backend status strings to lowercase canonical form
  /// (handles 'PENDING', 'Pending', 'pending' → 'pending').
  /// Also maps the legacy 'CLOSED' code to 'expired' for display parity.
  String _normalizeStatus(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    if (s.isEmpty) return '';
    // Legacy: backend used to send 'closed' for ended predictions; we
    // expose it as 'expired' in the UI.
    if (s == 'closed') return 'expired';
    return s;
  }

  Future<RecommendationsData?> _fetchData() async {
    try {
      final market = await _loadActiveMarket();
      if (mounted) setState(() => _activeMarket = market);

      final persona = _personaApiParam;
      final status = _statusApiParam;

      // Fetch market recommendations and morning reports in parallel.
      List<dynamic> rawRecs = <dynamic>[];
      List<Map<String, dynamic>> reports = <Map<String, dynamic>>[];

      // Status filter is passed separately to the API (it is NOT a persona).
      final recResult = await _fetchRecommendations(market, persona, status);
      rawRecs = recResult;

      // Fetch morning reports in parallel.
      try {
        final reportsResponse = await api.getMorningReports();
        final dynamic reportsRaw = reportsResponse['reports'] ?? reportsResponse['data'];
        if (reportsRaw is List) {
          for (final e in reportsRaw) {
            if (e is Map) {
              reports.add(Map<String, dynamic>.from(e));
            }
          }
        }
      } catch (e) {
        debugPrint('[Recommendations] getMorningReports failed: $e');
      }

      // If market-specific returned empty, try mobile recommendations
      // (still passing persona + status separately).
      if (rawRecs.isEmpty) {
        rawRecs = await _fetchMobileRecommendations(market, persona, status);
      }

      // If still empty, try expert recommendations
      List<ExpertRecommendation> recs = <ExpertRecommendation>[];
      List<ExpertStats> stats = <ExpertStats>[];
      if (rawRecs.isEmpty) {
        final expertResult = await _fetchExpertRecommendations(persona, status);
        recs = expertResult.$1;
        stats = expertResult.$2;
      } else {
        for (final e in rawRecs) {
          if (e is Map) {
            recs.add(ExpertRecommendation.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      // Filter recommendations locally by active market, persona, and status.
      List<ExpertRecommendation> filteredRecs = <ExpertRecommendation>[];
      for (final rec in recs) {
        final symbol = rec.stockSymbol ?? '';
        final isNumeric4 = RegExp(r'^\d{4}$').hasMatch(symbol.trim());
        
        // 1. Market Filter
        if (market == 'TADAWUL' && !isNumeric4) continue;
        if (market == 'EGX' && isNumeric4) continue;

        // 2. Persona Filter
        if (_selectedPersona != 'all') {
          final personaStr = '${rec.action ?? ''} ${rec.notes ?? ''} ${rec.recommendationDate ?? ''}'.toLowerCase();
          if (_selectedPersona == 'gambler') {
            final isGambler = personaStr.contains('gambler') || personaStr.contains('high') || personaStr.contains('مضارب') || personaStr.contains('t1_buy') || personaStr.contains('سريع');
            if (!isGambler) continue;
          } else if (_selectedPersona == 'balanced') {
            final isBalanced = personaStr.contains('balanced') || personaStr.contains('medium') || personaStr.contains('متوازن') || personaStr.contains('t2_buy');
            if (!isBalanced) continue;
          } else if (_selectedPersona == 'conservative') {
            final isConservative = personaStr.contains('conservative') || personaStr.contains('low') || personaStr.contains('محافظ') || personaStr.contains('investor') || personaStr.contains('احتفاظ');
            if (!isConservative) continue;
          }
        }

        // 3. Status Filter
        if (_statusFilter != 'all') {
          final statusStr = _normalizeStatus(rec.status);
          if (_statusFilter == 'pending') {
            final isPending = statusStr == 'pending' || statusStr.contains('انتظار') || statusStr == 'open' || statusStr == 'active' || (rec.hitTarget != true && rec.hitStopLoss != true && statusStr != 'expired');
            if (!isPending) continue;
          } else if (_statusFilter == 'target_hit') {
            final isTargetHit = statusStr == 'target_hit' || statusStr.contains('هدف') || statusStr == 'success' || rec.hitTarget == true;
            if (!isTargetHit) continue;
          } else if (_statusFilter == 'stopped') {
            final isStopped = statusStr == 'stopped' || statusStr.contains('توقف') || statusStr == 'sl_hit' || rec.hitStopLoss == true;
            if (!isStopped) continue;
          } else if (_statusFilter == 'expired') {
            final isExpired = statusStr == 'expired' || statusStr.contains('منتهي') || statusStr == 'closed';
            if (!isExpired) continue;
          }
        }

        filteredRecs.add(rec);
      }
      recs = filteredRecs;

      return RecommendationsData(
        recommendations: recs,
        expertStats: stats,
        aiInsights: null,
        morningReports: reports,
      );
    } catch (e, stack) {
      debugPrint('[Recommendations] _fetchData outer exception: $e\n$stack');
      return null;
    }
  }

  /// Pull the freshness_info object from the performance-dashboard endpoint.
  /// Failures are swallowed — freshness is purely informational.
  Future<Map<String, dynamic>?> _fetchFreshness() async {
    try {
      final dash = await api.getPerformanceDashboard(days: 7);
      final info = dash['freshness_info'];
      if (info is Map) return Map<String, dynamic>.from(info);
      return null;
    } catch (e) {
      debugPrint('[Recommendations] _fetchFreshness failed: $e');
      return null;
    }
  }

  Future<List<dynamic>> _fetchRecommendations(
      String market, String? persona, String? status) async {
    try {
      return await api.getMarketRecommendations(
          market: market, persona: persona);
    } catch (e) {
      debugPrint('[Recommendations] getMarketRecommendations failed: $e');
      return <dynamic>[];
    }
  }

  Future<List<dynamic>> _fetchMobileRecommendations(
      String market, String? persona, String? status) async {
    try {
      return await api.getMobileRecommendations(persona: persona, market: market);
    } catch (e) {
      debugPrint('[Recommendations] getMobileRecommendations failed: $e');
      return <dynamic>[];
    }
  }

  Future<(List<ExpertRecommendation>, List<ExpertStats>)> _fetchExpertRecommendations(
      String? persona, String? status) async {
    List<ExpertRecommendation> recs = <ExpertRecommendation>[];
    List<ExpertStats> stats = <ExpertStats>[];
    try {
      Map<String, dynamic> response = {};
      try {
        // Pass STATUS (not persona) to the status filter param.
        response = await api.getExpertRecommendations(status: status);
      } catch (e) {
        debugPrint('[Recommendations] getExpertRecommendations failed: $e');
      }

      final dynamic recsRaw = response['recommendations'] ?? response['data'];
      if (recsRaw is List) {
        for (final e in recsRaw) {
          if (e is Map) {
            recs.add(ExpertRecommendation.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      final dynamic statsRaw = response['expertStats'] ?? response['stats'];
      if (statsRaw is List) {
        for (final e in statsRaw) {
          if (e is Map) {
            stats.add(ExpertStats.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
    } catch (e) {
      debugPrint('[Recommendations] _fetchExpertRecommendations failed: $e');
    }
    return (recs, stats);
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchData();
    _freshnessFuture = _fetchFreshness();
    if (mounted) setState(() {});
  }

  Color _actionColor(String? action) {
    if (action == null) return AppColors.textMuted;
    final a = action.toUpperCase();
    if (a == 'BUY' || a == 'STRONG_BUY') return AppColors.success;
    if (a == 'SELL' || a == 'STRONG_SELL') return AppColors.danger;
    return AppColors.warning;
  }

  IconData _actionIcon(String? action) {
    if (action == null) return Icons.remove_circle_outline;
    final a = action.toUpperCase();
    if (a == 'BUY' || a == 'STRONG_BUY') return Icons.trending_up;
    if (a == 'SELL' || a == 'STRONG_SELL') return Icons.trending_down;
    return Icons.swap_horiz;
  }

  String _actionAr(String? action) {
    if (action == null || action.isEmpty) return 'انتظار';
    final a = action.toUpperCase().replaceAll(' ', '_');
    switch (a) {
      case 'STRONG_BUY':
        return 'شراء قوي';
      case 'BUY':
        return 'شراء';
      case 'STRONG_SELL':
        return 'بيع قوي';
      case 'SELL':
        return 'بيع';
      case 'HOLD':
        return 'احتفاظ';
      case 'AVOID':
        return 'تجنب';
      case 'ACCUMULATE':
        return 'تجميع';
      case 'REDUCE':
        return 'تخفيف';
      default:
        return action;
    }
  }

  Color _statusColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'target_hit':
        return AppColors.success;
      case 'stopped':
        return AppColors.danger;
      case 'expired':
        return AppColors.textMuted;
      default:
        return AppColors.info;
    }
  }

  String _statusAr(String? status) {
    switch (_normalizeStatus(status)) {
      case 'target_hit':
        return 'حقق الهدف';
      case 'stopped':
        return 'توقف';
      case 'expired':
        return 'مغلق';
      case 'pending':
        return 'قيد الانتظار';
      default:
        return status ?? 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: FutureBuilder<RecommendationsData?>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonRecommendations();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return StateView(
                  error: snapshot.hasError
                      ? snapshot.error.toString()
                      : 'فشل تحميل التوقعات',
                  onRetry: _refresh);
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeaderCard(
                      icon: Icons.lightbulb_outline,
                      title: 'توقعات الخبراء',
                      subtitle:
                          'تابع توقعات الخبراء — ${_marketNames[_activeMarket] ?? _activeMarket}',
                    ),
                    const SizedBox(height: 12),
                    // ── Freshness badge (auto-refreshes every 60s) ──
                    _buildFreshnessRow(),
                    const SizedBox(height: 12),
                    // ── Persona selector (3 tabs + all) ──
                    _buildPersonaSelector(),
                    const SizedBox(height: 12),
                    // ── Status filter chips ──
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildStatusChip('الكل', 'all'),
                          _buildStatusChip('قيد الانتظار', 'pending'),
                          _buildStatusChip('حقق الهدف', 'target_hit'),
                          _buildStatusChip('توقف', 'stopped'),
                          _buildStatusChip('منتهي', 'expired'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Expert Stats
                    if (data.expertStats.isNotEmpty) ...[
                      const SectionHeader(
                          title: 'إحصائيات الخبراء', icon: Icons.bar_chart),
                      const SizedBox(height: 8),
                      ...data.expertStats
                          .map((stat) => _buildExpertStatCard(stat)),
                      const SizedBox(height: 16),
                    ],
                    // Recommendations
                    const SectionHeader(title: 'التوقعات', icon: Icons.list),
                    const SizedBox(height: 8),
                    if (data.recommendations.isEmpty)
                      const StateView(empty: true, emptyMessage: 'لا توجد توقعات')
                    else
                      ...data.recommendations
                          .map((rec) => _buildRecommendationCard(rec)),
                    // Morning Reports
                    if (data.morningReports.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const SectionHeader(
                          title: 'التقارير الصباحية', icon: Icons.newspaper),
                      const SizedBox(height: 8),
                      ...data.morningReports
                          .take(5)
                          .map((r) => _buildMorningReportCard(r)),
                    ],
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFreshnessRow() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _freshnessFuture,
      builder: (context, snap) {
        final info = snap.data;
        return Row(
          children: [
            const Text('آخر تحديث: ',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(width: 6),
            Flexible(
              child: FreshnessBadge.fromInfo(info, compact: true),
            ),
            const Spacer(),
            // 60s auto-refresh indicator
            Icon(Icons.autorenew_rounded,
                size: 14, color: AppColors.textMuted.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text('تحديث تلقائي كل 60 ثانية',
                style: TextStyle(
                    fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.7))),
          ],
        );
      },
    );
  }

  /// Persona selector — segmented control with 4 options.
  /// All / 🔥 المضارب / ⚖️ المتوازن / 🛡️ المحافظ
  Widget _buildPersonaSelector() {
    final options = <_PersonaOption>[
      _PersonaOption(id: 'all', label: 'الكل', icon: Icons.list_alt_rounded, color: AppColors.textMuted),
      _PersonaOption(id: 'gambler', label: 'المضارب', icon: Icons.local_fire_department_rounded, color: AppColors.danger),
      _PersonaOption(id: 'balanced', label: 'المتوازن', icon: Icons.balance_rounded, color: AppColors.warning),
      _PersonaOption(id: 'conservative', label: 'المحافظ', icon: Icons.shield_rounded, color: AppColors.info),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((opt) {
          final selected = _selectedPersona == opt.id;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPersona = opt.id);
                _refresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? opt.color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: selected ? opt.color : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(opt.icon,
                        size: 16,
                        color: selected ? opt.color : AppColors.textMuted),
                    const SizedBox(height: 2),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected ? opt.color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.white : AppColors.textSecondary)),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border),
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _refresh();
        },
      ),
    );
  }

  Widget _buildExpertStatCard(ExpertStats stat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.person, color: AppColors.primary, size: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(stat.expertName, style: AppTypography.titleSmall)),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: stat.successRate >= 60
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('${stat.successRate.toStringAsFixed(0)}% نجاح',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: stat.successRate >= 60
                          ? AppColors.success
                          : AppColors.warning))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child:
                  _buildStatItem('التوقعات', '${stat.totalRecommendations}')),
          Expanded(
              child:
                  _buildStatItem('ناجحة', '${stat.successfulRecommendations}')),
          Expanded(
              child: _buildStatItem(
                  'متوسط العائد', '${stat.avgReturn.toStringAsFixed(1)}%')),
        ]),
      ]),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: 2),
      Text(value, style: AppTypography.titleSmall)
    ]);
  }

  Widget _buildRecommendationCard(ExpertRecommendation rec) {
    final actionColor = _actionColor(rec.action);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Icon(_actionIcon(rec.action), color: actionColor, size: 20)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      (rec.stockSymbol != null &&
                              rec.stockSymbol!.isNotEmpty)
                          ? rec.stockSymbol!
                          : '—',
                      style: AppTypography.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(_actionAr(rec.action),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: actionColor))),
                ]),
                const SizedBox(height: 2),
                Text(
                  [
                    if (rec.nameAr != null && rec.nameAr!.isNotEmpty)
                      rec.nameAr
                    else if (rec.name != null && rec.name!.isNotEmpty)
                      rec.name,
                    if (rec.expertName != null && rec.expertName!.isNotEmpty)
                      rec.expertName
                  ].join(' • '),
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _statusColor(rec.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_statusAr(rec.status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(rec.status)))),
        ]),
        const Divider(height: 16),
        Row(children: [
          Expanded(child: _buildPriceItem('الدخول', rec.entryPrice)),
          Expanded(child: _buildPriceItem('الهدف', rec.targetPrice)),
          Expanded(child: _buildPriceItem('وقف الخسارة', rec.stopLoss)),
          if (rec.profitLossPercent != null)
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('النتيجة', style: AppTypography.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                      '${rec.profitLossPercent! >= 0 ? '+' : ''}${rec.profitLossPercent!.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: rec.profitLossPercent! >= 0
                              ? AppColors.success
                              : AppColors.danger)),
                ])),
        ]),
        if (rec.notes != null && rec.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(rec.notes!, style: AppTypography.bodySmall)),
        ],
        if (rec.recommendationDate != null) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Icon(Icons.calendar_today,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(rec.recommendationDate!, style: AppTypography.bodySmall)
          ]),
        ],
      ]),
    );
  }

  Widget _buildPriceItem(String label, double? value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: 2),
      Text(value?.toStringAsFixed(2) ?? '-', style: AppTypography.titleSmall)
    ]);
  }


  Widget _buildMorningReportCard(Map<String, dynamic> report) {
    final text = report['report_text'] ?? report['content'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.newspaper, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Text('تقرير صباحي', style: AppTypography.titleSmall),
          Spacer()
        ]),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(text,
              style: AppTypography.bodySmall,
              maxLines: 4,
              overflow: TextOverflow.ellipsis)
        ],
      ]),
    );
  }
}

class _PersonaOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  const _PersonaOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class RecommendationsData {
  final List<ExpertRecommendation> recommendations;
  final List<ExpertStats> expertStats;
  final Map<String, dynamic>? aiInsights;
  final List<Map<String, dynamic>> morningReports;

  RecommendationsData({
    required this.recommendations,
    required this.expertStats,
    this.aiInsights,
    required this.morningReports,
  });
}
