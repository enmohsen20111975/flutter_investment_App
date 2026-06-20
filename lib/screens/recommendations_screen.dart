// ============================================================================
// مساعد الاستثمار Flutter - Expert Predictions Screen
// Shows expert predictions/analysis with stats and filtering
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Future<RecommendationsData?>? _dataFuture;
  String _statusFilter = 'all';
  String _activeMarket = 'EGX';

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
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

  Future<RecommendationsData?> _fetchData() async {
    try {
      final market = await _loadActiveMarket();
      if (mounted) setState(() => _activeMarket = market);
      final persona = _statusFilter != 'all' ? _statusFilter : null;

      // 1) Try market-specific recommendations first (matches the user's
      //    selected market, e.g. EGX) so predictions aren't from another
      //    market (e.g. Saudi TADAWUL).
      List<dynamic> rawRecs = await api.getMarketRecommendations(
          market: market, persona: persona);

      // 2) Fallback to all-markets mobile endpoint (with market hint) if the
      //    market route is unavailable or empty.
      if (rawRecs.isEmpty) {
        rawRecs =
            await api.getMobileRecommendations(persona: persona, market: market);
      }

      List<ExpertRecommendation> recs = rawRecs
          .map((e) =>
              ExpertRecommendation.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();

      // Fallback to expert recommendations if empty
      if (recs.isEmpty) {
        final response = await api.getExpertRecommendations(
            status: _statusFilter != 'all' ? _statusFilter : null);
        recs = (response['recommendations'] as List?)
                ?.map((e) => ExpertRecommendation.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        if (recs.isEmpty) {
          recs = (response['data'] as List?)
                  ?.map((e) => ExpertRecommendation.fromJson(
                      Map<String, dynamic>.from(e as Map)))
                  .toList() ??
              [];
        }

        var stats = (response['expertStats'] as List?)
                ?.map((e) =>
                    ExpertStats.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [];
        if (stats.isEmpty) {
          stats = (response['stats'] as List?)
                  ?.map((e) =>
                      ExpertStats.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList() ??
              [];
        }

        final aiInsights = await api.getMarketAiInsights();
        final reportsResponse = await api.getMorningReports();
        final reports = (reportsResponse['reports'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            <Map<String, dynamic>>[];

        return RecommendationsData(
          recommendations: recs,
          expertStats: stats,
          aiInsights: aiInsights,
          morningReports: reports,
        );
      }

      final aiInsights = await api.getMarketAiInsights();
      final reportsResponse = await api.getMorningReports();
      final reports = (reportsResponse['reports'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          <Map<String, dynamic>>[];

      return RecommendationsData(
        recommendations: recs,
        expertStats: [],
        aiInsights: aiInsights,
        morningReports: reports,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchData();
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
    switch (status) {
      case 'HIT_TARGET':
        return AppColors.success;
      case 'STOPPED':
        return AppColors.danger;
      case 'CLOSED':
        return AppColors.textMuted;
      default:
        return AppColors.info;
    }
  }

  String _statusAr(String? status) {
    switch (status) {
      case 'HIT_TARGET':
        return 'حقق الهدف';
      case 'STOPPED':
        return 'توقف';
      case 'CLOSED':
        return 'مغلق';
      case 'PENDING':
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
                    const SizedBox(height: 16),
                    // Status Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('الكل', 'all'),
                          _buildFilterChip('قيد الانتظار', 'PENDING'),
                          _buildFilterChip('حقق الهدف', 'HIT_TARGET'),
                          _buildFilterChip('توقف', 'STOPPED'),
                          _buildFilterChip('مغلق', 'CLOSED'),
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
                      const StateView(
                          empty: true, emptyMessage: 'لا توجد توقعات')
                    else
                      ...data.recommendations
                          .map((rec) => _buildRecommendationCard(rec)),
                    // AI Insights
                    if (data.aiInsights != null &&
                        data.aiInsights!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const SectionHeader(
                          title: 'تحليلات AI للسوق', icon: Icons.auto_awesome),
                      const SizedBox(height: 8),
                      _buildAiInsightsCard(data.aiInsights!),
                    ],
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

  Widget _buildFilterChip(String label, String value) {
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

  Widget _buildAiInsightsCard(Map<String, dynamic> insights) {
    final summary = insights['summary']?.toString() ??
        insights['market_outlook']?.toString() ??
        '';
    final recommendations = (insights['recommendations'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        <Map<String, dynamic>>[];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('رؤية AI للسوق', style: AppTypography.titleSmall)
        ]),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(summary, style: AppTypography.bodyMedium)
        ],
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...recommendations.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('• ', style: TextStyle(color: AppColors.primary)),
                Expanded(
                    child: Text(r['title'] ?? r['ticker'] ?? r.toString(),
                        style: AppTypography.bodySmall)),
              ]))),
        ],
      ]),
    );
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
