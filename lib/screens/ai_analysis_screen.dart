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
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

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
  Future<SubscriptionStatus>? _subscriptionFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _analysisFuture = _fetchAnalysis();
    _predictionsFuture = _fetchPredictions();
    _subscriptionFuture = SubscriptionService.instance.getStatus();
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
      final data = await api.getPredictions();
      return {'predictions': data};
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
        body: FutureBuilder<SubscriptionStatus>(
          future: _subscriptionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final hasAccess = snapshot.data?.hasFeature('ai_analysis') ?? false;
            return !hasAccess
                ? _buildLockedView()
                : RefreshIndicator(
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
                                Tab(text: 'الرئيسية'),
                                Tab(text: 'التنبؤات'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: MediaQuery.of(context).size.height - 200,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildAnalysisTab(),
                                _buildPredictionsTab(),
                              ],
                            ),
                          ),
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

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'التحليل الاحترافي ميزة مدفوعة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'قم بالترقية إلى بلس للوصول إلى تحليلات AI المتقدمة',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  UpgradeModal.show(context, feature: 'ai_analysis'),
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

  Widget _buildAnalysisTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _analysisFuture,
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
            error: 'فشل تحميل البيانات: ${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return const StateView(
            empty: true,
            emptyMessage: 'لا توجد تحليلات متاحة حالياً',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildAnalysisContent(data),
        );
      },
    );
  }

  Widget _buildAnalysisContent(Map<String, dynamic> data) {
    String outlook =
        parseString(data['outlook'] ?? data['market_outlook'] ?? '') ?? '';
    double confidence =
        parseDouble(data['confidence'] ?? data['overall_confidence'] ?? 0) ??
            0.0;
    final signals =
        (data['signals'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
    final recommendations =
        (data['recommendations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (outlook.isNotEmpty && confidence > 0) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getOutlookColors(outlook, confidence),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outlook.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مستوى الثقة: ${confidence.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (signals.isNotEmpty) ...[
          const SectionHeader(title: 'الإشارات الحية', icon: Icons.trending_up),
          const SizedBox(height: 8),
          ...signals.map((s) => _buildSignalCard(s)),
          const SizedBox(height: 16),
        ],
        if (recommendations.isNotEmpty) ...[
          const SectionHeader(title: 'التوصيات', icon: Icons.lightbulb_outline),
          const SizedBox(height: 8),
          ...recommendations.map((r) => _buildRecommendationCard(r)),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSignalCard(Map<String, dynamic> signal) {
    final ticker = signal['ticker'] ?? signal['symbol'] ?? '';
    final action =
        parseString(signal['action'] ?? signal['recommendation'] ?? '') ?? '';
    final confidence =
        parseDouble(signal['confidence'] ?? signal['score'] ?? 0);
    final reason =
        parseString(signal['reason'] ?? signal['reason_ar'] ?? '') ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getActionColor(action).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActionIcon(action),
              color: _getActionColor(action),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ticker, style: AppTypography.titleSmall),
                    const SizedBox(width: 8),
                    if (action.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getActionColor(action).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getActionAr(action),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getActionColor(action),
                          ),
                        ),
                      ),
                  ],
                ),
                if (reason.isNotEmpty)
                  Text(reason,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                if (confidence != null)
                  Text('ثقة: ${confidence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    final title =
        parseString(rec['title'] ?? rec['ticker'] ?? rec['name'] ?? '') ?? '';
    final description =
        parseString(rec['description'] ?? rec['reason'] ?? '') ?? '';
    final action =
        parseString(rec['action'] ?? rec['recommendation'] ?? '') ?? '';
    final impact = parseString(rec['impact'] ?? '') ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (action.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getActionColor(action).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getActionAr(action),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getActionColor(action),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.titleSmall)),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: AppTypography.bodySmall),
          ],
          if (impact.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.show_chart, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Text(impact, style: AppTypography.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _predictionsFuture,
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
            error: 'فشل تحميل التنبؤات: ${snapshot.error}',
            onRetry: _refresh,
          );
        }
        final data = snapshot.data;
        final predictions = (data != null && data.isNotEmpty)
            ? (data['predictions'] as List?) ?? []
            : <dynamic>[];
        if (predictions.isEmpty) {
          return const StateView(
            empty: true,
            emptyMessage: 'لا توجد تنبؤات متاحة حالياً',
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'تنبؤات AI', icon: Icons.auto_awesome),
              const SizedBox(height: 8),
              ...predictions
                  .map((p) => _buildPredictionCard(p as Map<String, dynamic>)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> prediction) {
    final ticker = prediction['ticker'] ?? prediction['symbol'] ?? '';
    final predictedPrice = (prediction['predicted_price'] as num?)?.toDouble();
    final currentPrice = (prediction['current_price'] as num?)?.toDouble();
    final changePercent = (prediction['change_percent'] as num?)?.toDouble();
    final timeframe = parseString(prediction['timeframe'] ?? '') ?? '';
    final confidence = parseDouble(prediction['confidence'] ?? 0);

    final isUp = (changePercent ?? 0) >= 0;
    final changeColor = isUp ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isUp ? Icons.trending_up : Icons.trending_down,
                color: changeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(ticker, style: AppTypography.titleSmall),
              ),
              if (confidence != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ثقة: ${confidence.toStringAsFixed(0)}%',
                    style:
                        const TextStyle(fontSize: 10, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPredictionItem(
                  'السعر الحالي',
                  currentPrice != null ? currentPrice.toStringAsFixed(2) : '-',
                ),
              ),
              Expanded(
                child: _buildPredictionItem(
                  'السعر المتوقع',
                  predictedPrice != null
                      ? predictedPrice.toStringAsFixed(2)
                      : '-',
                  color: changeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (changePercent != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ),
              if (timeframe.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeframe,
                    style: const TextStyle(fontSize: 11, color: AppColors.info),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? AppColors.text,
          ),
        ),
      ],
    );
  }

  List<Color> _getOutlookColors(String outlook, double confidence) {
    final o = outlook.toUpperCase();
    if (o.contains('BULLISH') || o.contains('صاعد')) {
      return [AppColors.success.withValues(alpha: 0.8), AppColors.success];
    }
    if (o.contains('BEARISH') || o.contains('هابط')) {
      return [AppColors.danger.withValues(alpha: 0.8), AppColors.danger];
    }
    if (o.contains('NEUTRAL') || o.contains('محايد')) {
      return [AppColors.warning.withValues(alpha: 0.8), AppColors.warning];
    }
    if (confidence >= 70) {
      return [AppColors.success.withValues(alpha: 0.8), AppColors.success];
    }
    if (confidence >= 40) {
      return [AppColors.warning.withValues(alpha: 0.8), AppColors.warning];
    }
    return [AppColors.info.withValues(alpha: 0.8), AppColors.info];
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
    return action;
  }
}
