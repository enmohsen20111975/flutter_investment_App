// ============================================================================
// مساعد الاستثمار Flutter - Quantum Price Alerts Screen
// Target Price Alerts, Stop-Loss Monitoring & Offline SQLite Sync
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../models/types.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _isLoading = true;
  List<PriceAlert> _alerts = [];

  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String _selectedCondition = 'ABOVE';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final list = await GLMApiClient.instance.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Alerts] Load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createAlert() async {
    final symbol = _symbolController.text.trim().toUpperCase();
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (symbol.isEmpty || price <= 0) return;

    final newAlert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol,
      companyName: symbol,
      targetPrice: price,
      condition: _selectedCondition,
      createdAt: DateTime.now(),
    );

    setState(() {
      _alerts.insert(0, newAlert);
    });

    try {
      await GLMApiClient.instance.createAlert(newAlert.toJson());
      _loadAlerts();
    } catch (e) {
      debugPrint('[Alerts] Create error: $e');
    }
  }

  Future<void> _deleteAlert(String id) async {
    setState(() {
      _alerts.removeWhere((a) => a.id == id);
    });
    try {
      await GLMApiClient.instance.deleteAlert(id);
    } catch (e) {
      debugPrint('[Alerts] Delete error: $e');
    }
  }

  void _showAddAlertDialog() {
    _symbolController.clear();
    _priceController.clear();
    _selectedCondition = 'ABOVE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.quantumGlass,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.quantumGlassBorder),
          ),
          title: const Text('ضبط تنبيه سعر جديد', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _symbolController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'رمز السهم (مثال: COMI)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.quantumSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.quantumGlassBorder),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'السعر المستهدف (ج.م)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.quantumSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.quantumGlassBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('الشرط: ', style: TextStyle(color: Colors.white70)),
                  ChoiceChip(
                    label: const Text('ارتفاع أعلى من'),
                    selected: _selectedCondition == 'ABOVE',
                    onSelected: (val) => setDialogState(() => _selectedCondition = 'ABOVE'),
                    selectedColor: AppColors.quantumEmerald,
                    labelStyle: TextStyle(color: _selectedCondition == 'ABOVE' ? Colors.black : Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('انخفاض أقل من'),
                    selected: _selectedCondition == 'BELOW',
                    onSelected: (val) => setDialogState(() => _selectedCondition = 'BELOW'),
                    selectedColor: AppColors.quantumCrimson,
                    labelStyle: TextStyle(color: _selectedCondition == 'BELOW' ? Colors.white : Colors.white70),
                  ),
                ],
              ),
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
              onPressed: () {
                Navigator.pop(context);
                _createAlert();
              },
              child: const Text('حفظ التنبيه'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.quantumBg,
      appBar: AppBar(
        backgroundColor: AppColors.quantumSurface,
        elevation: 0,
        title: const Text('تنبيهات الأسعار', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_outlined, color: AppColors.quantumEmerald),
            onPressed: _showAddAlertDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
          : RefreshIndicator(
              color: AppColors.quantumEmerald,
              backgroundColor: AppColors.quantumGlass,
              onRefresh: _loadAlerts,
              child: _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_outlined, size: 64, color: AppColors.quantumGold.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('لا توجد تنبيهات أسعار نشطة حالياً', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.quantumEmerald,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            icon: const Icon(Icons.add_alert),
                            label: const Text('إضافة تنبيه سعر جديد'),
                            onPressed: _showAddAlertDialog,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _alerts.length,
                      itemBuilder: (context, index) {
                        final item = _alerts[index];
                        final isAbove = item.condition == 'ABOVE';

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
                                  color: (isAbove ? AppColors.quantumEmerald : AppColors.quantumCrimson).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isAbove ? Icons.trending_up : Icons.trending_down,
                                  color: isAbove ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(item.symbol, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 6),
                                        Text(
                                          isAbove ? 'أعلى من' : 'أقل من',
                                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'السعر المستهدف: ${item.targetPrice} ج.م',
                                      style: TextStyle(
                                        color: isAbove ? AppColors.quantumEmerald : AppColors.quantumCrimson,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.white38),
                                onPressed: () => _deleteAlert(item.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
