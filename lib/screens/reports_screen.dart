// ============================================================================
// مساعد الاستثمار Flutter - Reports Screen
// Daily / weekly / monthly investment reports
// API: /api/reports/morning  (and synthesized weekly/monthly summaries)
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _reportsFuture;

  static const List<_ReportTab> _tabs = [
    _ReportTab('daily', 'يومي', Icons.today_rounded),
    _ReportTab('weekly', 'أسبوعي', Icons.date_range_rounded),
    _ReportTab('monthly', 'شهري', Icons.calendar_month_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _reportsFuture = _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchReports() async {
    return api.getMorningReports();
  }

  Future<void> _refresh() async {
    setState(() {
      _reportsFuture = _fetchReports();
    });
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
              expandedHeight: 140,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.secondary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
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
                            child: const Icon(Icons.description_rounded,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('التقارير الاستثمارية',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: 2),
                                Text('تحليلات يومية وأسبوعية وشهرية',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: AppColors.white),
                            onPressed: _refresh,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: _tabs
                      .map((t) => Tab(
                            icon: Icon(t.icon, size: 18),
                            text: t.label,
                          ))
                      .toList(),
                ),
              ),
            ),
            SliverFillRemaining(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _reportsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      children: [
                        SkeletonCard(height: 120),
                        SizedBox(height: 8),
                        SkeletonCard(height: 200),
                        SizedBox(height: 8),
                        SkeletonList(itemCount: 3, itemHeight: 80),
                      ],
                    );
                  }
                  if (snapshot.hasError) {
                    return StateView(
                        error: 'فشل تحميل التقارير', onRetry: _refresh);
                  }
                  final data = snapshot.data ?? {};
                  if (data.isEmpty) {
                    return const StateView(
                      empty: true,
                      emptyMessage: 'لا توجد تقارير متاحة حالياً',
                    );
                  }
                  final report = _ReportData.fromMap(data);
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDailyTab(report),
                      _buildWeeklyTab(report),
                      _buildMonthlyTab(report),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Daily tab
  // ===========================================================================
  Widget _buildDailyTab(_ReportData report) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeroCard(
            title: report.title ?? 'تقرير الصباح',
            subtitle: report.date,
            gradientColors: const [AppColors.primary, AppColors.primaryDark],
            icon: Icons.wb_sunny_rounded,
          ),
          const SizedBox(height: 8),
          if (report.summary != null)
            _buildSectionCard(
              title: 'ملخص اليوم',
              icon: Icons.summarize_rounded,
              child: Text(
                report.summary!,
                style: AppTypography.bodyMedium,
              ),
            ),
          if (report.marketMood != null) ...[
            const SizedBox(height: 8),
            _buildMoodCard(report.marketMood!),
          ],
          if (report.recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'توصيات اليوم',
              icon: Icons.lightbulb_outline_rounded,
              child: Column(
                children: report.recommendations
                    .map((r) => _buildRecommendationRow(r))
                    .toList(),
              ),
            ),
          ],
          if (report.events.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'أحداث وتواريخ مهمة',
              icon: Icons.event_note_rounded,
              child: Column(
                children: report.events
                    .map((e) => _buildEventRow(e))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Weekly tab
  // ===========================================================================
  Widget _buildWeeklyTab(_ReportData report) {
    final weekly = report.weekly;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeroCard(
            title: 'التقرير الأسبوعي',
            subtitle: 'أداء الأسواق خلال الأسبوع',
            gradientColors: const [AppColors.secondary, AppColors.secondaryDark],
            icon: Icons.trending_up_rounded,
          ),
          const SizedBox(height: 8),
          if (weekly.topGainers.isNotEmpty)
            _buildSectionCard(
              title: 'الأكثر ارتفاعاً',
              icon: Icons.arrow_upward_rounded,
              child: _buildMoversList(weekly.topGainers, true),
            ),
          if (weekly.topLosers.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'الأكثر انخفاضاً',
              icon: Icons.arrow_downward_rounded,
              child: _buildMoversList(weekly.topLosers, false),
            ),
          ],
          if (weekly.sectorPerformance.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'أداء القطاعات',
              icon: Icons.pie_chart_outline_rounded,
              child: _buildSectorBars(weekly.sectorPerformance),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Monthly tab
  // ===========================================================================
  Widget _buildMonthlyTab(_ReportData report) {
    final monthly = report.monthly;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeroCard(
            title: 'التقرير الشهري',
            subtitle: 'نظرة استراتيجية على الشهر',
            gradientColors: const [AppColors.accent, AppColors.accentDark],
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      'مؤشر السوق',
                      monthly.marketIndex,
                      monthly.marketChange,
                      Icons.bar_chart_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildStatCard(
                      'السيولة',
                      monthly.liquidity,
                      null,
                      Icons.water_drop_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          if (monthly.insights.isNotEmpty)
            _buildSectionCard(
              title: 'رؤى استراتيجية',
              icon: Icons.insights_rounded,
              child: Column(
                children: monthly.insights
                    .map((i) => _buildInsightRow(i))
                    .toList(),
              ),
            ),
          if (monthly.opportunities.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionCard(
              title: 'فرص الشهر القادم',
              icon: Icons.visibility_rounded,
              child: Column(
                children: monthly.opportunities
                    .map((o) => _buildRecommendationRow(o))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Card builders
  // ===========================================================================
  Widget _buildHeroCard({
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.titleSmall),
          ]),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMoodCard(String mood) {
    final isBull = mood.toLowerCase().contains('bull') ||
        mood.contains('صاعد') ||
        mood.contains('إيجاب');
    final color = isBull ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.18),
          AppColors.surface,
        ]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isBull ? Icons.trending_up : Icons.trending_down,
              color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مزاج السوق',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                Text(mood,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationRow(_Recommendation r) {
    final tone = _toneFromSignal(r.signal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              r.ticker.isNotEmpty ? r.ticker.substring(0, r.ticker.length.clamp(0, 3)) : '?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: tone,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ticker,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                if (r.note.isNotEmpty)
                  Text(r.note,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(r.signal,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tone)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(_Event e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(e.title,
                style: const TextStyle(fontSize: 13)),
          ),
          if (e.date.isNotEmpty)
            Text(e.date,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildMoversList(List<_Mover> movers, bool isGain) {
    final color = isGain ? AppColors.success : AppColors.danger;
    return Column(
      children: movers.map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(m.ticker,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  m.price.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  '${isGain ? '+' : ''}${m.change.toStringAsFixed(2)}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectorBars(Map<String, double> sectors) {
    final entries = sectors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: entries.map((e) {
        final isPos = e.value >= 0;
        final color = isPos ? AppColors.success : AppColors.danger;
        final width = (e.value.abs().clamp(0, 15) / 15).clamp(0.05, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.key,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    '${isPos ? '+' : ''}${e.value.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: width,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(
      String label, String value, String? change, IconData icon) {
    Color color = AppColors.primary;
    if (change != null) {
      final cleaned = change.replaceAll('%', '').replaceAll('+', '').trim();
      final num = double.tryParse(cleaned);
      final isPos = change.startsWith('+') || (num != null && num >= 0);
      color = isPos ? AppColors.success : AppColors.danger;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          if (change != null)
            Text(change,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String insight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(insight,
                style: const TextStyle(fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Color _toneFromSignal(String signal) {
    final s = signal.toLowerCase();
    if (s.contains('buy') || s.contains('شراء')) return AppColors.success;
    if (s.contains('sell') || s.contains('بيع')) return AppColors.danger;
    if (s.contains('hold') || s.contains('احتفاظ')) return AppColors.warning;
    return AppColors.primary;
  }
}

// ============================================================================
// Tabs
// ============================================================================
class _ReportTab {
  final String key;
  final String label;
  final IconData icon;
  const _ReportTab(this.key, this.label, this.icon);
}

// ============================================================================
// Report models
// ============================================================================
class _ReportData {
  final String? title;
  final String date;
  final String? summary;
  final String? marketMood;
  final List<_Recommendation> recommendations;
  final List<_Event> events;
  final _WeeklyData weekly;
  final _MonthlyData monthly;

  _ReportData({
    required this.title,
    required this.date,
    required this.summary,
    required this.marketMood,
    required this.recommendations,
    required this.events,
    required this.weekly,
    required this.monthly,
  });

  factory _ReportData.fromMap(Map<String, dynamic> m) {
    final data = m['data'] is Map ? Map<String, dynamic>.from(m['data']) : m;
    final title = (data['title'] ?? m['title'] ?? 'تقرير الصباح').toString();
    final date = (data['date'] ??
            data['report_date'] ??
            DateTime.now().toIso8601String().substring(0, 10))
        .toString();
    final summary =
        (data['summary'] ?? data['overview'] ?? data['description'])?.toString();
    final marketMood = (data['market_mood'] ??
            data['sentiment'] ??
            data['mood'] ??
            data['market_sentiment'])
        ?.toString();

    // Recommendations
    final rawRecs =
        data['recommendations'] ?? data['picks'] ?? data['top_picks'] ?? [];
    List<_Recommendation> recs = [];
    if (rawRecs is List) {
      for (final e in rawRecs) {
        if (e is Map) {
          final rm = Map<String, dynamic>.from(e);
          recs.add(_Recommendation(
            ticker: (rm['ticker'] ?? rm['symbol'] ?? '').toString(),
            signal: (rm['signal'] ?? rm['recommendation'] ?? 'HOLD').toString(),
            note: (rm['note'] ?? rm['reason'] ?? '').toString(),
          ));
        }
      }
    }
    // Events
    final rawEvents = data['events'] ?? data['calendar'] ?? [];
    List<_Event> events = [];
    if (rawEvents is List) {
      for (final e in rawEvents) {
        if (e is Map) {
          final em = Map<String, dynamic>.from(e);
          events.add(_Event(
            title: (em['title'] ?? em['event'] ?? '').toString(),
            date: (em['date'] ?? em['event_date'] ?? '').toString(),
          ));
        }
      }
    }
    // Weekly data
    final rawWeekly = data['weekly'] ?? data['week'] ?? <String, dynamic>{};
    final weeklyMap = rawWeekly is Map
        ? Map<String, dynamic>.from(rawWeekly)
        : <String, dynamic>{};
    final weekly = _WeeklyData.fromMap(weeklyMap, data);

    // Monthly data
    final rawMonthly = data['monthly'] ?? data['month'] ?? <String, dynamic>{};
    final monthlyMap = rawMonthly is Map
        ? Map<String, dynamic>.from(rawMonthly)
        : <String, dynamic>{};
    final monthly = _MonthlyData.fromMap(monthlyMap, data);

    return _ReportData(
      title: title,
      date: date,
      summary: summary,
      marketMood: marketMood,
      recommendations: recs,
      events: events,
      weekly: weekly,
      monthly: monthly,
    );
  }
}

class _WeeklyData {
  final List<_Mover> topGainers;
  final List<_Mover> topLosers;
  final Map<String, double> sectorPerformance;

  _WeeklyData({
    required this.topGainers,
    required this.topLosers,
    required this.sectorPerformance,
  });

  factory _WeeklyData.fromMap(Map<String, dynamic> m, Map<String, dynamic> root) {
    List<_Mover> parse(dynamic raw) {
      final list = <_Mover>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map) {
            final mm = Map<String, dynamic>.from(e);
            list.add(_Mover(
              ticker: (mm['ticker'] ?? mm['symbol'] ?? '').toString(),
              price: _toDouble(mm['price'] ?? mm['current_price']) ?? 0,
              change: _toDouble(mm['change'] ?? mm['change_percent']) ?? 0,
            ));
          }
        }
      }
      return list;
    }

    final gainers = parse(m['top_gainers'] ?? root['top_gainers'] ?? []);
    final losers = parse(m['top_losers'] ?? root['top_losers'] ?? []);
    final rawSectors = m['sector_performance'] ?? root['sectors'];
    final sectors = <String, double>{};
    if (rawSectors is Map) {
      rawSectors.forEach((k, v) {
        final d = _toDouble(v);
        if (d != null) sectors[k.toString()] = d;
      });
    } else if (rawSectors is List) {
      for (final e in rawSectors) {
        if (e is Map) {
          final sm = Map<String, dynamic>.from(e);
          final name = (sm['name'] ?? sm['sector'] ?? '').toString();
          final val = _toDouble(sm['change'] ?? sm['performance']);
          if (name.isNotEmpty && val != null) sectors[name] = val;
        }
      }
    }
    return _WeeklyData(
      topGainers: gainers,
      topLosers: losers,
      sectorPerformance: sectors,
    );
  }
}

class _MonthlyData {
  final String marketIndex;
  final String marketChange;
  final String liquidity;
  final List<String> insights;
  final List<_Recommendation> opportunities;

  _MonthlyData({
    required this.marketIndex,
    required this.marketChange,
    required this.liquidity,
    required this.insights,
    required this.opportunities,
  });

  factory _MonthlyData.fromMap(Map<String, dynamic> m, Map<String, dynamic> root) {
    final marketIndex = (m['market_index'] ??
            root['market_index'] ??
            root['index_value'] ??
            '--')
        .toString();
    final marketChange = (m['market_change'] ??
            root['market_change'] ??
            root['index_change'] ??
            '')
        .toString();
    final liquidity = (m['liquidity'] ??
            root['liquidity'] ??
            root['volume'] ??
            '--')
        .toString();
    final rawInsights = m['insights'] ?? root['insights'] ?? [];
    List<String> insights = [];
    if (rawInsights is List) {
      insights = rawInsights.map((e) => e.toString()).toList();
    }
    final rawOpps = m['opportunities'] ?? root['opportunities'] ?? [];
    List<_Recommendation> opportunities = [];
    if (rawOpps is List) {
      for (final e in rawOpps) {
        if (e is Map) {
          final om = Map<String, dynamic>.from(e);
          opportunities.add(_Recommendation(
            ticker: (om['ticker'] ?? om['symbol'] ?? '').toString(),
            signal: (om['signal'] ?? om['recommendation'] ?? 'HOLD').toString(),
            note: (om['note'] ?? om['reason'] ?? '').toString(),
          ));
        }
      }
    }
    return _MonthlyData(
      marketIndex: marketIndex,
      marketChange: marketChange,
      liquidity: liquidity,
      insights: insights,
      opportunities: opportunities,
    );
  }
}

class _Recommendation {
  final String ticker;
  final String signal;
  final String note;
  const _Recommendation({
    required this.ticker,
    required this.signal,
    required this.note,
  });
}

class _Event {
  final String title;
  final String date;
  const _Event({required this.title, required this.date});
}

class _Mover {
  final String ticker;
  final double price;
  final double change;
  const _Mover({
    required this.ticker,
    required this.price,
    required this.change,
  });
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
