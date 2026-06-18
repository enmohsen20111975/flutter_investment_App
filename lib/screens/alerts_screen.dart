// ============================================================================
// مساعد الاستثمار Flutter - Alerts Screen
// Manage price/indicator alerts via /api/mobile/alerts/settings
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Future<List<dynamic>>? _alertsFuture;
  final List<String> _alertTypes = [
    'price_above',
    'price_below',
    'change_percent_up',
    'rsi_overbought',
    'signal_buy',
  ];

  @override
  void initState() {
    super.initState();
    _alertsFuture = _fetchAlerts();
  }

  Future<List<dynamic>> _fetchAlerts() async {
    try {
      final res = await api.getAlertSettings();
      final list = res['alerts'] ?? res['data'] ?? res['settings'] ?? [];
      return list is List ? list : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() => _alertsFuture = _fetchAlerts());
  }

  Future<void> _showCreateDialog() async {
    final tickerCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String selectedType = _alertTypes.first;
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إنشاء تنبيه جديد'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'نوع التنبيه'),
                  items: _alertTypes
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(_alertTypeLabel(t)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedType = v ?? selectedType),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tickerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رمز السهم',
                    hintText: 'مثال: COMI',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _targetLabel(selectedType),
                    hintText: 'القيمة المستهدفة',
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final ticker = tickerCtrl.text.trim().toUpperCase();
                        final target = double.tryParse(targetCtrl.text);
                        if (ticker.isEmpty || target == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('يرجى ملء الحقول'),
                                backgroundColor: AppColors.danger),
                          );
                          return;
                        }
                        setState(() => submitting = true);
                        try {
                          await api.createAlert({
                            'type': selectedType,
                            'ticker': ticker,
                            'target_value': target,
                            'status': 'active',
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _refresh();
                        } catch (e) {
                          setState(() => submitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : const Text('إنشاء',
                        style: TextStyle(color: AppColors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAlert(String id) async {
    try {
      await api.deleteAlert(id);
      _refresh();
    } catch (_) {}
  }

  String _targetLabel(String type) {
    switch (type) {
      case 'price_above':
      case 'price_below':
        return 'السعر المستهدف';
      case 'change_percent_up':
        return 'نسبة التغير المستهدفة (%)';
      case 'rsi_overbought':
        return 'قيمة RSI';
      case 'signal_buy':
        return 'عدد الإشارات';
      default:
        return 'القيمة المستهدفة';
    }
  }

  String _alertTypeLabel(String type) {
    switch (type) {
      case 'price_above':
        return 'السهم فوق سعر';
      case 'price_below':
        return 'السهم تحت سعر';
      case 'change_percent_up':
        return 'نسبة التغير';
      case 'rsi_overbought':
        return 'RSI مرتفع';
      case 'signal_buy':
        return 'إشارة شراء';
      default:
        return type;
    }
  }

  IconData _alertIcon(String? type) {
    switch (type) {
      case 'price_above':
        return Icons.trending_up;
      case 'price_below':
        return Icons.trending_down;
      case 'change_percent_up':
        return Icons.show_chart;
      case 'rsi_overbought':
        return Icons.speed;
      case 'signal_buy':
        return Icons.auto_awesome;
      default:
        return Icons.notifications;
    }
  }

  Color _alertColor(String? type) {
    switch (type) {
      case 'price_above':
        return AppColors.success;
      case 'price_below':
        return AppColors.danger;
      case 'change_percent_up':
        return AppColors.primary;
      case 'rsi_overbought':
        return AppColors.warning;
      case 'signal_buy':
        return const Color(0xFFFFD700);
      default:
        return AppColors.textMuted;
    }
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
          title: const Text('التنبيهات',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.white),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _alertsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SkeletonList(itemCount: 4);
            if (snapshot.hasError)
              return StateView(error: 'فشل تحميل التنبيهات', onRetry: _refresh);
            final alerts = snapshot.data ?? [];
            if (alerts.isEmpty)
              return const StateView(
                  empty: true, emptyMessage: 'لا توجد تنبيهات');
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final a = alerts[index] is Map
                      ? Map<String, dynamic>.from(alerts[index])
                      : <String, dynamic>{};
                  final id = a['id']?.toString() ?? '';
                  final type = a['type']?.toString();
                  final ticker = a['ticker']?.toString() ?? '';
                  final target =
                      (a['target_value'] ?? a['target'])?.toString() ?? '';
                  final isActive = a['status']?.toString() == 'active' ||
                      a['is_active'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _alertColor(type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(_alertIcon(type),
                            color: _alertColor(type), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(ticker,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.successLight
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(isActive ? 'نشط' : 'منتهي',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isActive
                                            ? AppColors.success
                                            : AppColors.textMuted)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                                '${_alertTypeLabel(type ?? '')}: ${target.isEmpty ? '-' : target}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ])),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.danger, size: 20),
                        onPressed: () => _deleteAlert(id),
                      ),
                    ]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
