// ============================================================================
// مساعد الاستثمار Flutter - Settings Screen
// App settings, account management, preferences
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  bool _loading = true;
  String _riskTolerance = 'medium';
  String _language = 'ar';
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _riskTolerance = prefs.getString('risk_tolerance') ?? 'medium';
        _language = prefs.getString('language') ?? 'ar';
        _notifications = prefs.getBool('notifications') ?? true;
        _darkMode = prefs.getBool('dark_mode') ?? false;
      });

      // Try to load user data (skip if API fails)
      if (await api.isAuthenticated()) {
        try {
          final userData = await api.getMe();
          if (userData != null) {
            final user = User.fromJson(userData);
            if (mounted)
              setState(() {
                _user = user;
              });
          }
        } catch (_) {}
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تسجيل الخروج'),
          content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child:
                  const Text('خروج', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await api.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderCard(
                icon: Icons.settings,
                title: 'الإعدادات',
                subtitle: 'تخصيص التطبيق وإدارة الحساب',
              ),
              const SizedBox(height: 16),

              // Account Section
              const SectionHeader(title: 'الحساب', icon: Icons.person),
              const SizedBox(height: 8),
              _buildAccountCard(),
              const SizedBox(height: 20),

              // Preferences Section
              const SectionHeader(title: 'التفضيلات', icon: Icons.tune),
              const SizedBox(height: 8),
              _buildSettingsCard(
                icon: Icons.shield_outlined,
                title: 'مستوى تحمل المخاطر',
                child: DropdownButtonFormField<String>(
                  value: _riskTolerance,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('منخفض')),
                    DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                    DropdownMenuItem(value: 'high', child: Text('مرتفع')),
                  ],
                  onChanged: (v) {
                    setState(() => _riskTolerance = v ?? 'medium');
                    _saveSetting('risk_tolerance', _riskTolerance);
                  },
                ),
              ),
              _buildToggleCard(
                icon: Icons.notifications_outlined,
                title: 'الإشعارات',
                subtitle: 'تلقي تنبيهات الأسعار والأخبار',
                value: _notifications,
                onChanged: (v) {
                  setState(() => _notifications = v);
                  _saveSetting('notifications', v);
                },
              ),
              _buildToggleCard(
                icon: Icons.dark_mode_outlined,
                title: 'الوضع الداكن',
                subtitle: 'استخدام المظهر الداكن',
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  _saveSetting('dark_mode', v);
                },
              ),
              const SizedBox(height: 20),

              // Connection Section
              const SectionHeader(title: 'الاتصال', icon: Icons.cloud),
              const SizedBox(height: 8),
              _buildSettingsCard(
                icon: Icons.dns_outlined,
                title: 'عنوان الخادم',
                subtitle: api.baseUrl,
                onTap: () => _showServerUrlDialog(),
              ),
              _buildSettingsCard(
                icon: Icons.info_outline,
                title: 'فحص الاتصال',
                subtitle: 'التحقق من اتصال الخادم',
                onTap: () => _testConnection(),
              ),
              const SizedBox(height: 20),

              // About Section
              const SectionHeader(title: 'حول التطبيق', icon: Icons.info),
              const SizedBox(height: 8),
              _buildSettingsCard(
                icon: Icons.code,
                title: 'الإصدار',
                subtitle: '2.0.0',
              ),
              _buildSettingsCard(
                icon: Icons.web,
                title: 'الموقع الإلكتروني',
                subtitle: 'invist.m2y.net',
              ),
              const SizedBox(height: 20),

              // Logout
              if (_user != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: AppColors.white),
                    label: const Text('تسجيل الخروج',
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/auth'),
                    icon: const Icon(Icons.login, color: AppColors.white),
                    label: const Text('تسجيل الدخول',
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: _user != null
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    (_user?.username ?? _user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_user?.username ?? _user?.name ?? 'مستخدم',
                          style: AppTypography.titleSmall),
                      Text(_user?.email ?? '', style: AppTypography.bodySmall),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _user?.subscriptionTier ?? 'free',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.textMuted, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('غير مسجل الدخول',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('سجل دخولك للوصول لجميع الميزات',
                          style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? child,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleSmall),
                    if (subtitle != null)
                      Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              if (child != null)
                Expanded(child: child)
              else if (onTap != null)
                const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _showServerUrlDialog() async {
    final ctrl = TextEditingController(text: api.baseUrl);
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('عنوان الخادم'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://invist.m2y.net',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                api.setBaseUrl(ctrl.text.trim());
                _saveSetting('server_url', ctrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('تم تحديث الخادم: ${ctrl.text.trim()}')),
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child:
                  const Text('حفظ', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري فحص الاتصال...')),
    );
    try {
      final result = await api.healthCheck();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ الخادم متصل - الحالة: ${result['status'] ?? 'ok'}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('❌ فشل الاتصال: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }
}
