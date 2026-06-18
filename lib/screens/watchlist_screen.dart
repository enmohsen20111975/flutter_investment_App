// ============================================================================
// مساعد الاستثمار Flutter - Unified Watchlist Screen
// Multi-asset support: Stocks, Crypto, Gold & Metals
// Full CRUD: View, Add, Remove items with price alerts
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../widgets/upgrade_modal.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  Future<WatchlistResponse?>? _listFuture;
  String _selectedCategory = 'stock'; // 'stock', 'crypto', 'gold'

  @override
  void initState() {
    super.initState();
    _listFuture = _fetchWatchlist();
  }

  Future<WatchlistResponse?> _fetchWatchlist() async {
    try {
      if (!await api.isAuthenticated()) return null;
      try {
        return await api.getWatchlistEnhanced();
      } catch (_) {
        return await api.getWatchlist();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _listFuture = _fetchWatchlist();
    if (mounted) setState(() {});
  }

  String _detectAssetType(String ticker) {
    final t = ticker.toLowerCase();
    if (t.contains('gold') ||
        t.contains('silver') ||
        t.contains('metal') ||
        t == 'ounce') {
      return 'gold';
    }
    final cryptoSymbols = {
      'btc',
      'eth',
      'sol',
      'usdt',
      'bnb',
      'xrp',
      'ada',
      'doge',
      'bitcoin',
      'ethereum',
      'solana',
      'binancecoin',
      'cardano',
      'ripple'
    };
    if (cryptoSymbols.contains(t)) {
      return 'crypto';
    }
    return 'stock';
  }

  List<WatchlistItem> _getFilteredItems(WatchlistResponse data) {
    return data.items.where((item) {
      final type = _detectAssetType(item.ticker);
      return type == _selectedCategory;
    }).toList();
  }

  Future<void> _showAddDialog() async {
    try {
      final data = await _listFuture;
      if (!SubscriptionService.instance
          .canAddToWatchlist(data?.items.length ?? 0)) {
        UpgradeModal.show(context,
            feature: 'watchlist_unlimited',
            reason: 'لقد وصلت للحد الأقصى (3 أصول) في قائمة المراقبة المجانية');
        return;
      }
    } catch (_) {
      UpgradeModal.show(context,
          feature: 'watchlist_unlimited',
          reason: 'لقد وصلت للحد الأقصى (3 أصول) في قائمة المراقبة المجانية');
      return;
    }

    String type = _selectedCategory;
    final symbolCtrl = TextEditingController();
    final alertAboveCtrl = TextEditingController();
    final alertBelowCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة أصل للمراقبة',
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
                            symbolCtrl.text = 'GOLD_24';
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
                          symbolCtrl.text.isEmpty ? 'GOLD_24' : symbolCtrl.text,
                      decoration:
                          const InputDecoration(labelText: 'العيار / المعدن'),
                      items: const [
                        DropdownMenuItem(
                            value: 'GOLD_24', child: Text('ذهب عيار 24')),
                        DropdownMenuItem(
                            value: 'GOLD_21', child: Text('ذهب عيار 21')),
                        DropdownMenuItem(
                            value: 'GOLD_18', child: Text('ذهب عيار 18')),
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
                        prefixIcon: const Icon(Icons.search, size: 20),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  const SizedBox(height: 12),

                  // Price Alert Above
                  TextField(
                    controller: alertAboveCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'تنبيه عندما يرتفع السعر فوق',
                      suffixText: type == 'crypto' ? 'USD' : 'ج.م',
                      prefixIcon: const Icon(Icons.arrow_upward,
                          size: 20, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Alert Below
                  TextField(
                    controller: alertBelowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'تنبيه عندما ينخفض السعر تحت',
                      suffixText: type == 'crypto' ? 'USD' : 'ج.م',
                      prefixIcon: const Icon(Icons.arrow_downward,
                          size: 20, color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات المراقبة (اختياري)',
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
                        if (symbol.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('يرجى تحديد الرمز أو العيار'),
                                backgroundColor: AppColors.danger),
                          );
                          return;
                        }

                        setDialogState(() => submitting = true);
                        try {
                          final data = <String, dynamic>{'ticker': symbol};
                          final above = double.tryParse(alertAboveCtrl.text);
                          final below = double.tryParse(alertBelowCtrl.text);
                          if (above != null) data['alert_price_above'] = above;
                          if (below != null) data['alert_price_below'] = below;
                          if (notesCtrl.text.trim().isNotEmpty) {
                            data['notes'] = notesCtrl.text.trim();
                          }

                          await api.addToWatchlist(data);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'تم إضافة الأصل لقائمة المراقبة بنجاح'),
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

  Future<void> _removeItem(WatchlistItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إزالة من المراقبة'),
          content: Text('هل تريد إزالة ${item.ticker} من قائمة المراقبة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child:
                  const Text('إزالة', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await api.removeFromWatchlist(item.id);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('تمت الإزالة بنجاح'),
              backgroundColor: AppColors.success),
        );
        _refresh();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('فشل الإزالة: $e'),
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
        body: FutureBuilder<WatchlistResponse?>(
          future: _listFuture,
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
                  error: 'فشل تحميل قائمة المراقبة: ${snapshot.error}',
                  onRetry: _refresh);
            }
            final data = snapshot.data;
            if (data == null) {
              return const StateView(
                  empty: true,
                  emptyMessage:
                      'الرجاء تسجيل الدخول لعرض قائمة المراقبة الخاصة بك');
            }

            final filteredList = _getFilteredItems(data);

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
                        icon: Icons.visibility,
                        title: 'قائمة المراقبة والتنبيهات',
                        subtitle:
                            'تابع أسعار أصولك المفضلة وتلقى تنبيهات الارتفاع والانخفاض'),
                    const SizedBox(height: 16),

                    // Category Selector Row
                    Row(
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
                    const SizedBox(height: 16),

                    if (filteredList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedCategory == 'stock'
                              ? 'قائمة مراقبة الأسهم فارغة. أضف أسهم لمتابعتها.'
                              : _selectedCategory == 'crypto'
                                  ? 'قائمة مراقبة الكريبتو فارغة. أضف عملات لتتبع أسعارها.'
                                  : 'قائمة مراقبة الذهب فارغة. أضف عيارات للتنبيه بالأسعار.',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${filteredList.length} أصل في المتابعة',
                            style: AppTypography.bodyMedium),
                      ),
                      ...filteredList.map((item) => _buildWatchlistCard(item)),
                    ],
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

  Widget _buildWatchlistCard(WatchlistItem item) {
    final isCrypto = _selectedCategory == 'crypto';
    final currency = isCrypto ? 'USD' : 'ج.م';
    final change = item.changePercent ?? 0.0;
    final isUp = change >= 0;

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
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCrypto
                      ? Icons.currency_bitcoin
                      : _selectedCategory == 'gold'
                          ? Icons.diamond_outlined
                          : Icons.show_chart_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nameAr ?? item.name ?? item.ticker,
                        style: AppTypography.titleSmall),
                    if (item.name != null && item.name != item.ticker)
                      Text(item.ticker, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              if (item.currentPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatCurrency(item.currentPrice!, currency),
                        style: AppTypography.titleSmall),
                    if (item.changePercent != null)
                      Text(
                        '${isUp ? '+' : ''}${item.changePercent!.toStringAsFixed(2)}%',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUp ? AppColors.success : AppColors.danger),
                      ),
                  ],
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 20),
                onPressed: () => _removeItem(item),
              ),
            ],
          ),

          // Alert prices
          if (item.alertPriceAbove != null || item.alertPriceBelow != null) ...[
            const Divider(height: 16),
            Row(
              children: [
                if (item.alertPriceAbove != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                              'تنبيه فوق: ${_formatCurrency(item.alertPriceAbove!, currency)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                if (item.alertPriceAbove != null &&
                    item.alertPriceBelow != null)
                  const SizedBox(width: 8),
                if (item.alertPriceBelow != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_downward,
                              size: 14, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text(
                              'تنبيه تحت: ${_formatCurrency(item.alertPriceBelow!, currency)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // Notes
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(item.notes!, style: AppTypography.bodySmall)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(double value, String currency) {
    return '${value.toStringAsFixed(2)} ${currency == 'USD' ? '\$' : 'ج.م'}';
  }
}
