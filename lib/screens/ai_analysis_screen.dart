// ============================================================================
// مساعد الاستثمار Flutter - AI Analysis Screen
// Shows AI-powered market analysis with live insights
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/json_helpers.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class AiAnalysisScreen extends StatefulWidget {
  const AiAnalysisScreen({super.key});

  @override
  State<AiAnalysisScreen> createState() => _AiAnalysisScreenState();
}

class _AiAnalysisScreenState extends State<AiAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Future<Map<String, dynamic>?>? _analysisFuture;
  Future<Map<String, dynamic>?>? _predictionsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _analysisFuture = _fetchAnalysis();
    _predictionsFuture = _fetchPredictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchAnalysis() async {
    try {
      final data = await api.getLiveAnalysis();
      if (data.isNotEmpty) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchPredictions() async {
    try {
      // Uses /api/mobile/predictions with 120s timeout via aiDio
      final data = await api.getMobilePredictions(limit: 20);
      return {'predictions': data};
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchGlobalPredictions() async {
    try {
      final data = await api.getGlobalPredictions();
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _analysisFuture = _fetchAnalysis();
      _predictionsFuture = _fetchPredictions();
    });
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
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('تحليل AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderCard(
                  icon: Icons.auto_awesome,
                  title: 'تحليل AI الذكي',
                  subtitle: 'رؤى وتحليلات مدعومة بالذكاء الاصطناعي',
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: const [
                      Tab(text: 'التوقعات'),
                      Tab(text: 'التحليل المباشر'),
                      Tab(text: 'توقعات عالمية'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPredictionsTab(),
                      _buildAnalysisTab(),
                      _buildGlobalPredictionsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _predictionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAiAnalysis();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return StateView(error: 'فشل تحميل التوقعات', onRetry: _refresh);
        }

        final predictions = snapshot.data!['predictions'] as List? ?? [];
        if (predictions.isEmpty) {
          return const StateView(
              empty: true, emptyMessage: 'لا توجد توقعات متاحة');
        }

        return ListView.builder(
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final pred = predictions[index] is Map
                ? Map<String, dynamic>.from(predictions[index])
                : <String, dynamic>{};
            return _buildPredictionCard(pred);
          },
        );
      },
    );
  }

  Widget _buildAnalysisTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _analysisFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAiAnalysis();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return StateView(error: 'فشل تحميل التحليل', onRetry: _refresh);
        }

        final data = snapshot.data!;
        final market = data['market'] is Map ? data['market'] as Map : {};
        final live = data['_live'] is Map ? data['_live'] as Map : {};
        final recs = market['recommendations'] is Map ? market['recommendations'] as Map : {};

        final regime = market['regime']?.toString() ?? 'neutral';
        final regimeText = regime == 'bull' ? 'صاعد 📈' : regime == 'bear' ? 'هابط 📉' : 'محايد ⚖️';
        
        final marketSummaryStr = 'اتجاه السوق الحالي: $regimeText\n'
            'إجمالي الأسهم التي تم تحليلها: ${market['totalStocksAnalyzed'] ?? 0}\n'
            'الأسهم المجتازة لفلتر الأمان المالي: ${market['passedSafetyFilter'] ?? 0}';

        final recsStr = '${live['aiCommentary'] ?? 'تحليل التوقعات الذكي للمحفظة والأسهم.'}\n\n'
            'شراء قوي: ${recs['strongBuy'] ?? 0} | شراء: ${recs['buy'] ?? 0}\n'
            'احتفاظ: ${recs['hold'] ?? 0} | تجنب: ${recs['avoid'] ?? 0} | تجنب قوي: ${recs['strongAvoid'] ?? 0}';

        final riskIssues = market['diversificationIssues'] is List 
            ? (market['diversificationIssues'] as List).join('\n')
            : '';
        final riskStr = 'نسبة السيولة النقدية المقترحة: ${parseDouble(market['fearCashPercent'])?.toStringAsFixed(0) ?? '20'}%\n'
            '${riskIssues.isNotEmpty ? '\nتنبيهات المحفظة والتنويع:\n$riskIssues' : 'المحفظة متنوعة بشكل جيد ولا توجد تنبيهات مخاطر.'}';

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildMetricCard(
                'مؤشرات السوق والاتجاه', Icons.show_chart, marketSummaryStr),
            _buildMetricCard(
                'توقعات وقراءة الذكاء الاصطناعي', Icons.lightbulb, recsStr),
            _buildMetricCard(
                'تحليل المخاطر والسيولة', Icons.warning, riskStr),
          ],
        );
      },
    );
  }

  Widget _buildGlobalPredictionsTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchGlobalPredictions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAiAnalysis();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return StateView(
              error: 'فشل تحميل التوقعات العالمية', onRetry: _refresh);
        }

        final data = snapshot.data!;
        return ListView(
          children: [
            _buildMetricCard(
                'التوقعات العالمية', Icons.public, data['summary'] ?? ''),
            if (data['predictions'] is List)
              ...(data['predictions'] as List).map((p) => _buildPredictionCard(
                  p is Map
                      ? Map<String, dynamic>.from(p)
                      : <String, dynamic>{})),
          ],
        );
      },
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> pred) {
    final ticker = pred['ticker'] ?? pred['symbol'] ?? '';
    final signal = (pred['signal'] ?? pred['signal_type'])?.toString().toUpperCase() ?? '';
    final confidence = parseDouble(pred['confidence']) ?? 0;
    final entryPrice = parseDouble(pred['entry_price']);
    final targetPrice = parseDouble(pred['target_price']);
    final stopLoss = parseDouble(pred['stop_loss']);

    Color signalColor;
    IconData signalIcon;
    switch (signal) {
      case 'STRONG_BUY':
        signalColor = const Color(0xFFFFD700);
        signalIcon = Icons.thumb_up;
        break;
      case 'BUY':
        signalColor = AppColors.success;
        signalIcon = Icons.trending_up;
        break;
      case 'SELL':
        signalColor = AppColors.danger;
        signalIcon = Icons.trending_down;
        break;
      case 'STRONG_SELL':
        signalColor = Colors.deepOrange;
        signalIcon = Icons.thumb_down;
        break;
      default:
        signalColor = AppColors.warning;
        signalIcon = Icons.swap_horiz;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: signal == 'STRONG_BUY'
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(signalIcon, color: signalColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
                child:
                    Text(ticker.toString(), style: AppTypography.titleSmall)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: signalColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                  signal == 'STRONG_BUY'
                      ? 'شراء قوي'
                      : signal == 'STRONG_SELL'
                          ? 'بيع قوي'
                          : signal,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: signalColor)),
            ),
          ]),
          if (confidence > 0) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Text('نسبة الثقة:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              Expanded(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: confidence / 100,
                          backgroundColor: AppColors.surfaceMuted,
                          color: signalColor,
                          minHeight: 6))),
              const SizedBox(width: 8),
              Text('${confidence.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: signalColor)),
            ]),
          ],
          const Divider(height: 16),
          Row(children: [
            if (entryPrice != null)
              Expanded(child: _buildPriceCol('الدخول', entryPrice)),
            if (targetPrice != null)
              Expanded(child: _buildPriceCol('الهدف', targetPrice)),
            if (stopLoss != null)
              Expanded(child: _buildPriceCol('وقف الخسارة', stopLoss)),
          ]),
          if (pred['reasoning'] != null) ...[
            const SizedBox(height: 8),
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(pred['reasoning'].toString(),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary))),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceCol(String label, double value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value.toStringAsFixed(2),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildMetricCard(String title, IconData icon, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.titleSmall)
        ]),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(content,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary))
        ],
      ]),
    );
  }
}
