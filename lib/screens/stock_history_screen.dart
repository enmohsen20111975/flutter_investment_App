// ============================================================================
// مساعد الاستثمار Flutter - Stock History Screen
// Shows stock detail, price history, AI recommendation, professional analysis
// Uses: GET /api/stocks/:ticker, GET /api/stocks/:ticker/history,
//       GET /api/stocks/:ticker/recommendation, GET /api/stocks/:ticker/professional-analysis
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/json_helpers.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class StockHistoryScreen extends StatefulWidget {
  final String ticker;
  const StockHistoryScreen({super.key, required this.ticker});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  StockHistoryResponse? _historyData;
  Stock? _stockDetail;
  Map<String, dynamic>? _recommendation;
  Map<String, dynamic>? _professionalAnalysis;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) if (mounted) setState(() { _loading = true; _error = null; });

      // Load all data in parallel
      await Future.wait([
        _loadHistory(),
        _loadStockDetail(),
        _loadRecommendation(),
        _loadProfessionalAnalysis(),
      ]);

      if (mounted) setState(() { _loading = false; _refreshing = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
    }
  }

  Future<void> _loadHistory() async {
    try {
      _historyData = await api.getStockHistory(widget.ticker, 30);
    } catch (_) {}
  }

  Future<void> _loadStockDetail() async {
    try {
      final response = await api.getStockDetail(widget.ticker, flat: true);
      _stockDetail = Stock.fromJson(response);
    } catch (_) {}
  }

  Future<void> _loadRecommendation() async {
    try {
      _recommendation = await api.getStockRecommendation(widget.ticker);
    } catch (_) {}
  }

  Future<void> _loadProfessionalAnalysis() async {
    try {
      _professionalAnalysis = await api.getStockProfessionalAnalysis(widget.ticker);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_stockDetail?.nameAr ?? _stockDetail?.name ?? widget.ticker),
              if ((_stockDetail?.ticker ?? widget.ticker) != (_stockDetail?.nameAr ?? _stockDetail?.name ?? ''))
                Text(
                  _stockDetail?.ticker ?? widget.ticker,
                  style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8)),
                ),
            ],
          ),
        ),
        body: _loading
            ? const StateView(loading: true)
            : _error != null
                ? StateView(error: _error, onRetry: () => _loadData())
                : Column(
                    children: [
                      // Stock price header
                      _buildPriceHeader(),
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
                          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          tabs: const [
                            Tab(text: 'البيانات'),
                            Tab(text: 'التوصية'),
                            Tab(text: 'تحليل'),
                          ],
                        ),
                      ),
                      // Tab content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildHistoryTab(),
                            _buildRecommendationTab(),
                            _buildAnalysisTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPriceHeader() {
    final stock = _stockDetail;
    final summary = _historyData?.summary;
    final changePercent = summary?.changePercent ?? stock?.changePercent ?? 0;
    final isPositive = changePercent >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          isPositive ? AppColors.success : AppColors.danger,
          isPositive ? AppColors.success.withValues(alpha: 0.8) : AppColors.danger.withValues(alpha: 0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            stock?.currentPrice?.toStringAsFixed(2) ?? '-',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white),
          ),
          Text('ج.م', style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPositive ? Icons.trending_up : Icons.trending_down, color: AppColors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                style: const TextStyle(fontSize: 16, color: AppColors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (stock?.sector != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(stock!.sector!, style: const TextStyle(fontSize: 11, color: AppColors.white)),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 1: Price History Data
  // ===========================================================================
  Widget _buildHistoryTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            if (_historyData?.summary != null) ...[
              _buildSummaryGrid(),
              const SizedBox(height: 16),
            ],
            // Stock detail info
            if (_stockDetail != null) ...[
              const SectionHeader(title: 'معلومات السهم', icon: Icons.info_outline),
              const SizedBox(height: 8),
              _buildStockInfoGrid(),
              const SizedBox(height: 16),
            ],
            // Price history chart
            if (_historyData?.data != null && _historyData!.data.isNotEmpty) ...[
              const SectionHeader(title: 'البيانات التاريخية - آخر 30 يوم', icon: Icons.calendar_today),
              const SizedBox(height: 8),
              _buildPriceChart(),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            if (_historyData?.data == null || _historyData!.data.isEmpty)
              const StateView(empty: true, emptyMessage: 'لا توجد بيانات تاريخية كافية للعرض'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    final s = _historyData!.summary!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildSummaryCard('أعلى سعر', s.highest?.toStringAsFixed(2) ?? '-', AppColors.success),
        _buildSummaryCard('أدنى سعر', s.lowest?.toStringAsFixed(2) ?? '-', AppColors.danger),
        _buildSummaryCard('متوسط السعر', s.avgPrice?.toStringAsFixed(2) ?? '-', AppColors.info),
        _buildSummaryCard('التغير %', '${(s.changePercent ?? 0) >= 0 ? '+' : ''}${s.changePercent?.toStringAsFixed(2) ?? '-'}%', (s.changePercent ?? 0) >= 0 ? AppColors.success : AppColors.danger),
      ],
    );
  }

  Widget _buildStockInfoGrid() {
    final s = _stockDetail!;
    final items = <Widget>[];
    if (s.previousClose != null) items.add(_buildSummaryCard('الإغلاق السابق', s.previousClose!.toStringAsFixed(2), AppColors.textSecondary));
    if (s.openPrice != null) items.add(_buildSummaryCard('الافتتاح', s.openPrice!.toStringAsFixed(2), AppColors.info));
    if (s.highPrice != null) items.add(_buildSummaryCard('الأعلى', s.highPrice!.toStringAsFixed(2), AppColors.success));
    if (s.lowPrice != null) items.add(_buildSummaryCard('الأدنى', s.lowPrice!.toStringAsFixed(2), AppColors.danger));
    if (s.volume != null) items.add(_buildSummaryCard('الحجم', '${s.volume}', AppColors.textSecondary));
    if (s.peRatio != null) items.add(_buildSummaryCard('P/E', s.peRatio!.toStringAsFixed(2), AppColors.info));
    if (s.marketCap != null) items.add(_buildSummaryCard('القيمة السوقية', '${(s.marketCap! / 1e9).toStringAsFixed(2)} B', AppColors.primary));
    if (s.rsi != null) items.add(_buildSummaryCard('RSI', s.rsi!.toStringAsFixed(1), s.rsi! > 70 ? AppColors.danger : s.rsi! < 30 ? AppColors.success : AppColors.info));

    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }

  Widget _buildPriceChart() {
    final data = _historyData!.data;
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

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border(left: BorderSide(color: color, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.headline4.copyWith(color: color)),
      ]),
    );
  }

  Widget _buildDayCard(StockHistory day, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Row(children: [
            Text(day.date, style: AppTypography.titleSmall),
            const Spacer(),
            if (day.rsi != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: day.rsi! > 70 ? AppColors.dangerLight : day.rsi! < 30 ? AppColors.successLight : AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                child: Text('RSI ${day.rsi!.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: day.rsi! > 70 ? AppColors.danger : day.rsi! < 30 ? AppColors.success : AppColors.textSecondary)),
              ),
          ]),
          const Divider(height: 16),
          Row(
            children: [
              _buildDayValue('الافتتاح', day.open?.toStringAsFixed(2) ?? '-'),
              _buildDayValue('الأعلى', day.high?.toStringAsFixed(2) ?? '-'),
              _buildDayValue('الأدنى', day.low?.toStringAsFixed(2) ?? '-'),
              _buildDayValue('الإغلاق', day.close?.toStringAsFixed(2) ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayValue(String label, String value) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: AppTypography.bodySmall), Text(value, style: AppTypography.titleSmall)]));
  }

  // ===========================================================================
  // Tab 2: Recommendation
  // ===========================================================================
  Widget _buildRecommendationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_recommendation == null)
            const StateView(empty: true, emptyMessage: 'لا توجد توصية متاحة لهذا السهم')
          else ...[
            _buildRecommendationCard(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final rec = _recommendation!;

    // Extract recommendation data
    final recommendation = rec['recommendation'] as Map<String, dynamic>?;
    final action = parseString(recommendation?['action']) ?? '';
    final actionAr = parseString(recommendation?['action_ar']) ?? '';
    final confidence = parseDouble(recommendation?['confidence']) ?? 0;

    // Extract scores
    final scores = rec['scores'] as Map<String, dynamic>?;
    final totalScore = parseDouble(scores?['total_score']);
    final technicalScore = parseDouble(scores?['technical_score']);
    final fundamentalScore = parseDouble(scores?['fundamental_score']);
    final momentumScore = parseDouble(scores?['momentum_score']);
    final riskScore = parseDouble(scores?['risk_score']);
    final riskAdjustedScore = parseDouble(scores?['risk_adjusted_score']);
    final marketContextScore = parseDouble(scores?['market_context_score']);
    final consensusRatio = parseDouble(scores?['consensus_ratio']);

    // Extract trend
    final trend = rec['trend'] as Map<String, dynamic>?;
    final trendDirection = parseString(trend?['direction_ar']) ?? '';

    // Extract price range
    final priceRange = rec['price_range'] as Map<String, dynamic>?;
    final support = parseDouble(priceRange?['support']);
    final resistance = parseDouble(priceRange?['resistance']);
    final targetPrice = parseDouble(rec['target_price']);

    // Extract strengths and risks
    final keyStrengths = (rec['key_strengths'] as List?) ?? [];
    final keyRisks = (rec['key_risks'] as List?) ?? [];
    final note = parseString(rec['note']) ?? '';

    // Extract professional analysis from recommendation
    final profAnalysis = rec['professional_analysis'] as Map<String, dynamic>?;

    final actionColor = _getActionColor(action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Action Card
        if (action.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [actionColor.withValues(alpha: 0.8), actionColor]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getActionIcon(action), color: AppColors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      actionAr.isNotEmpty ? actionAr : _getActionAr(action),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('مستوى الثقة: ${confidence.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.9))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (targetPrice != null) ...[
                      _buildRecPriceBadge('السعر المستهدف', targetPrice, AppColors.white),
                      const SizedBox(width: 12),
                    ],
                    if (support != null) ...[
                      _buildRecPriceBadge('الدعم', support, AppColors.white),
                      const SizedBox(width: 12),
                    ],
                    if (resistance != null)
                      _buildRecPriceBadge('المقاومة', resistance, AppColors.white),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Trend Card
        if (trendDirection.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(
                  trendDirection.contains('صاعد') || trendDirection.contains('bullish') || trendDirection.contains('هبوطي') ?
                      (trendDirection.contains('هبوطي') ? Icons.trending_down : Icons.trending_up) : Icons.trending_down,
                  color: trendDirection.contains('صاعد') || trendDirection.contains('bullish') ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الاتجاه: $trendDirection', style: AppTypography.titleSmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Total Score Card
        if (totalScore != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_getScoreColor(totalScore).withValues(alpha: 0.8), _getScoreColor(totalScore)]),
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
                      const Text('النتيجة الإجمالية', style: TextStyle(fontSize: 12, color: AppColors.white)),
                      Text('${totalScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Scores Grid
        if (technicalScore != null || fundamentalScore != null || momentumScore != null || riskScore != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('النتائج التفصيلية', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (technicalScore != null) _buildScoreCard('الفني', technicalScore),
                    if (fundamentalScore != null) _buildScoreCard('الأساسي', fundamentalScore),
                    if (momentumScore != null) _buildScoreCard('الزخم', momentumScore),
                    if (riskScore != null) _buildScoreCard('المخاطر', riskScore),
                    if (riskAdjustedScore != null) _buildScoreCard('المعدل', riskAdjustedScore),
                    if (marketContextScore != null) _buildScoreCard('السياق', marketContextScore),
                    if (consensusRatio != null) _buildScoreCard('الإجماع', consensusRatio),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Key Strengths
        if (keyStrengths.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.thumb_up, size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text('نقاط القوة', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                ...keyStrengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✓ ', style: TextStyle(fontSize: 14, color: AppColors.success)),
                      Expanded(child: Text(s['title_ar'] ?? s['title'] ?? '', style: AppTypography.bodyMedium)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Key Risks
        if (keyRisks.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.warning, size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Text('المخاطر', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                ...keyRisks.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠ ', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                      Expanded(child: Text(r['title_ar'] ?? r['title'] ?? '', style: AppTypography.bodyMedium)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Note
        if (note.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(note, style: AppTypography.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Professional Analysis Preview (if available)
        if (profAnalysis != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.analytics, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('تحليل احترافي متوفر', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 8),
                Text('انتقل إلى تبويب "تحليل" لعرض التفاصيل الكاملة', style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecPriceBadge(String label, double price, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text('${price.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildScoreCard(String label, double score) {
    final color = _getScoreColor(score);
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text('${score.toStringAsFixed(0)}%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Professional Analysis
  // ===========================================================================
  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_professionalAnalysis == null)
            const StateView(empty: true, emptyMessage: 'لا يوجد تحليل احترافي متاح لهذا السهم')
          else ...[
            _buildAnalysisCard(),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    final analysis = _professionalAnalysis!;
    
    // The API response structure is: { success, ticker, stock, analysis: {...}, ai_insight, data_available, ... }
    // All analysis data is inside the 'analysis' key
    final data = analysis['analysis'] as Map<String, dynamic>? ?? analysis;

    // Extract scores
    final scores = data['scores'] as Map<String, dynamic>?;
    final compositeScore = parseDouble(scores?['composite']);
    final technicalScore = parseDouble(scores?['technical']);
    final valueScore = parseDouble(scores?['value']);
    final qualityScore = parseDouble(scores?['quality']);
    final momentumScore = parseDouble(scores?['momentum']);
    final riskScore = parseDouble(scores?['risk']);

    // Extract recommendation
    final recommendation = data['recommendation'] as Map<String, dynamic>?;
    final action = parseString(recommendation?['action']) ?? '';
    final actionAr = parseString(recommendation?['action_ar']) ?? '';
    final confidence = parseDouble(recommendation?['confidence']) ?? 0;
    final entryPrice = parseDouble(recommendation?['entry_price']);
    final targetPrice = parseDouble(recommendation?['target_price']);
    final stopLoss = parseDouble(recommendation?['stop_loss']);
    final riskRewardRatio = parseDouble(recommendation?['risk_reward_ratio']);
    final timeHorizon = parseString(recommendation?['time_horizon_ar']) ?? '';
    final summaryAr = parseString(recommendation?['summary_ar']) ?? '';

    // Extract trend
    final trend = data['trend'] as Map<String, dynamic>?;
    final trendDirection = parseString(trend?['direction_ar']) ?? '';
    final trendStrength = parseString(trend?['strength_ar']) ?? '';

    // Extract indicators
    final indicators = data['indicators'] as Map<String, dynamic>?;
    final rsi = indicators?['rsi'] as Map<String, dynamic>?;
    final macd = indicators?['macd'] as Map<String, dynamic>?;
    final bollinger = indicators?['bollinger'] as Map<String, dynamic>?;
    final stochRsi = indicators?['stochastic_rsi'] as Map<String, dynamic>?;
    final roc = indicators?['roc'] as Map<String, dynamic>?;
    final atr = parseDouble(indicators?['atr']);
    final atrPercent = parseDouble(indicators?['atr_percent']);
    final obv = indicators?['obv'];
    final obvTrend = parseString(indicators?['obv_trend']) ?? '';
    final vwap = parseDouble(indicators?['vwap']);

    // Extract patterns
    final patterns = data['patterns'] as Map<String, dynamic>?;
    final detectedPatterns = (patterns?['detected'] as List?) ?? [];
    final maCross = parseString(patterns?['ma_cross']) ?? '';

    // Extract price levels
    final priceLevels = data['price_levels'] as Map<String, dynamic>?;
    final support1 = parseDouble(priceLevels?['support_1']);
    final support2 = parseDouble(priceLevels?['support_2']);
    final resistance1 = parseDouble(priceLevels?['resistance_1']);
    final resistance2 = parseDouble(priceLevels?['resistance_2']);
    final pivot = parseDouble(priceLevels?['pivot']);

    // Extract risk metrics
    final riskMetrics = data['risk_metrics'] as Map<String, dynamic>?;
    final sharpeRatio = parseDouble(riskMetrics?['sharpe_ratio']);
    final maxDrawdown = parseDouble(riskMetrics?['max_drawdown_percent']);
    final volatility = parseDouble(riskMetrics?['volatility_annualized']);
    final beta = parseDouble(riskMetrics?['beta']);

    // Extract volume analysis
    final volumeAnalysis = data['volume_analysis'] as Map<String, dynamic>?;
    final volumeSignal = parseString(volumeAnalysis?['signal_ar']) ?? '';

    // Extract data quality
    final dataQuality = data['data_quality'] as Map<String, dynamic>?;
    final historyPoints = parseInt(dataQuality?['history_points']);
    final quality = parseString(dataQuality?['quality']) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Composite Score Card
        if (compositeScore != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                _getScoreColor(compositeScore).withValues(alpha: 0.8),
                _getScoreColor(compositeScore),
              ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.analytics, color: AppColors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('النتيجة المركبة', style: TextStyle(fontSize: 12, color: AppColors.white)),
                      Text('${compositeScore.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Recommendation Card
        if (recommendation != null && action.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getActionColor(action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getActionColor(action).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getActionIcon(action), color: _getActionColor(action), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(actionAr.isNotEmpty ? actionAr : _getActionAr(action),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _getActionColor(action))),
                          Text('مستوى الثقة: ${confidence.toStringAsFixed(0)}% • $timeHorizon',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                if (summaryAr.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                    child: Text(summaryAr, style: AppTypography.bodyMedium),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (entryPrice != null) _buildPriceBadge('الدخول', entryPrice, AppColors.info),
                    if (targetPrice != null) _buildPriceBadge('الهدف', targetPrice, AppColors.success),
                    if (stopLoss != null) _buildPriceBadge('وقف الخسارة', stopLoss, AppColors.danger),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Trend Card
        if (trendDirection.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(
                  trendDirection.contains('صاعد') || trendDirection.contains('bullish') ? Icons.trending_up : Icons.trending_down,
                  color: trendDirection.contains('صاعد') || trendDirection.contains('bullish') ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الاتجاه: $trendDirection', style: AppTypography.titleSmall),
                      if (trendStrength.isNotEmpty) Text('القوة: $trendStrength', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Score Bars
        if (technicalScore != null || valueScore != null || qualityScore != null || momentumScore != null || riskScore != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('النتائج التفصيلية', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 12),
                if (technicalScore != null) ...[_buildScoreBar('الفني', technicalScore), const SizedBox(height: 8)],
                if (valueScore != null) ...[_buildScoreBar('القيمة', valueScore), const SizedBox(height: 8)],
                if (qualityScore != null) ...[_buildScoreBar('الجودة', qualityScore), const SizedBox(height: 8)],
                if (momentumScore != null) ...[_buildScoreBar('الزخم', momentumScore), const SizedBox(height: 8)],
                if (riskScore != null) _buildScoreBar('المخاطر', riskScore),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Technical Indicators
        if (indicators != null) ...[
          const SectionHeader(title: 'المؤشرات الفنية', icon: Icons.analytics),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // RSI
              if (rsi != null) _buildIndicatorCard(
                'RSI',
                '${(rsi['value'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '-'}',
                parseString(rsi['signal']) ?? '',
                _getRsiColor(parseDouble(rsi['value'])),
              ),
              // MACD
              if (macd != null) _buildIndicatorCard(
                'MACD',
                '${(macd['line'] as num?)?.toDouble()?.toStringAsFixed(2) ?? '-'}',
                parseString(macd['signal_text']) ?? '',
                AppColors.info,
              ),
              // Bollinger
              if (bollinger != null) _buildIndicatorCard(
                'بولينجر',
                '${(bollinger['lower'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '-'} - ${(bollinger['upper'] as num?)?.toDouble()?.toStringAsFixed(0) ?? '-'}',
                parseString(bollinger['signal_text']) ?? '',
                AppColors.warning,
              ),
              // Stochastic RSI
              if (stochRsi != null) _buildIndicatorCard(
                'Stoch RSI',
                'K:${(stochRsi['k'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '-'} D:${(stochRsi['d'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '-'}',
                parseString(stochRsi['signal_text']) ?? '',
                AppColors.info,
              ),
              // ATR
              if (atr != null) _buildIndicatorCard(
                'ATR',
                '${atr.toStringAsFixed(2)} (${atrPercent?.toStringAsFixed(0)}%)',
                '',
                AppColors.warning,
              ),
              // VWAP
              if (vwap != null) _buildIndicatorCard(
                'VWAP',
                vwap.toStringAsFixed(2),
                '',
                AppColors.info,
              ),
              // ROC
              if (roc != null) _buildIndicatorCard(
                'ROC',
                '5:${(roc['roc_5'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '-'}%',
                parseString(roc['signal_text']) ?? '',
                AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Patterns
        if (detectedPatterns.isNotEmpty || maCross.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.show_chart, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('النماذج المكتشفة', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                if (maCross.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (maCross == 'golden_cross' ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      maCross == 'golden_cross' ? 'تقاطع ذهبي ↑' : 'تقاطع الموت ↓',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: maCross == 'golden_cross' ? AppColors.success : AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...detectedPatterns.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        (p['type'] == 'bullish' || p['type'] == 'صاعد') ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: (p['type'] == 'bullish' || p['type'] == 'صاعد') ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p['name_ar'] ?? p['name'] ?? '', style: AppTypography.bodyMedium)),
                      if (p['reliability'] != null)
                        Text(p['reliability'], style: AppTypography.bodySmall),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Price Levels
        if (support1 != null || resistance1 != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.format_list_numbered, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('مستويات السعر', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (resistance2 != null) _buildPriceLevelCard('مقاومة 2', resistance2, AppColors.danger),
                    if (resistance1 != null) _buildPriceLevelCard('مقاومة 1', resistance1, AppColors.danger),
                    if (pivot != null) _buildPriceLevelCard('محور', pivot, AppColors.warning),
                    if (support1 != null) _buildPriceLevelCard('دعم 1', support1, AppColors.success),
                    if (support2 != null) _buildPriceLevelCard('دعم 2', support2, AppColors.success),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Risk Metrics
        if (riskMetrics != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.shield, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('مقاييس المخاطر', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (sharpeRatio != null) _buildRiskMetricCard('Sharpe Ratio', sharpeRatio.toStringAsFixed(2)),
                    if (maxDrawdown != null) _buildRiskMetricCard('أقصى انخفاض', '${maxDrawdown.toStringAsFixed(1)}%'),
                    if (volatility != null) _buildRiskMetricCard('التقلبية', '${volatility.toStringAsFixed(1)}%'),
                    if (beta != null) _buildRiskMetricCard('Beta', beta.toStringAsFixed(2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Volume Analysis
        if (volumeSignal.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تحليل الحجم', style: AppTypography.titleSmall),
                      Text(volumeSignal, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Data Quality
        if (quality.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Icon(Icons.data_usage, size: 18, color: quality == 'high' ? AppColors.success : AppColors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('جودة البيانات: ${quality == 'high' ? 'عالية' : quality}', style: AppTypography.titleSmall),
                      if (historyPoints != null) Text('$historyPoints نقطة بيانات', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceBadge(String label, double price, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            Text('${price.toStringAsFixed(2)} ج.م', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(String title, String value, String subtitle, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 56) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceLevelCard(String label, double price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text('${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildRiskMetricCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.titleSmall),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  Color _getRsiColor(double? rsi) {
    if (rsi == null) return AppColors.info;
    if (rsi > 70) return AppColors.danger;
    if (rsi < 30) return AppColors.success;
    return AppColors.info;
  }

  Widget _buildScoreBar(String label, double score) {
    final normalizedScore = (score / 100).clamp(0.0, 1.0);
    final color = score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text('${score.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalizedScore,
            backgroundColor: AppColors.surfaceMuted,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // Helpers
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
}

// Simple line chart painter for stock prices
class _StockLineChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  _StockLineChartPainter({required this.prices, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill;

    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final padding = 10.0;

    final points = <Offset>[];
    for (int i = 0; i < prices.length; i++) {
      final x = padding + (i / (prices.length - 1).clamp(1, prices.length)) * (size.width - padding * 2);
      final y = size.height - padding - ((prices[i] - min) / range) * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, paint);

    // Dots
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(points.first, 4, dotPaint);
    canvas.drawCircle(points.last, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
