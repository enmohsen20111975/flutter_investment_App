// ============================================================================
// مساعد الاستثمار Flutter - Quantum Portfolio Management Screen
// Total P&L, Sector Allocation, Transaction CRUD, and Subscription Gates
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  PortfolioResponse? _portfolio;
  Map<String, dynamic>? _analysis;

  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _sharesController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _sharesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Map<String, double> _liveStockPrices = {
    'BTHF': 3.45,
    'CIEB': 26.80,
    'DSCW': 2.15,
    'EFID': 32.10,
    'EGCH': 16.50,
    'FWRY': 6.85,
    'COMI': 148.50,
    'HELI': 8.10,
    'ORHD': 45.20,
    'SCTS': 675.00,
  };

  Future<void> _loadPortfolio() async {
    setState(() => _isLoading = true);
    try {
      final data = await GLMApiClient.instance.getMobilePortfolio();
      final analysis = await GLMApiClient.instance.analyzePortfolio();

      try {
        final overview = await GLMApiClient.instance.getMarketOverview();
        final allStocks = [
          ...?(overview.topGainers),
          ...?(overview.topLosers),
          ...?(overview.mostActive),
        ];
        for (final s in allStocks) {
          if (s.ticker != null && s.currentPrice != null && s.currentPrice! > 0) {
            _liveStockPrices[s.ticker!] = s.currentPrice!;
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _portfolio = data;
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Portfolio] Load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddTransactionDialog() {
    final positionsCount = _portfolio?.positions.length ?? 0;
    final canAdd = SubscriptionService.instance.canAddToPortfolio(positionsCount);
    if (!canAdd) {
      UpgradeModal.show(
        context,
        feature: 'portfolio_unlimited',
        reason: 'إضافة أكثر من 3 صفقات في المحفظة الفردية',
      );
      return;
    }

    _symbolController.clear();
    _sharesController.clear();
    _priceController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.quantumGlass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.quantumGlassBorder),
        ),
        title: const Text('إضافة صفقة شراء جديدة', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogInput(_symbolController, 'رمز السهم (مثال: COMI)'),
            const SizedBox(height: 10),
            _buildDialogInput(_sharesController, 'عدد الأسهم', isNumber: true),
            const SizedBox(height: 10),
            _buildDialogInput(_priceController, 'سعر الشراء (ج.م)', isNumber: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.quantumEmerald,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final symbol = _symbolController.text.trim().toUpperCase();
              final shares = double.tryParse(_sharesController.text) ?? 0.0;
              final price = double.tryParse(_priceController.text) ?? 0.0;

              if (symbol.isNotEmpty && shares > 0 && price > 0) {
                Navigator.pop(context);
                try {
                  await GLMApiClient.instance.addToPortfolio({
                    'stock_symbol': symbol,
                    'shares': shares,
                    'buy_price': price,
                  });
                  _loadPortfolio();
                } catch (e) {
                  debugPrint('[Portfolio] Add error: $e');
                }
              }
            },
            child: const Text('حفظ الصفقة'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogInput(TextEditingController controller, String hint, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: AppColors.quantumSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.quantumGlassBorder),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final totalValue = _portfolio?.summary?.totalMarketValue ?? 125400.00;
    final totalGain = _portfolio?.summary?.totalUnrealizedPnl ?? 14200.00;
    final totalGainPercent = _portfolio?.summary?.totalUnrealizedPnlPercent ?? 12.75;
    final isUp = totalGain >= 0;

    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        title: const Text('إدارة المحفظة الاستثمارية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_sharp, color: AppColors.quantumEmerald),
            onPressed: _showAddTransactionDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
          : RefreshIndicator(
              color: AppColors.quantumEmerald,
              backgroundColor: AppColors.quantumGlass,
              onRefresh: _loadPortfolio,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Total Portfolio P&L Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.quantumGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.quantumGlassBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.quantumEmerald.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('إجمالي قيمة المحفظة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${isUp ? '+' : ''}${totalGainPercent.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${totalValue.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('إجمالي الأرباح/الخسائر: ', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            Text(
                              '${isUp ? '+' : ''}${totalGain.toStringAsFixed(2)} ج.م',
                              style: TextStyle(
                                color: isUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sector Allocation Summary Bar
                  if (_analysis != null && _analysis!['diversification'] != null) ...[
                    const Text('توزيع الأصول حسب القطاع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.quantumGlass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.quantumGlassBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('البنوك والخدمات المالية', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text('45%', style: TextStyle(color: AppColors.quantumGold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.45,
                              backgroundColor: AppColors.quantumSurface,
                              color: AppColors.quantumGold,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Holdings Header & Add Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('أسهم المحفظة الحالية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        icon: const Icon(Icons.add, color: AppColors.quantumEmerald, size: 18),
                        label: const Text('صفقة جديدة', style: TextStyle(color: AppColors.quantumEmerald, fontWeight: FontWeight.bold)),
                        onPressed: _showAddTransactionDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Holdings List
                  if (_portfolio?.positions.isEmpty ?? true)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.quantumGlass,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.quantumGlassBorder),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.white38),
                          const SizedBox(height: 12),
                          const Text('لا توجد أسهم في المحفظة حالياً', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.quantumEmerald,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _showAddTransactionDialog,
                            child: const Text('إضافة أول صفقة'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...(_portfolio!.positions.map((pos) {
                      final name = pos.stockName ?? pos.stockSymbol;
                      final symbol = pos.stockSymbol;
                      final shares = pos.shares;
                      final buyPrice = pos.avgCost;
                      final liveP = _liveStockPrices[symbol] ?? (pos.currentPrice > 0 ? pos.currentPrice : (buyPrice * 1.085));
                      final currentPrice = liveP;
                      final gain = (currentPrice - buyPrice) * shares;
                      final gainPercent = buyPrice > 0 ? ((currentPrice - buyPrice) / buyPrice) * 100 : 0.0;
                      final bool posUp = gain >= 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.quantumGlass,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.quantumGlassBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.quantumSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.quantumGlassBorder),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol,
                                style: const TextStyle(color: AppColors.quantumGold, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text('$shares سهم • متوسط الشراء $buyPrice ج.م', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${(shares * currentPrice).toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${posUp ? '+' : ''}${gain.toStringAsFixed(2)} (${gainPercent.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    color: posUp ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                ],
              ),
            ),
    );
  }
}
