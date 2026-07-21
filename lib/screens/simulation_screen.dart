// ============================================================================
// مساعد الاستثمار Flutter - Simulation Screen (Paper Trading)
// Virtual trading with no real money — practice strategies safely
// API: /api/v2/recommend (for tradeable tickers) + local state
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  static const double _initialCapital = 100000.0; // virtual 100k EGP
  static const String _kCashKey = 'sim_cash';
  static const String _kPositionsKey = 'sim_positions';
  static const String _kTradesKey = 'sim_trades';

  late TabController _tabController;
  double _cash = _initialCapital;
  List<_SimPosition> _positions = [];
  List<_SimTrade> _trades = [];
  Future<List<_SimStock>>? _marketFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadState();
    _marketFuture = _fetchMarket();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cash = prefs.getDouble(_kCashKey) ?? _initialCapital;
      final posStr = prefs.getString(_kPositionsKey);
      if (posStr != null) {
        final list = jsonDecode(posStr) as List;
        _positions = list
            .map((e) => _SimPosition.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      final trStr = prefs.getString(_kTradesKey);
      if (trStr != null) {
        final list = jsonDecode(trStr) as List;
        _trades = list
            .map((e) => _SimTrade.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kCashKey, _cash);
      await prefs.setString(
          _kPositionsKey, jsonEncode(_positions.map((p) => p.toMap()).toList()));
      await prefs.setString(
          _kTradesKey, jsonEncode(_trades.map((t) => t.toMap()).toList()));
    } catch (_) {}
  }

  Future<List<_SimStock>> _fetchMarket() async {
    try {
      final raw = await api.getHunterScreener(market: 'EGX', limit: 20);
      final stocks = <_SimStock>[];
      for (final e in raw) {
        if (e is Map) {
          stocks.add(_SimStock.fromMap(Map<String, dynamic>.from(e)));
        }
      }
      // Update price cache outside of build
      _positionsCache.clear();
      for (final s in stocks) {
        if (s.currentPrice != null) {
          _positionsCache[s.ticker] = s.currentPrice!;
        }
      }
      if (mounted) setState(() {});
      return stocks;
    } catch (_) {
      return <_SimStock>[];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _marketFuture = _fetchMarket();
    });
  }

  void _resetSim() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إعادة تعيين المحاكاة'),
          content: const Text(
              'سيتم حذف كل المراكز والصفقات وإعادة الرصيد إلى 100,000. هل أنت متأكد؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إعادة تعيين',
                  style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      _cash = _initialCapital;
      _positions = [];
      _trades = [];
      await _saveState();
      if (mounted) setState(() {});
    }
  }

  void _showTradeSheet(_SimStock stock, bool isBuy) {
    final qtyCtrl = TextEditingController(text: '10');
    final priceCtrl = TextEditingController(
      text: stock.currentPrice?.toStringAsFixed(2) ?? '',
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setSheetState) {
            final qty = int.tryParse(qtyCtrl.text) ?? 0;
            final price = double.tryParse(priceCtrl.text) ?? 0;
            final total = qty * price;
            final canAfford = isBuy ? total <= _cash : qty > 0 && _hasPosition(stock.ticker, qty);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isBuy ? Icons.trending_up : Icons.trending_down,
                        color: isBuy ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isBuy ? 'شراء' : 'بيع'} ${stock.ticker}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الكمية',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر للسهم',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Text('الإجمالي:',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        const Spacer(),
                        Text(
                          total.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isBuy ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!canAfford) ...[
                    const SizedBox(height: 8),
                    Text(
                      isBuy
                          ? 'رصيدك غير كافٍ (المتاح: ${_cash.toStringAsFixed(2)})'
                          : 'لا تملك هذه الكمية في محفظتك',
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isBuy
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          onPressed: canAfford && qty > 0 && price > 0
                              ? () {
                                  _executeTrade(stock, qty, price, isBuy);
                                  Navigator.pop(ctx);
                                }
                              : null,
                          child: Text(isBuy ? 'تنفيذ الشراء' : 'تنفيذ البيع',
                              style: const TextStyle(color: AppColors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _hasPosition(String ticker, int qty) {
    final pos = _positions.where((p) => p.ticker == ticker).toList();
    if (pos.isEmpty) return false;
    return pos.first.quantity >= qty;
  }

  void _executeTrade(_SimStock stock, int qty, double price, bool isBuy) {
    final total = qty * price;
    if (isBuy) {
      _cash -= total;
      final existing =
          _positions.where((p) => p.ticker == stock.ticker).toList();
      if (existing.isEmpty) {
        _positions.add(_SimPosition(
          ticker: stock.ticker,
          displayName: stock.displayName,
          quantity: qty,
          avgPrice: price,
          openedAt: DateTime.now().toIso8601String(),
        ));
      } else {
        final p = existing.first;
        final newQty = p.quantity + qty;
        final newAvg = ((p.avgPrice * p.quantity) + (price * qty)) / newQty;
        _positions.remove(p);
        _positions.add(_SimPosition(
          ticker: p.ticker,
          displayName: p.displayName,
          quantity: newQty,
          avgPrice: newAvg,
          openedAt: p.openedAt,
        ));
      }
    } else {
      _cash += total;
      final existing =
          _positions.where((p) => p.ticker == stock.ticker).toList();
      if (existing.isNotEmpty) {
        final p = existing.first;
        final newQty = p.quantity - qty;
        _positions.remove(p);
        if (newQty > 0) {
          _positions.add(_SimPosition(
            ticker: p.ticker,
            displayName: p.displayName,
            quantity: newQty,
            avgPrice: p.avgPrice,
            openedAt: p.openedAt,
          ));
        }
      }
    }
    _trades.insert(
      0,
      _SimTrade(
        ticker: stock.ticker,
        action: isBuy ? 'BUY' : 'SELL',
        quantity: qty,
        price: price,
        timestamp: DateTime.now().toIso8601String(),
      ),
    );
    _saveState();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBuy
              ? 'تم تنفيذ شراء $qty من ${stock.ticker} @ ${price.toStringAsFixed(2)}'
              : 'تم تنفيذ بيع $qty من ${stock.ticker} @ ${price.toStringAsFixed(2)}',
        ),
        backgroundColor: isBuy ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  double get _positionsValue {
    return _positions.fold(0.0, (sum, p) {
      final market = _latestPrice(p.ticker);
      return sum + (market * p.quantity);
    });
  }

  double _latestPrice(String ticker) {
    // We'll resolve from cached market data if available
    // (best-effort — simulation can use avg price as fallback)
    return _positionsCache[ticker] ?? 0;
  }

  // Simple in-memory cache of latest market prices keyed by ticker
  final Map<String, double> _positionsCache = {};

  double get _totalEquity => _cash + _positionsValue;
  double get _totalPnl => _totalEquity - _initialCapital;
  double get _totalPnlPct =>
      _initialCapital > 0 ? (_totalPnl / _initialCapital) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            child: const Icon(Icons.science_outlined,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('محاكاة التداول',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('تدرب بدون مخاطر حقيقية',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.restart_alt_rounded,
                                color: AppColors.white),
                            onPressed: _resetSim,
                            tooltip: 'إعادة تعيين',
                          ),
                        ],
                      ),
                      _buildEquityHeader(),
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
                  tabs: const [
                    Tab(icon: Icon(Icons.storefront_rounded, size: 18), text: 'السوق'),
                    Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'محفظتي'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMarketTab(),
                  _buildPositionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityHeader() {
    final isProfit = _totalPnl >= 0;
    final pnlColor = isProfit ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إجمالي رأس المال',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _totalEquity.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: pnlColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${isProfit ? '+' : ''}${_totalPnl.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${isProfit ? '+' : ''}${_totalPnlPct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: pnlColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTab() {
    return FutureBuilder<List<_SimStock>>(
      future: _marketFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonList(itemCount: 5, itemHeight: 80);
        }
        if (snapshot.hasError) {
          return StateView(error: 'فشل تحميل السوق', onRetry: _refresh);
        }
        final stocks = snapshot.data ?? [];
        if (stocks.isEmpty) {
          return const StateView(
            empty: true,
            emptyMessage: 'لا توجد أسهم متاحة للمحاكاة',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: stocks.length,
            cacheExtent: 600,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final s = stocks[index];
              return _MarketRow(
                stock: s,
                onBuy: () => _showTradeSheet(s, true),
                onSell: () => _showTradeSheet(s, false),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPositionsTab() {
    if (_positions.isEmpty && _trades.isEmpty) {
      return const StateView(
        empty: true,
        emptyMessage: 'لم تنفذ أي صفقات بعد. ابدأ من تبويب السوق',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Cash balance
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surface, AppColors.surfaceMuted],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.accent),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('الرصيد النقدي المتاح',
                    style: TextStyle(fontSize: 13)),
              ),
              Text(
                _cash.toStringAsFixed(2),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Open positions
        if (_positions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('المراكز المفتوحة',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
          ..._positions.map((p) {
            final market = _latestPrice(p.ticker);
            final value = market * p.quantity;
            final cost = p.avgPrice * p.quantity;
            final pnl = value - cost;
            final pnlPct = cost > 0 ? (pnl / cost) * 100 : 0.0;
            final isProfit = pnl >= 0;
            final color = isProfit ? AppColors.success : AppColors.danger;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p.ticker,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                      Text('${p.quantity} سهم',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _posField('متوسط الشراء', p.avgPrice),
                      ),
                      Expanded(
                        child: _posField('السعر الحالي', market),
                      ),
                      Expanded(
                        child: _posField('القيمة', value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(isProfit ? Icons.trending_up : Icons.trending_down,
                            color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${isProfit ? '+' : ''}${pnl.toStringAsFixed(2)}  '
                          '(${isProfit ? '+' : ''}${pnlPct.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        // Recent trades
        if (_trades.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text('آخر الصفقات',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ),
          ..._trades.take(8).map((t) {
            final isBuy = t.action == 'BUY';
            final color = isBuy ? AppColors.success : AppColors.danger;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border(
                  right: BorderSide(color: color, width: 3),
                ),
              ),
              child: Row(
                children: [
                  Icon(isBuy ? Icons.arrow_upward : Icons.arrow_downward,
                      color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${isBuy ? 'شراء' : 'بيع'} ${t.quantity} × ${t.ticker}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    t.price.toStringAsFixed(2),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _posField(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value.toStringAsFixed(2),
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ============================================================================
// Market row
// ============================================================================
class _MarketRow extends StatelessWidget {
  final _SimStock stock;
  final VoidCallback onBuy;
  final VoidCallback onSell;

  const _MarketRow({
    required this.stock,
    required this.onBuy,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final change = stock.changePercent ?? 0;
    final isUp = change >= 0;
    final changeColor = isUp ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.ticker,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                if (stock.displayName.isNotEmpty &&
                    stock.displayName != stock.ticker)
                  Text(stock.displayName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      stock.currentPrice?.toStringAsFixed(2) ?? '--',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: changeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                width: 64,
                child: ElevatedButton(
                  onPressed: onBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(64, 30),
                  ),
                  child: const Text('شراء',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 64,
                child: ElevatedButton(
                  onPressed: onSell,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(64, 30),
                  ),
                  child: const Text('بيع',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Models
// ============================================================================
class _SimStock {
  final String ticker;
  final String displayName;
  final double? currentPrice;
  final double? changePercent;

  _SimStock({
    required this.ticker,
    required this.displayName,
    required this.currentPrice,
    required this.changePercent,
  });

  factory _SimStock.fromMap(Map<String, dynamic> m) {
    final ticker = (m['ticker'] ?? m['symbol'] ?? '').toString();
    final name = (m['name'] ?? m['company'] ?? '').toString();
    final nameAr = (m['name_ar'] ?? m['nameAr'] ?? '').toString();
    return _SimStock(
      ticker: ticker,
      displayName: nameAr.isNotEmpty ? nameAr : (name.isNotEmpty ? name : ticker),
      currentPrice: _toDouble(m['current_price'] ?? m['price'] ?? m['entry_price']),
      changePercent: _toDouble(m['change_percent'] ?? m['change']),
    );
  }
}

class _SimPosition {
  final String ticker;
  final String displayName;
  final int quantity;
  final double avgPrice;
  final String openedAt;

  _SimPosition({
    required this.ticker,
    required this.displayName,
    required this.quantity,
    required this.avgPrice,
    required this.openedAt,
  });

  Map<String, dynamic> toMap() => {
        'ticker': ticker,
        'displayName': displayName,
        'quantity': quantity,
        'avgPrice': avgPrice,
        'openedAt': openedAt,
      };

  factory _SimPosition.fromMap(Map<String, dynamic> m) => _SimPosition(
        ticker: (m['ticker'] ?? '').toString(),
        displayName: (m['displayName'] ?? '').toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        avgPrice: _toDouble(m['avgPrice']) ?? 0,
        openedAt: (m['openedAt'] ?? '').toString(),
      );
}

class _SimTrade {
  final String ticker;
  final String action;
  final int quantity;
  final double price;
  final String timestamp;

  _SimTrade({
    required this.ticker,
    required this.action,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'ticker': ticker,
        'action': action,
        'quantity': quantity,
        'price': price,
        'timestamp': timestamp,
      };

  factory _SimTrade.fromMap(Map<String, dynamic> m) => _SimTrade(
        ticker: (m['ticker'] ?? '').toString(),
        action: (m['action'] ?? 'BUY').toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        price: _toDouble(m['price']) ?? 0,
        timestamp: (m['timestamp'] ?? '').toString(),
      );
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
