// ============================================================================
// مساعد الاستثمار Flutter - Main Entry Point
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/colors.dart';
import 'app.dart';
import 'api/client.dart';
import 'screens/auth_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/stock_history_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/zakat_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/metals_screen.dart';
import 'screens/learning_backtest_screen.dart';
import 'screens/force_update_screen.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'services/version_service.dart';
import 'services/polling_service.dart';

final darkModeProvider = StateProvider<bool>((ref) => true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Load custom server URL if exists
  final String? serverUrl = prefs.getString('server_url');
  if (serverUrl != null && serverUrl.isNotEmpty) {
    GLMApiClient.instance.setBaseUrl(serverUrl);
  }

  // Restore auth token for GLMApiClient
  final String? authToken = prefs.getString('auth_token');
  if (authToken != null && authToken.isNotEmpty) {
    GLMApiClient.instance.setAuthToken(authToken);
  }

  // Check if user has auth token (simplified check)
  final bool hasToken = prefs.containsKey('auth_token');

  // Load theme preference
  final bool isDarkMode = prefs.getBool('dark_mode') ?? false;

  // Initialize notification service non-blocking (skip if it takes too long)
  unawaited(NotificationService().init());
  unawaited(SubscriptionService.instance.init());

  runApp(
    ProviderScope(
      overrides: [
        darkModeProvider.overrideWith((ref) => isDarkMode),
      ],
      child: _AppRoot(
        hasToken: hasToken,
        isDarkMode: isDarkMode,
      ),
    ),
  );
}

/// Root widget that performs the forced-update check before letting the user
/// reach the main app. If the installed version is below the required minimum,
/// a blocking [ForceUpdateScreen] is shown and the rest of the app is
/// inaccessible until the user updates from Google Play.
class _AppRoot extends StatefulWidget {
  final bool hasToken;
  final bool isDarkMode;

  const _AppRoot({
    required this.hasToken,
    required this.isDarkMode,
  });

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  bool _checking = true;
  bool _forceUpdate = false;
  dynamic _versionResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkForcedUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForcedUpdate();
      pollingService.resume();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pollingService.pause();
    }
  }

  Future<void> _checkForcedUpdate() async {
    try {
      final result = await VersionService.instance.checkVersion();
      if (mounted) {
        setState(() {
          _versionResult = result;
          _forceUpdate = result.updateRequired;
          _checking = false;
        });
      }
    } catch (e) {
      debugPrint('[AppRoot] Version check error: $e');
      // On error, do NOT block the user — let them in.
      if (mounted) {
        setState(() {
          _checking = false;
          _forceUpdate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a splash/loading while checking the version.
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Cairo',
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.trending_up_rounded,
                        color: AppColors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text('مساعد الاستثمار',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2.5),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Block the app if a forced update is required.
    if (_forceUpdate && _versionResult != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          fontFamily: 'Cairo',
        ),
        home: ForceUpdateScreen(result: _versionResult),
      );
    }

    // All good — run the normal app.
    return GLMInvestmentApp(
      initialRoute: widget.hasToken ? '/home' : '/auth',
      isDarkMode: widget.isDarkMode,
    );
  }
}

class GLMInvestmentApp extends ConsumerWidget {
  final String initialRoute;
  final bool isDarkMode;

  const GLMInvestmentApp({
    super.key,
    required this.initialRoute,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'مساعد الاستثمار ✨',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              color: AppColors.text),
        ),
        fontFamily: 'Cairo',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Cairo',
              color: AppColors.text),
        ),
        fontFamily: 'Cairo',
      ),
      themeMode: ThemeMode.dark,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: initialRoute,
      routes: {
        '/home': (_) => const MainNavigator(),
        '/auth': (_) => const AuthScreen(),
        '/portfolio': (_) => const PortfolioScreen(),
        '/watchlist': (_) => const WatchlistScreen(),
        '/recommendations': (_) => const RecommendationsScreen(),
        '/subscription': (_) => const SubscriptionScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/webview': (_) => const WebViewScreen(),
        '/stock-history': (_) => const StockHistoryScreen(ticker: 'EGX'),
        '/currency': (_) => const CurrencyScreen(),
        '/crypto': (_) => const CryptoScreen(),
        '/zakat': (_) => const ZakatScreen(),
        '/ai-analysis': (_) => const AiAnalysisScreen(),
        '/metals': (_) => const MetalsScreen(),
        '/learning-backtest': (_) => const LearningBacktestScreen(),
      },
    );
  }
}
