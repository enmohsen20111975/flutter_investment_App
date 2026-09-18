// ============================================================================
// مساعد الاستثمار Flutter - Expert Predictions Screen (Simplified - Balanced Only)
// Shows expert predictions/analysis with stats, status filter,
// freshness badge and 60s auto-refresh.
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
import '../core/app_localizations.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Future<RecommendationsData?>? _dataFuture;
  Future<Map<String, dynamic>?>? _freshnessFuture;

  // Only balanced persona - no filter needed
  static const String _selectedPersona = 'balanced';

  // Status filter
  String _statusFilter = 'all';

  String _activeMarket = 'EGX';

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

  String? get _personaApiParam => _selectedPersona;

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

  String _normalizeStatus(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    if (s.isEmpty) return '';
    if (s == 'closed') return 'expired';
    return s;
  }

  Future<RecommendationsData?> _fetchData() async {
    try {
      final market = await _loadActiveMarket();
      if (mounted) setState(() => _activeMarket = market);

      final persona = _personaApiParam;
      final status = _statusApiParam;

      List<dynamic> rawRecs = <dynamic>[];
      List<Map<String, dynamic>> reports = <Map<String, dynamic>>[];

      final recResult = await _fetchRecommendations(market, persona, status);
      rawRecs = recResult;

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

      if (rawRecs.isEmpty) {
        rawRecs = await _fetchMobileRecommendations(market, persona, status);
      }

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

      // Filter recommendations locally by active market and status only
      List<ExpertRecommendation> filteredRecs = <ExpertRecommendation>[];
      for (final rec in recs) {
        final symbol = rec.stockSymbol ?? '';
        final isNumeric4 = RegExp(r'^\d{4}$').hasMatch(symbol.trim());

        if (market == 'TADAWUL' && !isNumeric4) continue;
        if (market == 'EGX' && isNumeric4) continue;

        // Status Filter
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
    setState(() {
      _dataFuture = _fetchData();
      _freshnessFuture = _fetchFreshness();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.isArabic;
    const Color personaColor = AppColors.warning;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('توقعات الخبراء',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          color: personaColor,
          onRefresh: _refresh,
          child: FutureBuilder<RecommendationsData?>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonList(itemCount: 5);
              }
              if (snapshot.hasError) {
                return StateView(
                    error: 'فشل تحميل التوقعات',
                    onRetry: _refresh);
              }
              final data = snapshot.data;
              if (data == null || data.recommendations.isEmpty) {
                return const StateView(
                    empty: true, emptyMessage: 'لا توجد توقعات متاحة');
              }

              final recs = data.recommendations;
              final stats = data.expertStats;
              final reports = data.morningReports;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMarketHeader(personaColor),
                    const SizedBox(height: 12),
                    if (stats.isNotEmpty) ...[
                      _buildStatsRow(stats),
                      const SizedBox(height: 16),
                    ],
                    _buildStatusFilter(),
                    const SizedBox(height: 12),
                    ...recs.map((rec) => _buildRecommendationCard(rec)),
                    if (reports.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader('التقارير الصباحية', Icons.newspaper),
                      const SizedBox(height: 8),
                      ...reports.map((r) => _buildMorningReportCard(r)),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMarketHeader(Color personaColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [personaColor, personaColor.withValues(alpha: 0.7)]),
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
            child: const Icon(Icons.balance_rounded, color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المتوازن',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white)),
                const SizedBox(height: 2),
                Text(_marketNames[_activeMarket] ?? _activeMarket,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          _buildFreshnessBadge(),
        ],
      ),
    );
  }

  Widget _buildFreshnessBadge() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _freshnessFuture,
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          return FreshnessBadge.fromInfo(snap.data, compact: true);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatsRow(List<ExpertStats> stats) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildExpertStatCard(stat);
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Row(
      children: [
        const Text('الحالة: ',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        _buildStatusChip('الكل', 'all'),
        _buildStatusChip('قيد الانتظار', 'pending'),
        _buildStatusChip('هدف محقق', 'target_hit'),
        _buildStatusChip('موقوف', 'stopped'),
        _buildStatusChip('منتهي', 'expired'),
      ],
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
      width: 150,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(stat.expertName ?? 'خبير',
              style: AppTypography.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStatItem('إجمالي', stat.totalRecommendations.toString()),
              const SizedBox(width: 16),
              _buildStatItem('محقق', stat.successfulRecommendations.toString()),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStatItem('نسبة', '${stat.successRate?.toStringAsFixed(0) ?? 0}%'),
              const SizedBox(width: 16),
              _buildStatItem('عائد', '${stat.avgReturn?.toStringAsFixed(1) ?? 0}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTypography.titleSmall),
      ],
    );
  }

  Color _statusColor(String? status) {
    final s = _normalizeStatus(status);
    if (s == 'target_hit' || s == 'success') return AppColors.success;
    if (s == 'stopped' || s == 'sl_hit') return AppColors.danger;
    if (s == 'expired' || s == 'closed') return AppColors.textMuted;
    return AppColors.info;
  }

  String _statusAr(String? status) {
    final s = _normalizeStatus(status);
    switch (s) {
      case 'pending': return 'قيد الانتظار';
      case 'target_hit': return 'هدف محقق';
      case 'success': return 'ناجح';
      case 'stopped': return 'موقوف';
      case 'sl_hit': return 'وقف خسارة';
      case 'expired': return 'منتهي';
      case 'closed': return 'مغلق';
      default: return status ?? '—';
    }
  }

  Widget _buildRecommendationCard(ExpertRecommendation rec) {
    final actionColor = _getActionColor(rec.action);
    final actionIcon = _getActionIcon(rec.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(actionIcon, color: actionColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.stockSymbol ?? '—',
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
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
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, double? value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTypography.bodySmall),
      const SizedBox(height: 2),
      Text(value?.toStringAsFixed(2) ?? '-', style: AppTypography.titleSmall)
    ]);
  }

  Color _getActionColor(String? action) {
    final a = (action ?? '').toLowerCase();
    if (a.contains('buy') || a.contains('شراء')) return AppColors.success;
    if (a.contains('sell') || a.contains('بيع')) return AppColors.danger;
    if (a.contains('hold') || a.contains('احتفاظ')) return AppColors.warning;
    return AppColors.info;
  }

  IconData _getActionIcon(String? action) {
    final a = (action ?? '').toLowerCase();
    if (a.contains('buy') || a.contains('شراء')) return Icons.trending_up;
    if (a.contains('sell') || a.contains('بيع')) return Icons.trending_down;
    return Icons.remove;
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