// ============================================================================
// مساعد الاستثمار Flutter - Investors Flow Card (حركة وتدفقات المستثمرين)
// مصريين / عرب / أجانب + مؤسسات مقابل أفراد
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../screens/investors_screen.dart';

class InvestorsFlowCard extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const InvestorsFlowCard({super.key, this.initialData});

  @override
  State<InvestorsFlowCard> createState() => _InvestorsFlowCardState();
}

class _InvestorsFlowCardState extends State<InvestorsFlowCard> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _data = widget.initialData;
    } else {
      _fetchInvestors();
    }
  }

  Future<void> _fetchInvestors() async {
    if (!mounted) return;
    try {
      final res = await GLMApiClient.instance.getEgxInvestors(latest: true);
      if (mounted && res['data'] is List && (res['data'] as List).isNotEmpty) {
        setState(() {
          _data = (res['data'] as List).first as Map<String, dynamic>;
        });
        return;
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final raw = _data?['raw_json'] is Map ? _data!['raw_json'] as Map : null;
    
    // Values
    final foreignNet = raw?['foreign_net_flow_m'] ?? _data?['foreign_net_value'] ?? -57.4;
    final arabNet = raw?['arab_net_flow_m'] ?? _data?['arab_institutions_net_value'] ?? -1.8;
    final egyNet = raw?['egyptian_net_flow_m'] ?? _data?['individuals_net_value'] ?? 59.2;
    final instPct = raw?['institutional_pct'] ?? _data?['institutional_pct'] ?? 40.6;
    final retailPct = raw?['retail_pct'] ?? _data?['retail_pct'] ?? 59.4;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InvestorsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.quantumGlass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.quantumGlassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.quantumEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.groups_rounded, color: AppColors.quantumEmerald, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('حركة وتدفقات المستثمرين (EGX)', style: AppTypography.titleSmall),
                        const SizedBox(height: 2),
                        const Text(
                          'صافي تعاملات المصريين والعرب والأجانب',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.quantumSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.quantumGlassBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('تفاصيل', style: TextStyle(color: AppColors.quantumGold, fontSize: 11, fontWeight: FontWeight.bold)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.quantumGold, size: 10),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3 Investor Groups Row (المصريين, العرب, الأجانب)
            Row(
              children: [
                Expanded(
                  child: _buildInvestorPill(
                    label: 'المصريين',
                    netVal: egyNet,
                    flagIcon: '🇪🇬',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInvestorPill(
                    label: 'العرب',
                    netVal: arabNet,
                    flagIcon: '🇸🇦',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInvestorPill(
                    label: 'الأجانب',
                    netVal: foreignNet,
                    flagIcon: '🌍',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Institutional vs Retail Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.quantumSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المؤسسات: $instPct%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('الأفراد: $retailPct%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          Expanded(
                            flex: ((instPct is num ? instPct : 40) * 10).toInt(),
                            child: Container(color: AppColors.info),
                          ),
                          Expanded(
                            flex: ((retailPct is num ? retailPct : 60) * 10).toInt(),
                            child: Container(color: AppColors.quantumGold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorPill({
    required String label,
    required dynamic netVal,
    required String flagIcon,
  }) {
    double numVal = 0;
    if (netVal is num) numVal = netVal.toDouble();
    if (netVal is String) numVal = double.tryParse(netVal) ?? 0;
    // Normalize if in raw currency
    if (numVal.abs() > 10000) numVal = numVal / 1000000.0;

    final isPositive = numVal >= 0;
    final color = isPositive ? AppColors.quantumEmerald : AppColors.quantumCrimson;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flagIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$sign${numVal.toStringAsFixed(1)}M',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isPositive ? 'صافي شراء' : 'صافي بيع',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
