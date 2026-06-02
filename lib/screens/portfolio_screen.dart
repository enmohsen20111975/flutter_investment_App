// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Screen
// Full CRUD: View, Add, Remove positions
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  PortfolioResponse? _data;
  Map<String, dynamic>? _analysis;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      
      debugPrint('[Portfolio] Loading portfolio data...');
      
      final results = await Future.wait([
        api.getPortfolio(),
        api.analyzePortfolio().catchError((e) {
          debugPrint('[Portfolio] Analysis error: $e');
          return <String, dynamic>{};
        }),
      ]);
      
      _data = results[0] as PortfolioResponse;
      _analysis = results[1] as Map<String, dynamic>?;
      
      debugPrint('[Portfolio] Loaded ${_data?.positions.length ?? 0} positions');
      
      setState(() { _loading = false; _refreshing = false; });
    } catch (e) {
      debugPrint('[Portfolio] Error loading data: $e');
      setState(() { _error = 'فشل تحميل المحفظة. اسحب للتحديث.'; _loading = false; _refreshing = false; });
    }
  }

  Future<void> _showAddDialog() async {
    if (!SubscriptionService.instance.canAddToPortfolio(_data?.positions.length ?? 0)) {
      UpgradeModal.show(context, feature: 'portfolio_unlimited', reason: 'لقد وصلت للحد الأقصى (3 أسهم) في المحفظة');
      return;
    }

    final tickerCtrl = TextEditingController();
    final sharesCtrl = TextEditingController();
    final avgCostCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة سهم للمحفظة', style: TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tickerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رمز السهم *',
                      hintText: 'مثال: COMI',
                      prefixIcon: Icon(Icons.trending_up, size: 20),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sharesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأسهم *',
                      prefixIcon: Icon(Icons.numbers, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: avgCostCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'متوسط سعر الشراء *',
                      suffixText: 'ج.م',
                      prefixIcon: Icon(Icons.attach_money, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      prefixIcon: Icon(Icons.note, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: submitting ? null : () async {
                  final ticker = tickerCtrl.text.trim().toUpperCase();
                  final shares = int.tryParse(sharesCtrl.text) ?? 0;
                  final avgCost = double.tryParse(avgCostCtrl.text) ?? 0;
                  if (ticker.isEmpty || shares <= 0 || avgCost <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  setDialogState(() => submitting = true);
                  try {
                    await api.addToPortfolio({
                      'stock_symbol': ticker,
                      'shares': shares,
                      'avg_cost': avgCost,
                      'notes': notesCtrl.text.trim(),
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إضافة السهم للمحفظة'), backgroundColor: AppColors.success),
                      );
                      _loadData(silent: true);
                    }
                  } catch (e) {
                    setDialogState(() => submitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل الإضافة: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                    : const Text('إضافة', style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removePosition(PortfolioPosition pos) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف السهم'),
          content: Text('هل تريد حذف ${pos.stockSymbol} من المحفظة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('حذف', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      try {
        await api.removeFromPortfolio(pos.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السهم'), backgroundColor: AppColors.success),
        );
        _loadData(silent: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderCard(icon: Icons.wallet, title: 'المحفظة الاستثمارية', subtitle: 'تتبع استثماراتك وتابع أداءها'),
              const SizedBox(height: 16),
              
              if (_loading)
                const StateView(loading: true)
              else if (_error != null && _data == null)
                StateView(error: _error, onRetry: () => _loadData())
              else ...[
                if (_data?.summary != null) _buildSummary(),
                const SizedBox(height: 16),
                if (_analysis != null && _analysis!.isNotEmpty) _buildAnalysis(),
                const SizedBox(height: 16),
                // Positions list
                if (_data?.positions.isEmpty ?? true)
                  const StateView(empty: true, emptyMessage: 'المحفظة فارغة. أضف أسهم لتتبعها.')
                else
                  ..._data!.positions.map((pos) => _buildPositionCard(pos)),
              ],
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysis() {
    final a = _analysis!;
    final diversification = a['diversification_score'] as num?;
    final riskLevel = a['risk_level']?.toString() ?? '';
    final recommendations = (a['recommendations'] as List?)?.cast<String>() ?? [];
    final sectorBreakdown = a['sector_breakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.analytics, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('تحليل المحفظة', style: AppTypography.titleSmall),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (diversification != null)
                _buildAnalysisMetric('التنويع', '${diversification.toDouble().toStringAsFixed(0)}%', AppColors.info),
              if (riskLevel.isNotEmpty)
                _buildAnalysisMetric('مستوى المخاطر', riskLevel, riskLevel == 'high' ? AppColors.danger : AppColors.success),
              ...sectorBreakdown.entries.map((e) => _buildAnalysisMetric(e.key, '${e.value}', AppColors.textSecondary)),
            ],
          ),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...recommendations.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primary)),
                  Expanded(child: Text(r, style: AppTypography.bodySmall)),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _buildSummary() {
    final s = _data!.summary!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('ملخص المحفظة', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('عدد الأسهم', '${s.totalPositions}', Icons.pie_chart)),
              Expanded(child: _buildSummaryItem('التكلفة', _formatCurrency(s.totalCostBasis), Icons.payments)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('القيمة الحالية', _formatCurrency(s.totalMarketValue), Icons.account_balance_wallet)),
              Expanded(
                child: _buildSummaryItem(
                  'الربح/الخسارة',
                  '${s.totalUnrealizedPnlPercent >= 0 ? '+' : ''}${s.totalUnrealizedPnlPercent.toStringAsFixed(2)}%',
                  s.totalUnrealizedPnl >= 0 ? Icons.trending_up : Icons.trending_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي الربح/الخسارة', style: TextStyle(color: AppColors.white, fontSize: 13)),
                Text(
                  '${s.totalUnrealizedPnl >= 0 ? '+' : ''}${_formatCurrency(s.totalUnrealizedPnl)}',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildPositionCard(PortfolioPosition pos) {
    final isProfit = pos.unrealizedPnl >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
                  color: isProfit ? AppColors.successLight : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isProfit ? Icons.trending_up : Icons.trending_down,
                  color: isProfit ? AppColors.success : AppColors.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(pos.stockName ?? pos.stockSymbol, style: AppTypography.titleSmall),
                     if (pos.stockName != null && pos.stockName != pos.stockSymbol)
                       Text(pos.stockSymbol, style: AppTypography.bodySmall),
                   ],
                 ),
               ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pos.shares} سهم', style: AppTypography.bodySmall),
                  Text(_formatCurrency(pos.marketValue), style: AppTypography.titleSmall),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                onPressed: () => _removePosition(pos),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _buildDetailItem('متوسط التكلفة', _formatCurrency(pos.avgCost)),
              _buildDetailItem('السعر الحالي', _formatCurrency(pos.currentPrice)),
              _buildDetailItem('الربح/الخسارة', _formatCurrency(pos.unrealizedPnl),
                color: isProfit ? AppColors.success : AppColors.danger),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pos.unrealizedPnlPercent.abs() / 50).clamp(0, 1),
              backgroundColor: AppColors.surfaceMuted,
              color: isProfit ? AppColors.success : AppColors.danger,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('التكلفة: ${_formatCurrency(pos.costBasis)}', style: AppTypography.bodySmall),
              Text(
                '${isProfit ? '+' : ''}${pos.unrealizedPnlPercent.toStringAsFixed(2)}%',
                style: AppTypography.bodySmall.copyWith(
                  color: isProfit ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.titleSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2)} ج.م';
  }
}
