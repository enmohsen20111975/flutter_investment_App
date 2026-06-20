import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class UpgradeModal {
  static Future<void> show(BuildContext context, {
    required String feature,
    String? reason,
    String? upgradeTo,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_open, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getTitle(feature),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (reason != null)
                      Text(
                        reason,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    _buildTierCard(
                      context,
                      title: 'بلس - Plus',
                      price: '49 ج.م / أسبوع',
                      features: const [
                        'محفظة غير محدودة',
                        'قائمة متابعة غير محدودة',
                        'تحليل ذكي غير محدود',
                        'توقعات احترافية',
                      ],
                      isPrimary: upgradeTo == 'plus',
                    ),
                    const SizedBox(height: 12),
                    _buildTierCard(
                      context,
                      title: 'بريميوم - Premium',
                      price: '99 ج.م / أسبوع',
                      features: const [
                        'كل مزايا بلس',
                        'تنبؤات الأسعار',
                        'دعم أولوية',
                        'تصدير التقارير',
                      ],
                      isPrimary: upgradeTo == 'premium',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(context, '/subscription');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'عرض الخطط والاشتراك',
                          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTierCard(BuildContext context, {
    required String title,
    required String price,
    required List<String> features,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary ? AppColors.primary : AppColors.border,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(f, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  static String _getTitle(String feature) {
    switch (feature) {
      case 'ai_analysis':
        return 'التحليل الذكي ميزة مدفوعة';
      case 'recommendations':
        return 'التوقعات ميزة مدفوعة';
      case 'predictions':
        return 'التنبؤات ميزة بريميوم';
      case 'reports_export':
        return 'تصدير التقارير ميزة بريميوم';
      case 'portfolio_unlimited':
        return 'المحفظة الممتدة ميزة مدفوعة';
      case 'watchlist_unlimited':
        return 'قائمة المتابعة الممتدة ميزة مدفوعة';
      default:
        return 'ترقية مطلوبة';
    }
  }
}
