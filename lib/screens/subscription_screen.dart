// ============================================================================
// مساعد الاستثمار Flutter - Subscription Screen
// View plans, current subscription, and upgrade
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSub;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() { _loading = true; _error = null; });
      final results = await Future.wait([
        api.getSubscriptionPlans(),
        _loadCurrentSubscription(),
      ]);
      final plansData = results[0] as Map<String, dynamic>;
      final plansList = (plansData['plans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() { _plans = plansList; _loading = false; _refreshing = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; _refreshing = false; });
    }
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final response = await api.getCurrentSubscription();
      _currentSub = response;
    } catch (_) {
      // User might not be logged in
    }
  }

  Future<void> _subscribeToPlan(String planId) async {
    setState(() { _subscribing = true; });
    try {
      Map<String, dynamic> result;
      final currentTier = _currentSub?['subscription_tier'] ?? _currentSub?['plan'] ?? 'free';
      if (currentTier != 'free') {
        result = await api.upgradeSubscription(planId);
      } else {
        result = await api.subscribeToPlan(planId);
      }
      if (result['success'] == true) {
        // Check if payment URL is returned
        if (result['payment_url'] != null) {
          // In a real app, open payment URL in browser
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم توجيهك لصفحة الدفع'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الاشتراك بنجاح!'), backgroundColor: AppColors.success),
          );
        }
        _loadCurrentSubscription();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'فشل الاشتراك'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() { _subscribing = false; });
    }
  }

  Future<void> _startTrial() async {
    setState(() { _subscribing = true; });
    try {
      final result = await api.startTrial();
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل الفترة التجريبية!'), backgroundColor: AppColors.success),
        );
        _loadData(silent: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'فشل تفعيل التجربة'), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() { _subscribing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async { setState(() => _refreshing = true); await _loadData(silent: true); },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const HeaderCard(
                  icon: Icons.card_membership,
                  title: 'الاشتراكات',
                  subtitle: 'اختر الخطة المناسبة لاحتياجاتك',
                ),
                const SizedBox(height: 16),
                StateView(loading: _loading, error: _error, onRetry: () => _loadData()),
                if (!_loading && _error == null) ...[
                  // Current subscription status
                  if (_currentSub != null) ...[
                    _buildCurrentSubscription(),
                    const SizedBox(height: 20),
                  ],
                  // Plans
                  if (_plans.isEmpty)
                    const StateView(empty: true, emptyMessage: 'لا توجد خطط متاحة حالياً')
                  else
                    ..._plans.map((plan) => _buildPlanCard(plan)),
                  const SizedBox(height: 16),
                  // Trial button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _subscribing ? null : _startTrial,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _subscribing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : const Text('تجربة مجانية لمدة 7 أيام', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubscription() {
    final tier = _currentSub?['subscription_tier'] ?? _currentSub?['plan'] ?? 'free';
    final expiresAt = _currentSub?['expires_at'] ?? _currentSub?['end_date'];
    final isActive = _currentSub?['is_active'] ?? true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          isActive ? AppColors.primaryDark : AppColors.textMuted,
          isActive ? AppColors.primary : AppColors.textSecondary,
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('الاشتراك الحالي', style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 8),
          Text(
            _getPlanNameAr(tier),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.white),
          ),
          if (expiresAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'ينتهي: $expiresAt',
              style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'نشط' : 'منتهي',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final id = plan['id'] ?? '';
    final name = plan['name'] ?? '';
    final nameAr = plan['name_ar'] ?? name;
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final isPopular = plan['is_popular'] == true;
    final isCurrentPlan = _currentSub?['subscription_tier'] == id || _currentSub?['plan'] == id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? AppColors.primary : AppColors.border,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPopular ? AppColors.primaryMuted : AppColors.surfaceMuted,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nameAr, style: AppTypography.titleMedium),
                      if (isPopular) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('الأكثر شعبية', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0 ? 'مجاني' : '$price ج.م',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    if (price > 0)
                      const Text('/ شهرياً', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          // Features
          if (features.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: AppTypography.bodyMedium)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
          // Action button
          if (!isCurrentPlan)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _subscribing ? null : () => _subscribeToPlan(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular ? AppColors.primary : AppColors.surfaceMuted,
                    foregroundColor: isPopular ? AppColors.white : AppColors.text,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    price == 0 ? 'الخطة الحالية' : 'اشترك الآن',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getPlanNameAr(String tier) {
    switch (tier.toLowerCase()) {
      case 'free': return 'مجاني';
      case 'plus': return 'بلس';
      case 'premium': return 'بريميوم';
      default: return tier;
    }
  }
}
