// ============================================================================
// مساعد الاستثمار Flutter - Settings Screen
// App settings, account management, preferences
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_localizations.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../services/subscription_service.dart';
import '../services/version_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  String _riskTolerance = 'medium';
  String _appVersion = '';
  bool _devModeEnabled = false;  // FIX (FLUTTER-PROD-3): developer features خلف dev mode
  String _language = 'ar';
  bool _notifications = true;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _riskTolerance = prefs.getString('risk_tolerance') ?? 'medium';
      _language = prefs.getString('language') ?? 'ar';
      _notifications = prefs.getBool('notifications') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
      // FIX (FLUTTER-PROD-3): developer features خلف dev mode toggle
      // 5 taps على version card = enable dev mode (similar to Android developer options)
      _devModeEnabled = prefs.getBool('dev_mode_enabled') ?? false;
    });

    // FIX (FLUTTER-PROD-1): استخدم VersionService للحصول على الإصدار الحقيقي
    // (بدل ما نظهر '2.0.0' hardcoded)
    try {
      final version = await VersionService.instance.getCurrentVersion();
      final buildNumber = await VersionService.instance.getCurrentBuildNumber();
      if (mounted) {
        setState(() {
          _appVersion = '$version+$buildNumber';
        });
      }
    } catch (e) {
      debugPrint('[SettingsScreen] Failed to get version: $e');
      if (mounted) {
        setState(() {
          _appVersion = '3.0.1+44';  // fallback to pubspec version
        });
      }
    }

    // Try to load user data (skip if API fails)
    if (await api.isAuthenticated()) {
      try {
        final userData = await api.getMe();
        final user = User.fromJson(userData);
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  // FIX (FLUTTER-PROD-3): 5 taps على version card = enable/disable dev mode
  // (similar to Android's developer options pattern)
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;
  Future<void> _handleVersionTap() async {
    final now = DateTime.now();
    if (_lastVersionTap == null || now.difference(_lastVersionTap!) > const Duration(seconds: 2)) {
      _versionTapCount = 1;
    } else {
      _versionTapCount++;
    }
    _lastVersionTap = now;

    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      final prefs = await SharedPreferences.getInstance();
      final newDevMode = !(_devModeEnabled);
      await prefs.setBool('dev_mode_enabled', newDevMode);
      if (!mounted) return;
      setState(() {
        _devModeEnabled = newDevMode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newDevMode
              ? 'تم تفعيل وضع المطور — ميزات إضافية الآن متاحة'
              : 'تم إيقاف وضع المطور'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_versionTapCount >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('اضغط ${5 - _versionTapCount} مرات أخرى لتفعيل وضع المطور'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // FIX (FLUTTER-PROD-3): فتح الموقع في المتصفح الخارجي
  Future<void> _openWebsite() async {
    final Uri url = Uri.parse('https://invist.m2y.net');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الموقع: $e')),
      );
    }
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
      await SubscriptionService.instance.clearCache();
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
                  initialValue: _riskTolerance,
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
                icon: Icons.language,
                title: 'English Language',
                subtitle: 'Switch between Arabic and English',
                value: _language == 'en',
                onChanged: (v) {
                  setState(() => _language = v ? 'en' : 'ar');
                  _saveSetting('language', _language);
                  AppLocalizations.setLocale(v ? const Locale('en', 'US') : const Locale('ar', 'EG'));
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
              // FIX (FLUTTER-PROD-3): developer features خلف dev mode toggle
              // (5 taps على version card = enable/disable dev mode)
              if (_devModeEnabled) ...[
                _buildSettingsCard(
                  icon: Icons.dns_outlined,
                  title: 'عنوان الخادم (Dev)',
                  subtitle: api.baseUrl,
                  onTap: () => _showServerUrlDialog(),
                ),
                _buildSettingsCard(
                  icon: Icons.info_outline,
                  title: 'فحص الاتصال (Dev)',
                  subtitle: 'التحقق من اتصال الخادم',
                  onTap: () => _testConnection(),
                ),
                const SizedBox(height: 20),
              ],

              // About Section
              const SectionHeader(title: 'حول التطبيق', icon: Icons.info),
              const SizedBox(height: 8),
              _buildSettingsCard(
                icon: Icons.code,
                title: 'الإصدار',
                subtitle: _appVersion.isNotEmpty ? _appVersion : '3.0.1+44',
                onTap: _handleVersionTap,  // 5 taps = enable dev mode
              ),
              _buildSettingsCard(
                icon: Icons.web,
                title: 'الموقع الإلكتروني',
                subtitle: 'invist.m2y.net',
                onTap: () => _openWebsite(),
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

  String _getUserInitials() {
    if (_user == null) return 'U';
    final String displayName = _user!.username ?? _user!.email;
    if (displayName.trim().isEmpty) return 'U';
    return displayName.trim()[0].toUpperCase();
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
                    _getUserInitials(),
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
            activeThumbColor: AppColors.primary,
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
