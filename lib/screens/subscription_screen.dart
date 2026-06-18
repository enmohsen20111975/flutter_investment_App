// ============================================================================
// مساعد الاستثمار Flutter - Subscription Screen
// View plans, current subscription, and upgrade
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import 'webview_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Future<SubscriptionData?>? _dataFuture;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<SubscriptionData?> _fetchData() async {
    try {
      final results = await Future.wait([
        api.getSubscriptionPlans(),
        api.getCurrentSubscription(),
      ]);

      final rawPlans = results[0];
      final List<Map<String, dynamic>> plansList;
      if (rawPlans is Map) {
        plansList = (rawPlans['plans'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];
      } else if (rawPlans is List) {
        plansList = rawPlans.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        plansList = <Map<String, dynamic>>[];
      }
      final currentSub = results[1] as Map<String, dynamic>?;

      return SubscriptionData(plans: plansList, currentSub: currentSub);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    _dataFuture = _fetchData();
    if (mounted) setState(() {});
  }

  Future<void> _subscribeToPlan(
      String planId, Map<String, dynamic>? currentSub) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _subscribing = true;
    });
    try {
      final currentTier =
          currentSub?['subscription_tier'] ?? currentSub?['plan'] ?? 'free';
      final result = currentTier != 'free'
          ? await api.upgradeSubscription(planId)
          : await api.subscribeToPlan(planId);

      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('تم الاشتراك بنجاح!'),
              backgroundColor: AppColors.success),
        );
        _refresh();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'فشل الاشتراك'),
              backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
            content: Text('حدث خطأ: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subscribing = false;
        });
      }
    }
  }

  Future<void> _showPaymentMethodDialog(
      Map<String, dynamic> plan, Map<String, dynamic>? currentSub) async {
    final planId = plan['id'] ?? '';
    final price = (plan['price'] as num?)?.toDouble() ?? 0.0;

    if (price == 0.0) {
      _subscribeToPlan(planId, currentSub);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اختر طريقة الدفع للاشتراك في ${plan['name_ar'] ?? plan['name']}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'المبلغ المطلوب: $price ج.م شهرياً',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryMuted,
                    child: Icon(Icons.credit_card, color: AppColors.primary),
                  ),
                  title: const Text('بطاقة ائتمان / محفظة إلكترونية (PayMob)',
                      style: TextStyle(color: AppColors.text)),
                  subtitle: const Text('دفع فوري آمن عبر الإنترنت',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    _processPaymobPayment(planId, price);
                  },
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.successLight,
                    child: Icon(Icons.send_rounded, color: AppColors.success),
                  ),
                  title: const Text('تحويل مباشر عبر InstaPay',
                      style: TextStyle(color: AppColors.text)),
                  subtitle: const Text('تفعيل يدوي سريع بالرقم المرجعي',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    _showInstapayDialog(planId);
                  },
                ),
                const Divider(color: AppColors.border),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.infoLight,
                    child: Icon(Icons.shop_two_outlined, color: AppColors.info),
                  ),
                  title:
                      const Text('شراء عبر Google Play',
                          style: TextStyle(color: AppColors.text)),
                  subtitle: const Text('دفع سريع عبر حساب جوجل الخاص بك',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  onTap: () {
                    Navigator.pop(context);
                    _processGooglePlayPayment(planId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processPaymobPayment(String planId, double price) async {
    setState(() {
      _subscribing = true;
    });
    try {
      final result = await api.createPaymobPayment(
        amount: price,
        currency: 'EGP',
        planId: planId,
      );

      final paymentUrl =
          result['payment_url'] ?? result['iframe_url'] ?? result['url'];
      if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewScreen(initialUrl: paymentUrl.toString()),
          ),
        );
        _refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'جاري معالجة الدفع... سيتم تحديث اشتراكك فور استلام التأكيد.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception(result['error'] ?? 'رابط الدفع غير متوفر حالياً');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل الدفع عبر PayMob: $e'),
            backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subscribing = false;
        });
      }
    }
  }

  void _showInstapayDialog(String planId) {
    final txCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('الدفع عبر InstaPay',
                style: TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الرجاء إرسال قيمة الاشتراك إلى عنوان InstaPay التالي:',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const SelectableText(
                      'investassist@instapay',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGlow),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'بعد التحويل، أدخل الرقم المرجعي للمعاملة (Reference ID):',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: txCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      hintText: 'مثال: 489201837591',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final txHash = txCtrl.text.trim();
                  if (txHash.isEmpty) return;
                  Navigator.pop(context);

                  setState(() {
                    _subscribing = true;
                  });
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final verifyRes = await api.verifyInstapayPayment(txHash);
                    if (verifyRes['success'] == true) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'تم إرسال إيصال التحويل بنجاح! سيتم مراجعته وتفعيل حسابك خلال دقائق.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      _refresh();
                    } else {
                      throw Exception(
                          verifyRes['error'] ?? 'فشل التحقق من الإيصال');
                    }
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text('حدث خطأ: $e'),
                          backgroundColor: AppColors.danger),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _subscribing = false;
                      });
                    }
                  }
                },
                child: const Text('تأكيد وإرسال'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processGooglePlayPayment(String planId) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _subscribing = true;
    });
    try {
      final receipt = 'google_play_mock_receipt_token_for_$planId';
      final verifyRes = await api.verifyGooglePlayReceipt(receipt);
      if (verifyRes['success'] == true) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم التحقق وتفعيل الاشتراك عبر Google Play بنجاح!'),
            backgroundColor: AppColors.success,
          ),
        );
        _refresh();
      } else {
        throw Exception(verifyRes['error'] ?? 'فشل التحقق من متجر Google Play');
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text('فشل الدفع عبر Google Play: $e'),
            backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        setState(() {
          _subscribing = false;
        });
      }
    }
  }

  Future<void> _startTrial() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _subscribing = true;
    });
    try {
      final result = await api.startTrial();
      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('تم تفعيل الفترة التجريبية!'),
              backgroundColor: AppColors.success),
        );
        _refresh();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'فشل تفعيل التجربة'),
              backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() {
        _subscribing = false;
      });
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
          title: const Text('الاشتراكات',
              style:
                  TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<SubscriptionData?>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return StateView(
                  error: snapshot.hasError
                      ? snapshot.error.toString()
                      : 'فشل تحميل الاشتراكات',
                  onRetry: _refresh);
            }

            final data = snapshot.data!;
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
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
                    if (data.currentSub != null) ...[
                      _buildCurrentSubscription(data.currentSub!),
                      const SizedBox(height: 20),
                    ],
                    if (data.plans.isEmpty)
                      const StateView(
                          empty: true, emptyMessage: 'لا توجد خطط متاحة حالياً')
                    else
                       ...data.plans
                           .map((plan) => _buildPlanCard(plan, data.currentSub, _subscribing, _showPaymentMethodDialog, _subscribeToPlan)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _subscribing ? null : _startTrial,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _subscribing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: AppColors.primary, strokeWidth: 2))
                            : const Text('تجربة مجانية لمدة 7 أيام',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
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
}

Widget _buildCurrentSubscription(Map<String, dynamic> currentSub) {
  final tier = currentSub['subscription_tier'] ?? currentSub['plan'] ?? 'free';
  final expiresAt = currentSub['expires_at'] ?? currentSub['end_date'];
  final isActive = currentSub['is_active'] ?? true;

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
        Text('الاشتراك الحالي',
            style: TextStyle(
                fontSize: 14, color: AppColors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 8),
        Text(
          _getPlanNameAr(tier),
          style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.white),
        ),
        if (expiresAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'ينتهي: $expiresAt',
            style: TextStyle(
                fontSize: 12, color: AppColors.white.withValues(alpha: 0.7)),
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
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPlanCard(
    Map<String, dynamic> plan,
    Map<String, dynamic>? currentSub,
    bool subscribing,
    void Function(Map<String, dynamic> plan, Map<String, dynamic>? currentSub) onShowPayment,
    void Function(String planId, Map<String, dynamic>? currentSub) onSubscribe) {
  final id = plan['id'] ?? '';
  final name = plan['name'] ?? '';
  final nameAr = plan['name_ar'] ?? name;
  final price = (plan['price'] as num?)?.toDouble() ?? 0;
  final features = (plan['features'] as List?)?.cast<String>().toList() ?? <String>[];
  final isPopular = plan['is_popular'] == true;
  final isCurrentPlan =
      currentSub?['subscription_tier'] == id || currentSub?['plan'] == id;

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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isPopular ? AppColors.primaryMuted : AppColors.surfaceMuted,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('الأكثر شعبية',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white)),
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
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text),
                  ),
                  if (price > 0)
                    const Text('/ شهرياً',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        if (features.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: features
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                                child:
                                    Text(f, style: AppTypography.bodyMedium)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        if (!isCurrentPlan)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: subscribing ? null : () => onShowPayment(plan, currentSub),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPopular ? AppColors.primary : AppColors.surfaceMuted,
                  foregroundColor:
                      isPopular ? AppColors.white : AppColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
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
    case 'free':
      return 'مجاني';
    case 'plus':
      return 'بلس';
    case 'premium':
      return 'بريميوم';
    default:
      return tier;
  }
}

class SubscriptionData {
  final List<Map<String, dynamic>> plans;
  final Map<String, dynamic>? currentSub;

  SubscriptionData({required this.plans, this.currentSub});
}
