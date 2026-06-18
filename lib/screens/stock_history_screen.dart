// ============================================================================
// مساعد الاستثمار Flutter - Stock History Screen
// Shows stock detail, price history, AI recommendation, professional analysis
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/json_helpers.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class StockHistoryScreen extends StatefulWidget {
  final String ticker;
  const StockHistoryScreen({super.key, required this.ticker});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>>? _allDataFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  void _refreshData() {
    _allDataFuture = _loadAllFutures();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadAllFutures() async {
    final results = await Future.wait([
      api.getStockHistory(widget.ticker, days: 30).catchError((e) {
        debugPrint('Error getting stock history: $e');
        return StockHistoryResponse(data: [], summary: null);
      }),
      api.getStockDetail(widget.ticker, flat: true).then((dynamic response) {
        if (response is Map) {
          return Stock.fromJson(Map<String, dynamic>.from(response));
        }
        return Stock(ticker: widget.ticker);
      }).catchError((e) {
        debugPrint('Error getting stock detail: $e');
        return Stock(ticker: widget.ticker);
      }),
      api.getStockFundamentals(ticker: widget.ticker).then((dynamic response) {
        if (response is Map) {
          return Map<String, dynamic>.from(response);
        }
        return <String, dynamic>{};
      }).catchError((e) {
        debugPrint('Error getting stock fundamentals: $e');
        return <String, dynamic>{};
      }),
      api.getStockNews(widget.ticker).then((dynamic response) {
        if (response is Map) {
          final newsList = response['news'];
          if (newsList is List) {
            return newsList
                .map((e) => e is Map ? Map<String, dynamic>.from(e) : null)
                .where((e) => e != null)
                .cast<Map<String, dynamic>>()
                .toList();
          }
        }
        return <Map<String, dynamic>>[];
      }).catchError((e) {
        debugPrint('Error getting stock news: $e');
        return <Map<String, dynamic>>[];
      }),
    ]);

    final historyResponse = results[0] as StockHistoryResponse?;
    final stockDetail = results[1] as Stock?;
    final fundamentals = results[2] as Map<String, dynamic>?;
    final news = results[3] as List<Map<String, dynamic>>?;

    final accessResults = await Future.wait([
      SubscriptionService.instance.checkAccess('recommendations'),
      SubscriptionService.instance.checkAccess('ai_analysis'),
    ]);
    final recAccess = accessResults[0];
    final anaAccess = accessResults[1];

    final recommendation = recAccess.hasAccess
        ? await api.getStockRecommendation(widget.ticker).then((dynamic response) {
            if (response is Map) {
              return Map<String, dynamic>.from(response);
            }
            return <String, dynamic>{};
          }).catchError((e) {
            debugPrint('Error getting stock recommendation: $e');
            return <String, dynamic>{};
          })
        : null;

    final analysis = anaAccess.hasAccess
        ? await api.getStockProfessionalAnalysis(widget.ticker).then((dynamic response) {
            if (response is Map) {
              return Map<String, dynamic>.from(response);
            }
            return <String, dynamic>{};
          }).catchError((e) {
            debugPrint('Error getting stock analysis: $e');
            return <String, dynamic>{};
          })
        : null;

    return {
      'history': historyResponse,
      'stock': stockDetail,
      'fundamentals': fundamentals,
      'news': news ?? <Map<String, dynamic>>[],
      'recommendation': recommendation,
      'analysis': analysis,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
          title: FutureBuilder<Map<String, dynamic>>(
            future: _allDataFuture,
            builder: (context, snapshot) {
              final stock = snapshot.data?['stock'] as Stock?;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock?.nameAr ?? stock?.name ?? widget.ticker),
                  if (stock?.ticker != null &&
                      stock?.ticker != (stock?.nameAr ?? stock?.name))
                    Text(
                      stock!.ticker,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.8)),
                    ),
                ],
              );
            },
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _allDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError) {
              return StateView(
                  error: snapshot.error.toString(),
                  onRetry: () => setState(() {
                        _refreshData();
                      }));
            }

            final data = snapshot.data!;
            final historyData = data['history'] as StockHistoryResponse?;
            final stock = data['stock'] as Stock?;

            return Column(
              children: [
                // Stock price header
                _buildPriceHeader(historyData, stock),
                // Tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: AppColors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'البيانات'),
                      Tab(text: 'التوصية'),
                      Tab(text: 'تحليل'),
                      Tab(text: 'أخبار'),
                    ],
                  ),
                ),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHistoryTab(historyData, stock),
                      _buildRecommendationTab(
                          data['recommendation'] is Map ? Map<String, dynamic>.from(data['recommendation'] as Map) : null),
                      _buildAnalysisTab(
                          data['analysis'] is Map ? Map<String, dynamic>.from(data['analysis'] as Map) : null),
                      _buildNewsTab(
                          data['fundamentals'] is Map ? Map<String, dynamic>.from(data['fundamentals'] as Map) : null,
                          data['news'] is List
                              ? (data['news'] as List).cast<Map<String, dynamic>>()
                              : <Map<String, dynamic>>[]),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPriceHeader(StockHistoryResponse? historyData, Stock? stock) {
    final summary = historyData?.summary;
    final changePercent = summary?.changePercent ?? stock?.changePercent ?? 0;
    final isPositive = changePercent >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          isPositive ? AppColors.success : AppColors.danger,
          isPositive
              ? AppColors.success.withValues(alpha: 0.8)
              : AppColors.danger.withValues(alpha: 0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            stock?.currentPrice?.toStringAsFixed(2) ?? '-',
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.white),
          ),
          Text('ج.م',
              style: TextStyle(
                  fontSize: 14, color: AppColors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                  color: AppColors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (stock?.sector != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(stock!.sector!,
                  style: const TextStyle(fontSize: 11, color: AppColors.white)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(StockHistoryResponse? historyData, Stock? stock) {
    if (historyData == null) {
      return const Center(child: Text('لا توجد بيانات متاحة'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (historyData.summary != null) ...[
            _buildSummaryGrid(historyData.summary!),
            const SizedBox(height: 16),
          ],
          if (stock != null) ...[
            const SectionHeader(
                title: 'معلومات السهم', icon: Icons.info_outline),
            const SizedBox(height: 8),
            _buildStockInfoGrid(stock),
            const SizedBox(height: 16),
          ],
          if (historyData.data.isNotEmpty) ...[
            const SectionHeader(
                title: 'البيانات التاريخية - آخر 30 يوم',
                icon: Icons.calendar_today),
            const SizedBox(height: 8),
            _buildPriceChart(historyData.data),
            const SizedBox(height: 16),
          ],
          if (historyData.data.isEmpty)
            const StateView(
                empty: true,
                emptyMessage: 'لا توجد بيانات تاريخية كافية للعرض'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRecommendationTab(Map<String, dynamic>? rec) {
    final sub = SubscriptionService.instance;
    if (!sub.hasAccess('recommendations')) {
      return _buildLockedTab('recommendations');
    }
    if (rec == null || rec.isEmpty) {
      return const Center(
          child: StateView(
              empty: true, emptyMessage: 'لا توجد توصية متاحة لهذا السهم'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildRecommendationContent(rec),
    );
  }

  Widget _buildRecommendationContent(Map<String, dynamic> rec) {
    final rawRecommendation = rec['recommendation'];
    final Map<String, dynamic>? recommendation = (rawRecommendation is Map)
        ? Map<String, dynamic>.from(rawRecommendation)
        : null;
    final action = parseString(recommendation?['action']) ?? '';
    final actionAr = parseString(recommendation?['action_ar']) ?? '';
    final confidence = parseDouble(recommendation?['confidence']) ?? 0;
    
    final rawScores = rec['scores'];
    final Map<String, dynamic>? scores = (rawScores is Map)
        ? Map<String, dynamic>.from(rawScores)
        : null;
    final totalScore = parseDouble(scores?['total_score']);
    
    final rawStrengths = rec['key_strengths'];
    final List keyStrengths = rawStrengths is List ? rawStrengths : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (action.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getActionColor(action).withValues(alpha: 0.8),
                _getActionColor(action)
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getActionIcon(action),
                        color: AppColors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      actionAr.isNotEmpty ? actionAr : _getActionAr(action),
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('مستوى الثقة: ${confidence.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (totalScore != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getScoreColor(totalScore).withValues(alpha: 0.8),
                _getScoreColor(totalScore)
              ]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('النتيجة الإجمالية',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.white)),
                      Text('${totalScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        if (keyStrengths.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.thumb_up, size: 18, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('نقاط القوة', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                ...keyStrengths.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✓ ',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.success)),
                          Expanded(
                              child: Text(s['title_ar'] ?? s['title'] ?? '',
                                  style: AppTypography.bodyMedium)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAnalysisTab(Map<String, dynamic>? analysis) {
    final sub = SubscriptionService.instance;
    if (!sub.hasAccess('ai_analysis')) {
      return _buildLockedTab('ai_analysis');
    }
    if (analysis == null || analysis.isEmpty) {
      return const Center(
          child: StateView(
              empty: true,
              emptyMessage: 'لا يوجد تحليل احترافي متاح لهذا السهم'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildAnalysisContent(analysis),
    );
  }

  Widget _buildAnalysisContent(Map<String, dynamic> analysis) {
    final rawAnalysis = analysis['analysis'];
    final Map<String, dynamic> data = (rawAnalysis is Map)
        ? Map<String, dynamic>.from(rawAnalysis)
        : analysis;
    final rawScores = data['scores'];
    final Map<String, dynamic>? scores = (rawScores is Map)
        ? Map<String, dynamic>.from(rawScores)
        : null;
    final compositeScore = parseDouble(scores?['composite']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compositeScore != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getScoreColor(compositeScore).withValues(alpha: 0.8),
                _getScoreColor(compositeScore)
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.analytics,
                      color: AppColors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('النتيجة المركبة',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.white)),
                      Text('${compositeScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildNewsTab(
      Map<String, dynamic>? fundamentals, List<Map<String, dynamic>> news) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fundamentals != null) ...[
            const SectionHeader(
                title: 'البيانات الأساسية', icon: Icons.analytics),
            const SizedBox(height: 8),
            _buildFundamentalsCard(fundamentals),
            const SizedBox(height: 16),
          ],
          if (news.isEmpty)
            const StateView(
                empty: true, emptyMessage: 'لا توجد أخبار متاحة لهذا السهم')
          else ...[
            const SectionHeader(title: 'آخر الأخبار', icon: Icons.newspaper),
            const SizedBox(height: 8),
            ...news.map((n) => _buildNewsCard(n)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFundamentalsCard(Map<String, dynamic> f) {
    final fields = <MapEntry<String, String>>[];
    final rawFundamentals = f['fundamentals'];
    final Map<String, dynamic> entries = (rawFundamentals is Map)
        ? Map<String, dynamic>.from(rawFundamentals)
        : f;
    for (final e in entries.entries) {
      if (e.value != null && e.value is! Map && e.value is! List) {
        fields.add(MapEntry(e.key, e.value.toString()));
      }
    }
    if (fields.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('البيانات الأساسية', style: AppTypography.titleSmall),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fields
                .map((e) => _buildSummaryCard(
                      _fundamentalLabel(e.key),
                      e.value.length > 20
                          ? '${e.value.substring(0, 20)}...'
                          : e.value,
                      AppColors.info,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _fundamentalLabel(String key) {
    const labels = {
      'pe_ratio': 'P/E',
      'eps': 'EPS',
      'market_cap': 'القيمة السوقية',
      'dividend_yield': 'عائد التوزيعات',
      'book_value': 'القيمة الدفترية',
      'roe': 'ROE',
      'debt_to_equity': 'الدين/الحقوق',
    };
    return labels[key] ?? key;
  }

  Widget _buildNewsCard(Map<String, dynamic> n) {
    final title = n['title'] ?? n['title_ar'] ?? '';
    final source = n['source'] ?? '';
    final date = n['date'] ?? n['published_at'] ?? '';
    final url = n['url'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: InkWell(
        onTap: url.isNotEmpty
            ? () => Navigator.pushNamed(context, '/webview', arguments: url)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTypography.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (source.isNotEmpty || date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                if (source.isNotEmpty) ...[
                  const Icon(Icons.source,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(source,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
                if (date.isNotEmpty) ...[
                  const Spacer(),
                  Text(
                      date.toString().length > 10
                          ? date.toString().substring(0, 10)
                          : date.toString(),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.headline4.copyWith(color: color)),
      ]),
    );
  }

  Widget _buildSummaryGrid(StockHistorySummary s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSummaryCard('أعلى سعر', s.highest?.toStringAsFixed(2) ?? '-',
            AppColors.success),
        _buildSummaryCard(
            'أدنى سعر', s.lowest?.toStringAsFixed(2) ?? '-', AppColors.danger),
        _buildSummaryCard('متوسط السعر', s.avgPrice?.toStringAsFixed(2) ?? '-',
            AppColors.info),
        _buildSummaryCard(
            'التغير %',
            '${(s.changePercent ?? 0) >= 0 ? '+' : ''}${s.changePercent?.toStringAsFixed(2) ?? '-'}%',
            (s.changePercent ?? 0) >= 0 ? AppColors.success : AppColors.danger),
      ],
    );
  }

  Widget _buildStockInfoGrid(Stock s) {
    final items = <Widget>[];
    if (s.previousClose != null) {
      items.add(_buildSummaryCard('الإغلاق السابق',
          s.previousClose!.toStringAsFixed(2), AppColors.textSecondary));
    }
    if (s.openPrice != null) {
      items.add(_buildSummaryCard(
          'الافتتاح', s.openPrice!.toStringAsFixed(2), AppColors.info));
    }
    if (s.highPrice != null) {
      items.add(_buildSummaryCard(
          'الأعلى', s.highPrice!.toStringAsFixed(2), AppColors.success));
    }
    if (s.lowPrice != null) {
      items.add(_buildSummaryCard(
          'الأدنى', s.lowPrice!.toStringAsFixed(2), AppColors.danger));
    }
    if (s.volume != null) {
      items.add(
          _buildSummaryCard('الحجم', '${s.volume}', AppColors.textSecondary));
    }
    if (s.peRatio != null) {
      items.add(_buildSummaryCard(
          'P/E', s.peRatio!.toStringAsFixed(2), AppColors.info));
    }
    if (s.marketCap != null) {
      items.add(_buildSummaryCard('القيمة السوقية',
          '${(s.marketCap! / 1e9).toStringAsFixed(2)} B', AppColors.primary));
    }

    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }

  Widget _buildPriceChart(List<StockHistory> data) {
    final closes = data.map((d) => d.close ?? 0).where((c) => c > 0).toList();
    if (closes.isEmpty) return const SizedBox.shrink();

    final isUp = closes.last >= closes.first;
    final color = isUp ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          size: Size.infinite,
          painter: _StockLineChartPainter(prices: closes, color: color),
        ),
      ),
    );
  }

  Widget _buildLockedTab(String feature) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              feature == 'recommendations'
                  ? 'التوصيات ميزة مدفوعة'
                  : 'التحليل الاحترافي ميزة مدفوعة',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'قم بالترقية إلى بلس للوصول إلى ${feature == 'recommendations' ? 'التوصيات الاحترافية' : 'التحليل المتقدم'}',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => UpgradeModal.show(context, feature: feature),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ترقية الآن',
                  style: TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    final a = action.toUpperCase();
    if (a.contains('BUY') || a == 'شراء') return AppColors.success;
    if (a.contains('SELL') || a == 'بيع') return AppColors.danger;
    if (a.contains('HOLD') || a == 'احتفاظ') return AppColors.warning;
    return AppColors.info;
  }

  IconData _getActionIcon(String action) {
    final a = action.toUpperCase();
    if (a.contains('BUY') || a == 'شراء') return Icons.trending_up;
    if (a.contains('SELL') || a == 'بيع') return Icons.trending_down;
    return Icons.remove;
  }

  String _getActionAr(String action) {
    final a = action.toUpperCase();
    if (a.contains('STRONG_BUY')) return 'شراء قوي';
    if (a.contains('BUY')) return 'شراء';
    if (a.contains('STRONG_SELL')) return 'بيع قوي';
    if (a.contains('SELL')) return 'بيع';
    if (a.contains('HOLD')) return 'احتفاظ';
    if (a == 'ACCUMULATE') return 'تراكم';
    return action;
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }
}

class _StockLineChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _StockLineChartPainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    const padding = 10.0;

    final points = <Offset>[];
    for (int i = 0; i < prices.length; i++) {
      final x = padding +
          (i / (prices.length - 1).clamp(1, prices.length)) *
              (size.width - padding * 2);
      final y = size.height -
          padding -
          ((prices[i] - min) / range) * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(points.first, 4, dotPaint);
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
