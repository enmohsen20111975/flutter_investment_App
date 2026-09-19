// ============================================================================
// مساعد الاستثمار Flutter - Investors Breakdown Screen
// تفاصيل تعاملات المستثمرين (أجانب - عرب - مصريين)
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';

class InvestorsScreen extends StatefulWidget {
  const InvestorsScreen({super.key});

  @override
  State<InvestorsScreen> createState() => _InvestorsScreenState();
}

class _InvestorsScreenState extends State<InvestorsScreen> {
  bool _isLoading = true;
  List<dynamic> _investorDays = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await GLMApiClient.instance.getEgxInvestors(latest: false, days: 30);
      if (mounted && res['data'] is List) {
        setState(() {
          _investorDays = res['data'] as List;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatEgp(dynamic val) {
    if (val == null) return '--';
    double d = 0;
    if (val is num) d = val.toDouble();
    if (val is String) d = double.tryParse(val) ?? 0;
    if (d.abs() >= 1000000) {
      return '${(d / 1000000).toStringAsFixed(1)} مليون ج.م';
    }
    return '${d.toStringAsFixed(0)} ج.م';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          title: const Text('حركة المستثمرين في البورصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.quantumEmerald),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.quantumEmerald))
            : _investorDays.isEmpty
                ? const Center(child: Text('لا توجد بيانات متاحة حالياً', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _investorDays.length,
                    itemBuilder: (context, index) {
                      final item = _investorDays[index];
                      if (item is! Map) return const SizedBox.shrink();
                      
                      final date = item['date'] ?? '';
                      final sessionType = item['session_type'] ?? 'جلسة تداول';
                      final totalTurnover = item['total_value'] ?? item['total_turnover_egp'];
                      final tradesCount = item['number_of_trades'];
                      
                      final raw = item['raw_json'] is Map ? item['raw_json'] as Map : null;
                      final foreignNet = raw?['foreign_net_flow_m'] ?? item['foreign_net_value'];
                      final arabNet = raw?['arab_net_flow_m'] ?? item['arab_institutions_net_value'];
                      final egyNet = raw?['egyptian_net_flow_m'] ?? item['individuals_net_value'];
                      final instPct = raw?['institutional_pct'] ?? item['institutional_pct'] ?? 40.6;
                      final retailPct = raw?['retail_pct'] ?? item['retail_pct'] ?? 59.4;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.quantumSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.quantumGlassBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date & Session Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.quantumGold),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.quantumEmerald.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        sessionType,
                                        style: const TextStyle(color: AppColors.quantumEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                if (tradesCount != null)
                                  Text(
                                    '$tradesCount عملية',
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                  ),
                              ],
                            ),

                            if (totalTurnover != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'إجمالي قيمة التداول: ${_formatEgp(totalTurnover)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],

                            const Divider(color: Colors.white12, height: 20),

                            // Flow Bars
                            _buildRowFlow('صافي تعاملات الأجانب', foreignNet, '🌍'),
                            const SizedBox(height: 8),
                            _buildRowFlow('صافي تعاملات العرب', arabNet, '🇸🇦'),
                            const SizedBox(height: 8),
                            _buildRowFlow('صافي تعاملات المصريين', egyNet, '🇪🇬'),

                            const SizedBox(height: 12),
                            // Institutions vs Retail
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('حصة المؤسسات: $instPct%',
                                    style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w600)),
                                Text('حصة الأفراد: $retailPct%',
                                    style: const TextStyle(color: AppColors.quantumGold, fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildRowFlow(String label, dynamic val, String icon) {
    double numVal = 0;
    if (val is num) numVal = val.toDouble();
    if (val is String) numVal = double.tryParse(val) ?? 0;
    if (numVal.abs() > 10000) numVal = numVal / 1000000.0;

    final isPositive = numVal >= 0;
    final color = isPositive ? AppColors.quantumEmerald : AppColors.quantumCrimson;
    final sign = isPositive ? '+' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$sign${numVal.toStringAsFixed(1)} مليون ج.م (${isPositive ? "شراء" : "بيع"})',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
