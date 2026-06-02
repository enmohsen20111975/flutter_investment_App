// ============================================================================
// مساعد الاستثمار Flutter - Watchlist Screen
// Full CRUD: View, Add, Remove stocks with price alerts
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
  WatchlistResponse? _data;
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
      
      // Check authentication first
      final isLoggedIn = await api.isAuthenticated();
      if (!isLoggedIn) {
        debugPrint('[Watchlist] Not authenticated, skipping load');
        setState(() { _loading = false; _error = 'الرجاء تسجيل الدخول لعرض قائمة المراقبة'; });
        return;
      }
      
      WatchlistResponse data;
      try {
        data = await api.getWatchlistEnhanced();
      } catch (_) {
        data = await api.getWatchlist();
      }
      setState(() { _data = data; _loading = false; _refreshing = false; });
    } catch (e) {
      setState(() { _error = 'فشل تحميل قائمة المراقبة: ${e.toString()}'; _loading = false; _refreshing = false; });
    }
  }

  Future<void> _showAddDialog() async {
    if (!SubscriptionService.instance.canAddToWatchlist(_data?.items.length ?? 0)) {
      UpgradeModal.show(context, feature: 'watchlist_unlimited', reason: 'لقد وصلت للحد الأقصى (3 أسهم) في قائمة المراقبة');
      return;
    }

    final tickerCtrl = TextEditingController();
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
            title: const Text('إضافة سهم للمراقبة', style: TextStyle(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tickerCtrl,
                    decoration: const InputDecoration(
                      labelText: 'رمز السهم *',
                      hintText: 'مثال: COMI',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: alertAboveCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'تنبيه فوق سعر (اختياري)',
                      suffixText: 'ج.م',
                      prefixIcon: Icon(Icons.arrow_upward, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: alertBelowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'تنبيه تحت سعر (اختياري)',
                      suffixText: 'ج.م',
                      prefixIcon: Icon(Icons.arrow_downward, size: 20),
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
                  if (ticker.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى إدخال رمز السهم'), backgroundColor: AppColors.danger),
                    );
                    return;
                  }
                  setDialogState(() => submitting = true);
                  try {
                    final data = <String, dynamic>{'ticker': ticker};
                    final above = double.tryParse(alertAboveCtrl.text);
                    final below = double.tryParse(alertBelowCtrl.text);
                    if (above != null) data['alert_price_above'] = above;
                    if (below != null) data['alert_price_below'] = below;
                    if (notesCtrl.text.trim().isNotEmpty) data['notes'] = notesCtrl.text.trim();

                    await api.addToWatchlist(data);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت الإضافة لقائمة المراقبة'), backgroundColor: AppColors.success),
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

  Future<void> _removeItem(WatchlistItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إزالة من المراقبة'),
          content: Text('هل تريد إزالة ${item.ticker} من قائمة المراقبة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('إزالة', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      try {
        await api.removeFromWatchlist(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت الإزالة'), backgroundColor: AppColors.success),
        );
        _loadData(silent: true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإزالة: $e'), backgroundColor: AppColors.danger),
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
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderCard(icon: Icons.visibility, title: 'قائمة المراقبة', subtitle: 'تابع الأسهم التي تهمك مع تنبيهات الأسعار'),
                const SizedBox(height: 16),
                StateView(loading: _loading, error: _error, onRetry: () => _loadData()),
                if (!_loading && _error == null) ...[
                  if (_data?.items.isEmpty ?? true)
                    const StateView(empty: true, emptyMessage: 'قائمة المراقبة فارغة. أضف أسهم لمتابعتها.')
                  else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${_data?.total ?? 0} سهم في القائمة', style: AppTypography.bodyMedium),
                    ),
                    ..._data!.items.map((item) => _buildWatchlistCard(item)),
                  ],
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistCard(WatchlistItem item) {
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
                child: const Icon(Icons.visibility, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(item.nameAr ?? item.name ?? item.ticker, style: AppTypography.titleSmall),
                   ],
                 ),
               ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('فوق: ${item.alertPriceAbove!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                if (item.alertPriceAbove != null && item.alertPriceBelow != null)
                  const SizedBox(width: 8),
                if (item.alertPriceBelow != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_downward, size: 14, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text('تحت: ${item.alertPriceBelow!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
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
              decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item.notes!, style: AppTypography.bodySmall)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
