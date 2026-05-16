// ============================================================================
// مساعد الاستثمار Flutter - AI Analysis Screen
// AI-powered stock analysis, batch analysis, and predictions
// Uses: POST /api/ai-analysis, GET /api/stocks/batch-analysis, GET /api/predictions
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _analyzing = false;
  String? _error;

  // Server health
  bool _serverOnline = false;

  // Batch Analysis
  List<Map<String, dynamic>> _batchAnalysis = [];
  Map<String, dynamic>? _batchSummary;
  Map<String, dynamic>? _liveAnalysis;

  // Predictions
  List<Prediction> _predictions = [];

  // Single stock analysis
  final _tickerCtrl = TextEditingController();
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });

      // Load data from valid API endpoints in parallel
      await Future.wait([
        _loadServerHealth(),
        _loadBatchAnalysis(),
        _loadPredictions(),
        _loadLiveAnalysis(),
      ]);

      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadServerHealth() async {
    try {
      final result = await api.healthCheck();
      _serverOnline = result['status'] == 'ok';
    } catch (_) {
      _serverOnline = false;
    }
  }

  Future<void> _loadBatchAnalysis() async {
    try {
      final response = await api.getBatchAnalysis();
      final analyzed = (response['analyzed'] as List?) ?? [];
      _batchAnalysis = analyzed.cast<Map<String, dynamic>>();
      _batchSummary = response['summary'] as Map<String, dynamic>?;
    } catch (_) {
      // Batch analysis may not be available
    }
  }

  Future<void> _loadPredictions() async {
    try {
      final response = await api.getPredictions();
      final preds = (response['predictions'] as List?)
          ?.map((e) => Prediction.fromJson(e))
          .toList() ?? [];
      _predictions = preds;
    } catch (_) {}
  }

  Future<void> _loadLiveAnalysis() async {
    try {
      _liveAnalysis = await api.getLiveAnalysis();
    } catch (_) {}
  }

  Future<void> _analyzeStock() async {
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) return;

    final access = await SubscriptionService.instance.checkAccess('ai_analysis');
    if (!access.hasAccess) {
      if (mounted) {
        UpgradeModal.show(context, feature: 'ai_analysis', reason: access.reason, upgradeTo: access.upgradeTo);
      }
      return;
    }

    setState(() { _analyzing = true; _analysisResult = null; });
    try {
      final result = await api.analyzeStock(ticker);
      setState(() { _analysisResult = result; _analyzing = false; });
    } catch (e) {
      setState(() { _analyzing = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحليل: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Header with AI status
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.secondaryDark, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome, color: AppColors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('تحليل AI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
                                  Text(
                                    _serverOnline ? 'الخادم متصل • جاهز للتحليل' : 'جاري التحميل...',
                                    style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _serverOnline ? AppColors.success : AppColors.warning,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _serverOnline ? 'متصل' : 'غير متصل',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: AppColors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'تحليل سهم'),
                        Tab(text: 'تحليل شامل'),
                        Tab(text: 'التنبؤات'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: _loading
                  ? const StateView(loading: true)
                  : _error != null
                      ? StateView(error: _error, onRetry: () => _loadData())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAnalysisTab(),
                            _buildBatchAnalysisTab(),
                            _buildPredictionsTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Tab 1: Single Stock Analysis
  // ===========================================================================
  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tickerCtrl,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رمز السهم...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _analyzeStock(),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: _analyzing ? null : _analyzeStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: _analyzing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                        : const Text('تحليل', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Analysis Result
          if (_analysisResult != null) ...[
            _buildAnalysisResult(),
          ] else ...[
            const StateView(empty: true, emptyMessage: 'أدخل رمز سهم لتحليله بالذكاء الاصطناعي'),
          ],
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildAnalysisResult() {
    final data = _analysisResult!;
    final recommendation = data['recommendation'] as Map<String, dynamic>?;
    final action = recommendation?['action'] as String? ?? data['action'] as String? ?? '';
    final confidence = (recommendation?['confidence'] as num?)?.toDouble() ?? (data['confidence'] as num?)?.toDouble() ?? 0;
    final reasons = (data['reasons'] as List?)?.cast<String>() ?? [];
    final technicalAnalysis = data['technical_analysis'] as String? ?? '';
    final fundamentalAnalysis = data['fundamental_analysis'] as String? ?? '';
    final riskLevel = data['risk_level'] as String? ?? '';
    final priceTarget = (data['price_target'] as num?)?.toDouble();
    final stopLoss = (data['stop_loss'] as num?)?.toDouble();

    final actionColor = _getActionColor(action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Action Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [actionColor.withValues(alpha: 0.8), actionColor]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(_getActionAr(action), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white)),
              const SizedBox(height: 8),
              Text('مستوى الثقة: ${confidence.toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.9))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (priceTarget != null) ...[
                    Column(children: [
                      Text('السعر المستهدف', style: TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: 0.7))),
                      Text('${priceTarget.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ]),
                    const SizedBox(width: 24),
                  ],
                  if (stopLoss != null) ...[
                    Column(children: [
                      Text('وقف الخسارة', style: TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: 0.7))),
                      Text('${stopLoss.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ]),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Risk Level
        if (riskLevel.isNotEmpty) ...[
          _buildInfoCard('مستوى المخاطر', riskLevel, Icons.shield,
            color: riskLevel == 'high' ? AppColors.danger : riskLevel == 'low' ? AppColors.success : AppColors.warning),
          const SizedBox(height: 12),
        ],

        // Technical Analysis
        if (technicalAnalysis.isNotEmpty) ...[
          _buildInfoCard('التحليل الفني', technicalAnalysis, Icons.analytics),
          const SizedBox(height: 12),
        ],

        // Fundamental Analysis
        if (fundamentalAnalysis.isNotEmpty) ...[
          _buildInfoCard('التحليل الأساسي', fundamentalAnalysis, Icons.account_balance),
          const SizedBox(height: 12),
        ],

        // Reasons
        if (reasons.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text('الأسباب', style: AppTypography.titleSmall),
                ]),
                const SizedBox(height: 10),
                ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 14, color: AppColors.secondary)),
                      Expanded(child: Text(r, style: AppTypography.bodyMedium)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // Tab 2: Batch Analysis
  // ===========================================================================
  Widget _buildBatchAnalysisTab() {
    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: () => _loadData(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary
            if (_batchSummary != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.secondaryDark, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSummaryItem('شراء', _batchSummary!['buySignals'] ?? 0, AppColors.success)),
                    Expanded(child: _buildSummaryItem('بيع', _batchSummary!['sellSignals'] ?? 0, AppColors.danger)),
                    Expanded(child: _buildSummaryItem('احتفاظ', _batchSummary!['holdSignals'] ?? 0, AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_batchAnalysis.isEmpty)
              const StateView(empty: true, emptyMessage: 'لا يوجد تحليل شامل متاح حالياً')
            else
              ..._batchAnalysis.map((item) => _buildBatchAnalysisCard(item)),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildBatchAnalysisCard(Map<String, dynamic> item) {
    final stockData = item['stock'] as Map<String, dynamic>?;
    final ticker = stockData?['ticker'] ?? item['ticker'] ?? '';
    final name = stockData?['name_ar'] ?? stockData?['name'] ?? item['name'] ?? '';
    final action = item['recommendation']?['action'] ?? item['action'] ?? '';
    final score = (item['compositeScore'] ?? item['score'] as num?)?.toDouble() ?? 0;
    final actionColor = _getActionColor(action.toString());

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
              color: actionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getActionIcon(action.toString()), color: actionColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticker, style: AppTypography.titleSmall),
                if (name.isNotEmpty) Text(name, style: AppTypography.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getActionAr(action.toString()),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: actionColor),
                ),
              ),
              const SizedBox(height: 4),
              Text('النتيجة: ${score.toStringAsFixed(1)}', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Predictions
  // ===========================================================================
  Widget _buildPredictionsTab() {
    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: () => _loadData(silent: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_predictions.isEmpty)
              const StateView(empty: true, emptyMessage: 'لا توجد تنبؤات نشطة')
            else
              ..._predictions.map((pred) => _buildPredictionCard(pred)),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(Prediction pred) {
    final actionColor = _getActionColor(pred.predictionType ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getActionIcon(pred.predictionType ?? ''), color: actionColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pred.ticker ?? '', style: AppTypography.titleSmall),
                    Text(pred.predictionDate ?? '', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              // Confidence
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pred.confidence ?? 0}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: actionColor)),
                  const Text('ثقة', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              if (pred.entryPrice != null) Expanded(child: _buildPriceItem('الدخول', pred.entryPrice)),
              if (pred.targetPrice != null) Expanded(child: _buildPriceItem('الهدف', pred.targetPrice)),
              if (pred.stopLoss != null) Expanded(child: _buildPriceItem('وقف الخسارة', pred.stopLoss)),
            ],
          ),
          if (pred.technicalScore != null || pred.fundamentalScore != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (pred.technicalScore != null)
                  Expanded(child: _buildScoreBar('فني', pred.technicalScore!)),
                if (pred.technicalScore != null && pred.fundamentalScore != null)
                  const SizedBox(width: 8),
                if (pred.fundamentalScore != null)
                  Expanded(child: _buildScoreBar('أساسي', pred.fundamentalScore!)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================
  Widget _buildInfoCard(String title, String content, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color ?? AppColors.secondary),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.titleSmall),
          ]),
          const SizedBox(height: 8),
          Text(content, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, double? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall),
        const SizedBox(height: 2),
        Text(value != null ? '${value.toStringAsFixed(2)}' : '-', style: AppTypography.titleSmall),
      ],
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final color = score >= 70 ? AppColors.success : score >= 40 ? AppColors.warning : AppColors.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text('$score%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.surfaceMuted,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
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
}
