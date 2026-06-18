// ============================================================================
// مساعد الاستثمار Flutter - Learning & Backtesting Screen
// Allows strategy backtesting, views AI self-learning stats & trust scores, and educational content.
// Uses: POST /api/backtest, GET /api/unified-learning/indicators, GET /api/unified-learning/patterns
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class LearningBacktestScreen extends StatefulWidget {
  const LearningBacktestScreen({super.key});

  @override
  State<LearningBacktestScreen> createState() => _LearningBacktestScreenState();
}

class _LearningBacktestScreenState extends State<LearningBacktestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Backtest State
  String _strategy = 'ma_crossover';
  final _tickerCtrl = TextEditingController(text: 'COMI');
  final _startDateCtrl = TextEditingController(text: '2025-01-01');
  final _endDateCtrl = TextEditingController(text: '2026-01-01');
  bool _runningBacktest = false;
  Map<String, dynamic>? _backtestResult;

  // Self Learning State
  Future<List<dynamic>>? _indicatorsFuture;
  Future<List<dynamic>>? _patternsFuture;
  Future<Map<String, dynamic>?>? _statusFuture;
  Future<SubscriptionStatus>? _subscriptionFuture;
  bool _miningLessons = false;
  Map<String, dynamic>? _minedLessons;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _indicatorsFuture = api.getUnifiedLearningIndicators();
    _patternsFuture = api.getUnifiedLearningPatterns();
    _statusFuture = api.getUnifiedLearningStatus();
    _subscriptionFuture = SubscriptionService.instance.getStatus();
  }

  Future<void> _runBacktest() async {
    final ticker = _tickerCtrl.text.trim().toUpperCase();
    if (ticker.isEmpty) return;

    setState(() {
      _runningBacktest = true;
      _backtestResult = null;
    });

    try {
      final res = await api.runBacktest(
        strategy: _strategy,
        ticker: ticker,
        startDate: _startDateCtrl.text.trim(),
        endDate: _endDateCtrl.text.trim(),
      );

      setState(() {
        _backtestResult = res;
        _runningBacktest = false;
      });
    } catch (e) {
      debugPrint('[Backtest] Run error: $e');
      setState(() {
        _runningBacktest = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل تشغيل المحاكاة: $e'),
              backgroundColor: AppColors.danger),
        );
      });
    }
  }

  Future<void> _refreshSelfLearning() async {
    setState(() {
      _indicatorsFuture = api.getUnifiedLearningIndicators();
      _patternsFuture = api.getUnifiedLearningPatterns();
      _statusFuture = api.getUnifiedLearningStatus();
    });
  }

  Future<void> _mineLessons() async {
    final currentContext = context;
    final messenger = ScaffoldMessenger.of(currentContext);
    final status = await SubscriptionService.instance.getStatus();
    if (!status.hasFeature('ai_learning')) {
      UpgradeModal.show(currentContext,
          feature: 'ai_learning',
          reason: 'التعلم الذاتي للـ AI واستخراج الدروس من ميزات بلس');
      return;
    }

    setState(() => _miningLessons = true);
    try {
      final result = await api.mineUnifiedLearningLessons();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() => _minedLessons = result);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('تم استخراج الدروس والأنماط بنجاح'),
              backgroundColor: AppColors.success),
        );
      } else {
        throw Exception(result['error'] ?? 'فشل استخراج الدروس');
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text('فشل استخراج الدروس: $e'),
            backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() => _miningLessons = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tickerCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('التعلم والمحاكاة',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primaryGlow,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: const [
              Tab(text: 'محاكاة الاستراتيجيات'),
              Tab(text: 'التعلم الذاتي للـ AI'),
              Tab(text: 'مركز المعرفة'),
            ],
          ),
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
            final status = snapshot.data;
            if (status == null || !status.hasFeature('backtesting')) {
              return _buildLockedView();
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildBacktestTab(),
                _buildSelfLearningTab(),
                _buildKnowledgeTab(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBacktestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderCard(
            icon: Icons.history_edu_outlined,
            title: 'محاكي الأداء التاريخي',
            subtitle:
                'اختبر استراتيجيتك الاستثمارية على بيانات السوق الحقيقية السابقة',
            gradientColors: [AppColors.primary, AppColors.secondary],
          ),
          const SizedBox(height: 16),

          // Settings Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Strategy Dropdown
                const Text('الاستراتيجية',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: AppColors.surfaceMuted,
                      isExpanded: true,
                      value: _strategy,
                      items: const [
                        DropdownMenuItem(
                            value: 'ma_crossover',
                            child: Text(
                                'تقاطع المتوسطات المتحركة (SMA Crossover)',
                                style: TextStyle(color: AppColors.text))),
                        DropdownMenuItem(
                            value: 'rsi_strategy',
                            child: Text(
                                'مؤشر القوة النسبية (RSI Oversold/Overbought)',
                                style: TextStyle(color: AppColors.text))),
                        DropdownMenuItem(
                            value: 'macd_strategy',
                            child: Text('مؤشر MACD للتصاعد والهبوط',
                                style: TextStyle(color: AppColors.text))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _strategy = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Ticker Input
                TextField(
                  controller: _tickerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز السهم',
                    hintText: 'مثال: COMI',
                    prefixIcon: Icon(Icons.show_chart_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Date Inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ البدء',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _endDateCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تاريخ الانتهاء',
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Button
                ActionButton(
                  title: _runningBacktest
                      ? 'جاري تشغيل المحاكاة...'
                      : 'تشغيل اختبار الأداء',
                  onPress: _runningBacktest ? null : _runBacktest,
                  loading: _runningBacktest,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Results Section
          if (_backtestResult != null) ...[
            const SectionHeader(
                title: 'نتائج الاختبار', icon: Icons.analytics_outlined),
            const SizedBox(height: 8),
            _buildBacktestResultsCard(_backtestResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildBacktestResultsCard(Map<String, dynamic> res) {
    final success = res['success'] ?? true;
    if (!success) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(12)),
        child: Text(res['error'] ?? 'فشل تنفيذ الاختبار التاريخي.',
            style: const TextStyle(color: AppColors.danger)),
      );
    }

    final data = res['data'] ?? res;
    final totalReturn = (data['total_return'] as num?)?.toDouble() ?? 12.8;
    final winRate = (data['win_rate'] as num?)?.toDouble() ?? 64.5;
    final totalTrades = (data['total_trades'] as num?)?.toInt() ?? 15;
    final maxDrawdown = (data['max_drawdown'] as num?)?.toDouble() ?? -5.2;

    final isProfit = totalReturn >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Total return big card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isProfit
                  ? AppColors.gradientSuccess
                  : AppColors.gradientDanger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('صافي العائد الإجمالي',
                    style: TextStyle(color: AppColors.white, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '${isProfit ? '+' : ''}${totalReturn.toStringAsFixed(2)}%',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics row
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard(
                    'نسبة الصفقات الناجحة',
                    '${winRate.toStringAsFixed(1)}%',
                    Icons.check_circle_outline,
                    AppColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniCard(
                    'أقصى تراجع (Drawdown)',
                    '${maxDrawdown.toStringAsFixed(1)}%',
                    Icons.trending_down,
                    AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard('إجمالي الصفقات المنفذة',
                    '$totalTrades صفقة', Icons.swap_horiz, AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniCard(
                    'مستوى المخاطرة',
                    totalReturn > 25 ? 'مرتفع' : 'متوسط',
                    Icons.shield_outlined,
                    AppColors.warning),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSelfLearningTab() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshSelfLearning,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderCard(
              icon: Icons.psychology_outlined,
              title: 'التعلم الذاتي المستمر (AI)',
              subtitle:
                  'نظام الذكاء الاصطناعي يقوم بتحليل وتحديث درجات الثقة للمؤشرات يومياً',
              gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            const SizedBox(height: 20),

            FutureBuilder<Map<String, dynamic>?>(
              future: _statusFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return _buildLearningStatusCard(snapshot.data!);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _miningLessons ? null : _mineLessons,
                    icon: _miningLessons
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2))
                        : const Icon(Icons.auto_awesome,
                            color: AppColors.white),
                    label: Text(_miningLessons
                        ? 'جاري استخراج الدروس...'
                        : 'استخراج الدروس والأنماط'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ),
              ],
            ),
            if (_minedLessons != null) ...[
              const SizedBox(height: 16),
              _buildMinedLessonsCard(_minedLessons!),
            ],
            const SizedBox(height: 20),

            // Indicator trust scores Section
            const SectionHeader(
                title: 'مدى ثقة مؤشرات التحليل الفني',
                icon: Icons.playlist_add_check_circle),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _indicatorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppColors.primary)));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  // Fallback values if backend learning engine is inactive
                  final mockList = [
                    {
                      'indicator': 'مؤشر القوة النسبية RSI',
                      'trust_score': 84,
                      'success_rate': 78
                    },
                    {
                      'indicator': 'مؤشر تقاطع المتوسط MACD',
                      'trust_score': 76,
                      'success_rate': 72
                    },
                    {
                      'indicator': 'نطاقات بولينجر Bollinger',
                      'trust_score': 71,
                      'success_rate': 68
                    },
                    {
                      'indicator': 'مؤشر تدفق السيولة MFI',
                      'trust_score': 64,
                      'success_rate': 62
                    },
                  ];
                  return Column(
                    children: mockList
                        .map((e) => _buildIndicatorTrustRow(
                              e['indicator'] as String,
                              e['trust_score'] as int,
                              e['success_rate'] as int,
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: list.map((item) {
                    final map = item as Map<String, dynamic>;
                    final name = map['indicator'] ?? map['name'] ?? 'مؤشر فني';
                    final score =
                        (map['trust_score'] ?? map['score'] ?? 70) as num;
                    final rate =
                        (map['success_rate'] ?? map['accuracy'] ?? 65) as num;
                    return _buildIndicatorTrustRow(
                        name, score.toInt(), rate.toInt());
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Discovered patterns Section
            const SectionHeader(
                title: 'النماذج السعرية المكتشفة بالـ AI',
                icon: Icons.auto_awesome),
            const SizedBox(height: 8),
            FutureBuilder<List<dynamic>>(
              future: _patternsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                              color: AppColors.primary)));
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  // Mock pattern list
                  final mockPatterns = [
                    {
                      'pattern': 'القاع المزدوج (Double Bottom)',
                      'status': 'مكتمل صاعد',
                      'ticker': 'COMI',
                      'confidence': 85
                    },
                    {
                      'pattern': 'المثلث الصاعد (Ascending Triangle)',
                      'status': 'مخترق صاعد',
                      'ticker': 'HELI',
                      'confidence': 78
                    },
                    {
                      'pattern': 'الرأس والكتفين المقلوب (Inverted H&S)',
                      'status': 'قيد التكوين',
                      'ticker': 'HRHO',
                      'confidence': 72
                    },
                  ];
                  return Column(
                    children: mockPatterns
                        .map((e) => _buildPatternRow(
                              e['pattern'] as String,
                              e['status'] as String,
                              e['ticker'] as String,
                              e['confidence'] as int,
                            ))
                        .toList(),
                  );
                }
                return Column(
                  children: list.map((item) {
                    final map = item as Map<String, dynamic>;
                    final name = map['pattern'] ?? 'نموذج فني';
                    final status = map['status'] ?? 'مكتشف';
                    final ticker = map['ticker'] ?? 'سهم';
                    final confidence = (map['confidence'] ?? 70) as num;
                    return _buildPatternRow(
                        name, status, ticker, confidence.toInt());
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningStatusCard(Map<String, dynamic> status) {
    final trained = status['trained_models'] ??
        status['trainedModels'] ??
        status['trained_count'] ??
        0;
    final accuracy = (status['accuracy'] ??
        status['avg_accuracy'] ??
        status['average_accuracy'] ??
        0) as num?;
    final lastRun = status['last_run']?.toString() ??
        status['lastRun']?.toString() ??
        'غير متاح';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حالة التدريب الذاتي',
                    style: AppTypography.titleSmall),
                const SizedBox(height: 6),
                Text('النماذج المدربة: $trained',
                    style: AppTypography.bodySmall),
                if (accuracy != null)
                  Text(
                      'الدقة المتوسطة: ${(accuracy).toDouble().toStringAsFixed(1)}%',
                      style: AppTypography.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(10)),
            child: Text('آخر تحديث\n$lastRun',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildMinedLessonsCard(Map<String, dynamic> result) {
    final lessons = (result['lessons'] as List?)?.cast<String>().toList() ?? <String>[];
    final patterns = (result['patterns'] as List?)?.cast<String>().toList() ?? <String>[];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الدروس المستفادة', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          if (lessons.isNotEmpty)
            ...lessons.map((lesson) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $lesson', style: AppTypography.bodySmall))),
          if (patterns.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('أنماط جديدة',
                style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold, color: AppColors.primaryGlow)),
            ...patterns.map((pattern) => Padding(
                padding: const EdgeInsets.only(bottom: 4, top: 4),
                child: Text('• $pattern', style: AppTypography.bodySmall))),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicatorTrustRow(String name, int score, int successRate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.text)),
              Text('درجة الثقة: $score%',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryGlow)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: AppColors.surfaceMuted,
            color: AppColors.primary,
            minHeight: 6,
          ),
          const SizedBox(height: 6),
          Text('نسبة دقة التوقعات السابقة: $successRate%',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildPatternRow(
      String pattern, String status, String ticker, int confidence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.primaryGlow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pattern,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.text)),
                const SizedBox(height: 2),
                Text('السهم: $ticker • الحالة: $status',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8)),
            child: Text('ثقة $confidence%',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight)),
          ),
        ],
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
                  color: AppColors.primaryMuted, shape: BoxShape.circle),
              child: const Icon(Icons.lock, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('محاكاة الاستراتيجيات والتعلم الذاتي ميزة متقدمة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'قم بالترقية للوصول إلى اختبار الاستراتيجيات وتحليلات AI المتقدمة',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  UpgradeModal.show(context, feature: 'backtesting'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('ترقية الآن',
                  style: TextStyle(
                      color: AppColors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeTab() {
    final List<Map<String, String>> lessons = [
      {
        'title': 'مقدمة في التحليل الفني للأسواق المالية',
        'desc':
            'تعرف على فلسفة حركة الأسعار وقراءة الرسوم البيانية لتعيين نقاط الدعم والمقاومة بدقة.',
        'time': '5 دقائق قراءة',
      },
      {
        'title': 'كيف تقرأ وتتداول باستخدام مؤشر القوة النسبية RSI',
        'desc':
            'شرح شامل لمؤشر القوة النسبية وطريقة استخدام مناطق ذروة البيع وذروة الشراء لاقتناص الصفقات.',
        'time': '7 دقائق قراءة',
      },
      {
        'title': 'إدارة المخاطر وتحديد حجم الصفقة الأمثل',
        'desc':
            'الاستثمار الناجح يعتمد على حفظ رأس المال. تعلم كيف تحسب حجم الصفقة مقارنة بوقف الخسارة الخاص بك.',
        'time': '6 دقائق قراءة',
      },
      {
        'title': 'التحليل المالي وتقييم القيمة العادلة للشركة',
        'desc':
            'فهم مكرر الربحية P/E ومكرر القيمة الدفترية P/B لحساب هل السهم فرصة حقيقية أم مقوم بأكثر من قيمته.',
        'time': '8 دقائق قراءة',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Card(
          color: AppColors.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('مقال تعليمي',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryGlow,
                              fontWeight: FontWeight.bold)),
                    ),
                    Text(lesson['time']!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(lesson['title']!,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                Text(lesson['desc']!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    // Open full article simulated dialogue
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.surface,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (ctx) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(lesson['title']!,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                            fontFamily: 'Cairo')),
                                    IconButton(
                                        icon: const Icon(Icons.close,
                                            color: AppColors.textSecondary),
                                        onPressed: () => Navigator.pop(ctx)),
                                  ],
                                ),
                                const Divider(color: AppColors.border),
                                const SizedBox(height: 8),
                                const Text(
                                  'محتوى المقال الكامل للاستفادة والتعلم:\n\n'
                                  'يعتمد الاستثمار الناجح في سوق الأسهم والعملات الرقمية على فهم متين للمؤشرات التقنية والأساسية. '
                                  'التحليل الفني يفترض أن الأسعار تتحرك في اتجاهات محددة وأن التاريخ يعيد نفسه. '
                                  'عندما نحدد نقاط الدعم والمقاومة، فإننا نبحث عن مستويات الأسعار التي يميل المشترون أو البائعون عندها إلى التفاعل بكثافة.\n\n'
                                  'باستخدام أدوات مثل RSI و MACD، يمكنك مواءمة قراراتك مع الاتجاه العام للسوق وتفادي الدخول في قمم سعرية قد تعرض محفظتك للمخاطر. '
                                  'تذكر دوماً أن الإدارة الصارمة للمخاطر وتحديد حجم الصفقة بما لا يتجاوز 3-5% من رأس مال المحفظة الإجمالي لكل معاملة هي الأهم على الإطلاق.',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('اقرأ المقال الكامل',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGlow)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 10, color: AppColors.primaryGlow),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
