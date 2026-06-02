// ============================================================================
// مساعد الاستثمار Flutter - App Root with Navigation
// Bottom Tab Navigator + AppBar + Drawer + Command Bar
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stocks_screen.dart';
import 'screens/stock_history_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/zakat_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/webview_screen.dart';
import 'api/client.dart';
import 'models/types.dart';

// ============================================================================
// Main Navigator - AppBar + Bottom Tabs + Drawer + Command Bar
// ============================================================================
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _user;
  bool _isLoggedIn = false;

  // Tab titles matching bottom nav items
  final List<String> _titles = [
    'الرئيسية',
    'الأسهم',
    'الكريبتو',
    'المحفظة',
  ];

  // Tab screens — indices align 1:1 with BottomNavigationBar items
  final List<Widget> _screens = [
    const DashboardScreen(),   // 0: Home
    const StocksScreen(),      // 1: Stocks
    const CryptoScreen(),      // 2: Crypto
    const PortfolioScreen(),   // 3: Portfolio
  ];

@override
  void initState() {
    super.initState();
    // Defer auth check to post-frame callback to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final loggedIn = await api.isAuthenticated();
    if (mounted) {
      setState(() { 
        _isLoggedIn = loggedIn;
        // Load user data when login state changes
        if (loggedIn) {
          _loadUserData();
        } else {
          _user = null;
        }
      });
    }
    // Skip getMe() call - user data already available from login response
  }

  Future<void> _loadUserData() async {
    final user = await api.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  void _refreshAuth() {
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        // ── Persistent AppBar with drawer toggle + command bar ──
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPurplePink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.text),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'القائمة',
            ),
          ),
title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_currentIndex],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Cairo', color: AppColors.text),
                ),
                if (_isLoggedIn && _user != null)
                  Text(
                    _user?.username ?? _user?.name ?? 'مستخدم',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary),
                  ),
              ],
            ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPurplePink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.search, color: AppColors.white, size: 18),
              ),
              onPressed: _showCommandBar,
              tooltip: 'بحث سريع',
            ),
  if (_isLoggedIn && _user != null)
    GestureDetector(
      onTap: () => _navigateTo(const SettingsScreen()),
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        decoration: const BoxDecoration(
          gradient: AppColors.gradientPurplePink,
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.transparent,
          child: Text(
            _getUserInitials(_user),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ),
    )
            else
              GestureDetector(
                onTap: () async {
                  await _navigateTo(const AuthScreen());
                  _refreshAuth();
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8, right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: AppColors.gradientPurplePink,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Text(
                    '✨',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surface, AppColors.surfaceMuted],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, color: AppColors.textMuted),
                activeIcon: Icon(Icons.home, color: AppColors.primaryGlow),
                label: 'الرئيسية',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.trending_up_rounded, color: AppColors.textMuted),
                activeIcon: Icon(Icons.trending_up, color: AppColors.primaryGlow),
                label: 'الأسهم',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.currency_bitcoin_rounded, color: AppColors.textMuted),
                activeIcon: Icon(Icons.currency_bitcoin, color: AppColors.primaryGlow),
                label: 'الكريبتو',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.textMuted),
                activeIcon: Icon(Icons.account_balance_wallet, color: AppColors.primaryGlow),
                label: 'المحفظة',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Command Bar - Quick search & navigation
  // ===========================================================================
  void _showCommandBar() {
    showDialog(
      context: context,
      builder: (ctx) => _CommandBarDialog(
        onNavigate: (screen) {
          Navigator.pop(ctx);
          _navigateTo(screen);
        },
        onSwitchTab: (index) {
          Navigator.pop(ctx);
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  // ===========================================================================
  // Side Drawer
  // ===========================================================================
  Widget _buildDrawer() {
    return Drawer(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header with user info
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: AppColors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('مساعد الاستثمار', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white, fontFamily: 'Cairo')),
                  const SizedBox(height: 4),
                  Text('منصة الاستثمار الذكية', style: TextStyle(fontSize: 13, color: AppColors.white.withValues(alpha: 0.8))),
                  if (_isLoggedIn && _user != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.white.withValues(alpha: 0.3),
          child: Text(
            _getUserInitials(_user),
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_user?.username ?? _user?.name ?? 'مستخدم', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white)),
                                Text(_user?.email ?? '', style: TextStyle(fontSize: 10, color: AppColors.white.withValues(alpha: 0.7)), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () { Navigator.pop(context); _navigateTo(const AuthScreen()); _refreshAuth(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.login, color: AppColors.white, size: 16),
                            SizedBox(width: 8),
                            Text('تسجيل الدخول', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Quick Access ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('الوصول السريع', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ),
            _buildDrawerItem(Icons.visibility_outlined, 'قائمة المراقبة', () => _navigateTo(const WatchlistScreen())),
            _buildDrawerItem(Icons.history, 'تاريخ الأسهم', () => _navigateTo(const StockHistoryScreen(ticker: 'EGX'))),

            const Divider(),

            // ── Markets ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('الأسواق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ),
            _buildDrawerItem(Icons.trending_up, 'الأسهم', () => setState(() { _currentIndex = 1; Navigator.pop(context); })),
            _buildDrawerItem(Icons.currency_bitcoin, 'الكريبتو', () => setState(() { _currentIndex = 2; Navigator.pop(context); })),
            _buildDrawerItem(Icons.swap_horiz, 'العملات', () => _navigateTo(const CurrencyScreen())),

            const Divider(),

            // ── Analysis & Tools ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('التحليل والأدوات', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ),
            _buildDrawerItem(Icons.lightbulb_outline, 'التوصيات', () => _navigateTo(const RecommendationsScreen())),
            _buildDrawerItem(Icons.calculate_outlined, 'حاسبة الزكاة', () => _navigateTo(const ZakatScreen())),

            const Divider(),

            // ── Account ──
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text('الحساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            ),
            _buildDrawerItem(Icons.wallet_outlined, 'المحفظة', () => setState(() { _currentIndex = 3; Navigator.pop(context); })),
            _buildDrawerItem(Icons.card_membership_outlined, 'الاشتراكات', () => _navigateTo(const SubscriptionScreen())),
            _buildDrawerItem(Icons.settings_outlined, 'الإعدادات', () => _navigateTo(const SettingsScreen())),
            _buildDrawerItem(Icons.login, _isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول', () {
              if (_isLoggedIn) {
                _handleLogout();
              } else {
                _navigateTo(const AuthScreen()).then((_) => _refreshAuth());
              }
            }),

            const Divider(),

            // ── Website ──
            _buildDrawerItem(Icons.language, 'فتح الموقع', () => _navigateTo(const WebViewScreen())),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('الإصدار 2.0.0 • © 2024 مساعد الاستثمار', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('خروج', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await api.logout();
      setState(() { _user = null; _isLoggedIn = false; });
      if (mounted) Navigator.pop(context); // Close drawer
    }
  }

  String _getUserInitials(User? user) {
    if (user == null) return 'U';
    final String displayName = user.username ?? user.email ?? 'U';
    if (displayName.isEmpty) return 'U';
    return displayName[0].toUpperCase();
  }

  Widget _buildDrawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
    );
  }

  Future<void> _navigateTo(Widget screen) async {
    Navigator.pop(context); // Close drawer if open
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    _refreshAuth(); // Refresh auth state when returning
  }
}

// ===========================================================================
// Command Bar Dialog - Quick search & navigation palette
// ===========================================================================
class _CommandBarDialog extends StatefulWidget {
  final void Function(Widget screen) onNavigate;
  final void Function(int index) onSwitchTab;

  const _CommandBarDialog({required this.onNavigate, required this.onSwitchTab});

  @override
  State<_CommandBarDialog> createState() => _CommandBarDialogState();
}

class _CommandBarDialogState extends State<_CommandBarDialog> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  final List<_CommandAction> _actions = [
    // Quick Access
    _CommandAction('قائمة المراقبة', Icons.visibility_outlined, Icons.visibility, () => WatchlistScreen(), null),
    _CommandAction('تاريخ الأسهم', Icons.history, Icons.history, () => StockHistoryScreen(ticker: 'EGX'), null),
    // Markets
    _CommandAction('الأسهم', Icons.trending_up, Icons.trending_up, null, 1),
    _CommandAction('الكريبتو', Icons.currency_bitcoin_outlined, Icons.currency_bitcoin, null, 2),
    _CommandAction('العملات', Icons.swap_horiz, Icons.swap_horiz, () => CurrencyScreen(), null),
    // Analysis
    _CommandAction('التوصيات', Icons.lightbulb_outline, Icons.lightbulb, () => RecommendationsScreen(), null),
    _CommandAction('حاسبة الزكاة', Icons.calculate_outlined, Icons.calculate, () => ZakatScreen(), null),
    // Account
    _CommandAction('المحفظة', Icons.wallet_outlined, Icons.wallet, null, 3),
    _CommandAction('الاشتراكات', Icons.card_membership_outlined, Icons.card_membership, () => SubscriptionScreen(), null),
    _CommandAction('الإعدادات', Icons.settings_outlined, Icons.settings, () => SettingsScreen(), null),
    _CommandAction('تسجيل الدخول', Icons.login, Icons.login, () => AuthScreen(), null),
    _CommandAction('فتح الموقع', Icons.language, Icons.language, () => WebViewScreen(), null),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_CommandAction> get _filtered {
    if (_query.isEmpty) return _actions;
    return _actions.where((a) => a.label.contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'ابحث أو اختر إجراء...',
                          hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Actions grid
              Flexible(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  childAspectRatio: 1.1,
                  children: filtered.map((action) {
                    return InkWell(
                      onTap: () {
                        if (action.screenBuilder != null) {
                          widget.onNavigate(action.screenBuilder!());
                        } else if (action.tabIndex != null) {
                          widget.onSwitchTab(action.tabIndex!);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryMuted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(action.icon, size: 22, color: AppColors.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              action.label,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandAction {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget Function()? screenBuilder;
  final int? tabIndex;

  _CommandAction(this.label, this.icon, this.activeIcon, this.screenBuilder, this.tabIndex);
}
