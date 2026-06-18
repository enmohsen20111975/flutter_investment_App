// ============================================================================
// مساعد الاستثمار Flutter - Unified Portfolio Screen
// Multi-asset support: Stocks, Crypto, Gold & Metals
// Full CRUD: View, Add, Remove positions
// ============================================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  Future<PortfolioResponse?>? _portfolioFuture;
  Future<Map<String, dynamic>?>? _analysisFuture;

  // Active Category: 'stock', 'crypto', 'gold'
  String _selectedCategory = 'stock';

  @override
  void initState() {
    super.initState();
    _portfolioFuture = _fetchPortfolio();
    _analysisFuture = _fetchAnalysis();
  }

  Future<PortfolioResponse?> _fetchPortfolio() async {
    try {
      // Use mobile endpoint for portfolio data
      return await api.getMobilePortfolio();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchAnalysis() async {
    try {
      return await api.analyzePortfolio();
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _portfolioFuture = _fetchPortfolio();
    _analysisFuture = _fetchAnalysis();
    if (mounted) setState(() {});
  }

  List<PortfolioPosition> _getFilteredPositions(PortfolioResponse data) {
    final allItems = data.items ?? data.positions;
    return allItems.where((pos) {
      final type = pos.type?.toLowerCase() ?? 'stock';
      if (_selectedCategory == 'gold') {
        return type == 'gold' || type == 'metal' || type == 'silver';
      }
      return type == _selectedCategory;
    }).toList();
  }

  Future<void> _showAddDialog() async {
    try {
      final data = await _portfolioFuture;
      final totalCount = (data?.items ?? data?.positions)?.length ?? 0;
      if (!SubscriptionService.instance.canAddToPortfolio(totalCount)) {
        UpgradeModal.show(context,
            feature: 'portfolio_unlimited',
            reason: 'لقد وصلت للحد الأقصى (3 أصول) في المحفظة المجانية');
        return;
      }
    } catch (_) {
      UpgradeModal.show(context,
          feature: 'portfolio_unlimited',
          reason: 'لقد وصلت للحد الأقصى (3 أصول) في المحفظة المجانية');
      return;
    }

    String type = _selectedCategory;
    final symbolCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final avgPriceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة أصل للمحفظة',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Type Selector Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'نوع الأصل'),
                    items: const [
                      DropdownMenuItem(value: 'stock', child: Text('سهم')),
                      DropdownMenuItem(
                          value: 'crypto', child: Text('عملة رقمية')),
                      DropdownMenuItem(
                          value: 'gold', child: Text('ذهب ومعادن')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          type = val;
                          if (type == 'gold') {
                            symbolCtrl.text = 'GOLD';
                          } else {
                            symbolCtrl.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Symbol or Karat input
                  if (type == 'gold')
                    DropdownButtonFormField<String>(
                      initialValue:
                          symbolCtrl.text.isEmpty ? 'GOLD' : symbolCtrl.text,
                      decoration:
                          const InputDecoration(labelText: 'العيار / المعدن'),
                      items: const [
                        DropdownMenuItem(
                            value: 'GOLD_24', child: Text('ذهب عيار 24')),
                        DropdownMenuItem(
                            value: 'GOLD_21', child: Text('ذهب عيار 21')),
                        DropdownMenuItem(
                            value: 'GOLD_18', child: Text('ذهب عيار 18')),
                        DropdownMenuItem(
                            value: 'GOLD', child: Text('أوقية الذهب')),
                        DropdownMenuItem(value: 'SILVER', child: Text('فضة')),
                      ],
                      onChanged: (val) {
                        if (val != null) symbolCtrl.text = val;
                      },
                    )
                  else
                    TextField(
                      controller: symbolCtrl,
                      decoration: InputDecoration(
                        labelText: type == 'crypto'
                            ? 'رمز العملة (مثال: BTC)'
                            : 'رمز السهم (مثال: COMI)',
                        prefixIcon: const Icon(Icons.label_outline, size: 20),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  const SizedBox(height: 12),

                  // Quantity input
                  TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'gold'
                          ? 'الوزن (بالجرام أو الأوقية)'
                          : 'الكمية *',
                      prefixIcon: const Icon(Icons.numbers, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Avg buy price input
                  TextField(
                    controller: avgPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == 'gold'
                          ? 'سعر الشراء للجرام/الأوقية *'
                          : 'متوسط سعر الشراء *',
                      suffixText: type == 'crypto' ? 'USD' : 'ج.م',
                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes input
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
                onPressed: submitting
                    ? null
                    : () async {
                        final symbol = symbolCtrl.text.trim().toUpperCase();
                        final quantity =
                            double.tryParse(quantityCtrl.text) ?? 0;
                        final avgPrice =
                            double.tryParse(avgPriceCtrl.text) ?? 0;

                        if (symbol.isEmpty || quantity <= 0 || avgPrice <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'يرجى ملء جميع الحقول المطلوبة بالشكل الصحيح'),
                                backgroundColor: AppColors.danger),
                          );
                          return;
                        }

                        setDialogState(() => submitting = true);
                        try {
                          await api.addToPortfolio({
                            'type': type,
                            'stock_ticker': symbol,
                            'quantity': quantity,
                            'avg_buy_price': avgPrice,
                            'notes': notesCtrl.text.trim(),
                          });
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم إضافة الأصل للمحفظة بنجاح'),
                                  backgroundColor: AppColors.success),
                            );
                            _refresh();
                          }
                        } catch (e) {
                          setDialogState(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('فشل الإضافة: $e'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : const Text('إضافة',
                        style: TextStyle(color: AppColors.white)),
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
          title: const Text('حذف الأصل'),
          content: Text('هل تريد حذف ${pos.stockSymbol} من المحفظة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child:
                  const Text('حذف', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      try {
        await api.removeFromPortfolio(pos.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف الأصل من المحفظة'),
              backgroundColor: AppColors.success),
        );
        _refresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل الحذف: $e'),
              backgroundColor: AppColors.danger),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
        body: FutureBuilder<PortfolioResponse?>(
          future: _portfolioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return StateView(
                  error: snapshot.hasError
                      ? snapshot.error.toString()
                      : 'فشل تحميل المحفظة',
                  onRetry: _refresh);
            }

            final data = snapshot.data!;
            final filteredList = _getFilteredPositions(data);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeaderCard(
                        icon: Icons.account_balance_wallet,
                        title: 'المحفظة الاستثمارية الموحدة',
                        subtitle:
                            'تابع أداء كافة أصولك الاستثمارية في مكان واحد'),
                    const SizedBox(height: 16),

                    // Portfolio Summary
                    _buildSummary(data),
                    const SizedBox(height: 16),

                    // Choice Chips Category Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                              'stock', 'الأسهم 📈', Icons.trending_up),
                          const SizedBox(width: 8),
                          _buildCategoryChip('crypto', 'العملات الرقمية ₿',
                              Icons.currency_bitcoin),
                          const SizedBox(width: 8),
                          _buildCategoryChip('gold', 'الذهب والمعادن 💰',
                              Icons.diamond_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Positions List
                    if (filteredList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedCategory == 'stock'
                              ? 'لا توجد أسهم مضافة حالياً.'
                              : _selectedCategory == 'crypto'
                                  ? 'لا توجد عملات رقمية مضافة حالياً.'
                                  : 'لا توجد معادن أو سبائك ذهبية مضافة.',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    else
                      ...filteredList.map((pos) => _buildPositionCard(pos)),
                    const SizedBox(height: 16),

                    // AI Analysis Section
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _analysisFuture,
                      builder: (context, analysisSnapshot) {
                        if (analysisSnapshot.hasData &&
                            analysisSnapshot.data != null) {
                          return _buildAnalysis(analysisSnapshot.data!, data);
                        }
                        return const SizedBox.shrink();
                      },
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

  Widget _buildCategoryChip(String category, String label, IconData icon) {
    final active = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: active ? AppColors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: active ? AppColors.white : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(PortfolioResponse data) {
    final s = data.summary;
    if (s == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إجمالي قيمة المحفظة',
                  style: TextStyle(color: AppColors.white, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${s.totalUnrealizedPnlPercent >= 0 ? '+' : ''}${s.totalUnrealizedPnlPercent.toStringAsFixed(2)}%',
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _formatCurrency(s.totalMarketValue, 'EGP'),
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryItem('إجمالي المستثمر',
                      _formatCurrency(s.totalCostBasis, 'EGP'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildSummaryItem('صافي الربح/الخسارة',
                      _formatCurrency(s.totalUnrealizedPnl, 'EGP'),
                      isProfit: s.totalUnrealizedPnl >= 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool? isProfit}) {
    Color valColor = AppColors.white;
    if (isProfit != null) {
      valColor = isProfit ? AppColors.white : Colors.red[200]!;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.7), fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPositionCard(PortfolioPosition pos) {
    final isProfit = pos.unrealizedPnl >= 0;
    final currency = _selectedCategory == 'crypto' ? 'USD' : 'ج.م';

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
                  color:
                      isProfit ? AppColors.successLight : AppColors.dangerLight,
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
                    Text(pos.stockName ?? pos.stockSymbol,
                        style: AppTypography.titleSmall),
                    if (pos.stockSymbol.isNotEmpty &&
                        pos.stockName != pos.stockSymbol)
                      Text(pos.stockSymbol, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      _selectedCategory == 'gold'
                          ? '${pos.shares} جرام'
                          : '${pos.shares} وحدة',
                      style: AppTypography.bodySmall),
                  Text(_formatCurrency(pos.marketValue, currency),
                      style: AppTypography.titleSmall),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
                onPressed: () => _removePosition(pos),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _buildDetailItem(
                  'متوسط التكلفة', _formatCurrency(pos.avgCost, currency)),
              _buildDetailItem(
                  'السعر الحالي', _formatCurrency(pos.currentPrice, currency)),
              _buildDetailItem(
                  'الربح/الخسارة', _formatCurrency(pos.unrealizedPnl, currency),
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
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  'التكلفة الإجمالية: ${_formatCurrency(pos.costBasis, currency)}',
                  style: AppTypography.bodySmall),
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
          Text(value,
              style: AppTypography.titleSmall
                  .copyWith(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  List<MapEntry<String, double>> _getCategoryBreakdown(PortfolioResponse data) {
    final items = data.items ?? data.positions;
    final totals = <String, double>{};
    for (final pos in items) {
      final value = pos.marketValue > 0 ? pos.marketValue : pos.costBasis;
      if (value <= 0) continue;
      final label = _categoryLabel(pos);
      totals[label] = (totals[label] ?? 0) + value;
    }
    return totals.entries.where((e) => e.value > 0).toList();
  }

  String _categoryLabel(PortfolioPosition pos) {
    final type = (pos.type ?? '').toLowerCase();
    if (type == 'crypto') return 'العملات الرقمية';
    if (type == 'gold' || type == 'metal' || type == 'silver') {
      return 'الذهب والمعادن';
    }
    if (type == 'fund') return 'الصناديق';
    if (type == 'certificate') return 'الشهادات';
    return 'الأسهم';
  }

  Widget _buildAssetAllocationChart(List<MapEntry<String, double>> breakdown) {
    final total = breakdown.fold<double>(0, (sum, e) => sum + e.value);
    if (total <= 0 || breakdown.isEmpty) return const SizedBox.shrink();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.neonCyan,
    ];

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PieChart(
            PieChartData(
              sections: breakdown.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value.value;
                return PieChartSectionData(
                  value: value,
                  title: '${((value / total) * 100).toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  color: colors[index % colors.length],
                  radius: 62,
                  titlePositionPercentageOffset: 0.58,
                );
              }).toList(),
              centerSpaceRadius: 42,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: breakdown.asMap().entries.map((entry) {
            final index = entry.key;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  color: colors[index % colors.length].withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(entry.value.key,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnalysis(Map<String, dynamic> a, PortfolioResponse data) {
    final diversification = a['diversification_score'] as num?;
    final riskLevel = a['risk_level']?.toString() ?? '';
    final recommendations =
        (a['recommendations'] as List?)?.cast<String>().toList() ?? <String>[];
    final sectorBreakdown =
        a['sector_breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = _getCategoryBreakdown(data);

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
          const Row(children: [
            Icon(Icons.analytics, size: 18, color: AppColors.primaryGlow),
            SizedBox(width: 8),
            Text('تحليل وتوزيع المحفظة الذكي', style: AppTypography.titleSmall),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (diversification != null)
                _buildAnalysisMetric(
                    'مؤشر التنويع',
                    '${diversification.toDouble().toStringAsFixed(0)}%',
                    AppColors.neonCyan),
              if (riskLevel.isNotEmpty)
                _buildAnalysisMetric(
                    'مستوى المخاطر العامة',
                    riskLevel == 'low'
                        ? 'منخفض'
                        : riskLevel == 'medium'
                            ? 'متوسط'
                            : 'مرتفع',
                    riskLevel == 'high' ? AppColors.danger : AppColors.success),
              ...sectorBreakdown.entries.map((e) => _buildAnalysisMetric(
                  e.key, '${e.value}', AppColors.textSecondary)),
            ],
          ),
          if (breakdown.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAssetAllocationChart(breakdown),
          ],
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('توصيات الذكاء الاصطناعي للمحفظة:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight)),
            const SizedBox(height: 4),
            ...recommendations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(color: AppColors.primaryGlow)),
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
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        Text(value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  String _formatCurrency(double value, String currency) {
    return '${value.toStringAsFixed(2)} ${currency == 'USD' ? '\$' : 'ج.م'}';
  }
}
