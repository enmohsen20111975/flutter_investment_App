// ============================================================================
// مساعد الاستثمار Flutter - Main Entry Point
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/colors.dart';
import 'theme/typography.dart';
import 'app.dart';
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
import 'services/notification_service.dart';
import 'services/version_service.dart';

final darkModeProvider = StateProvider<bool>((ref) => true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if user has auth token (simplified check)
  final bool hasToken = prefs.containsKey('auth_token');

  // Load theme preference
  final bool isDarkMode = prefs.getBool('dark_mode') ?? false;

  // Initialize notification service non-blocking (skip if it takes too long)
  unawaited(NotificationService().init());

  runApp(
    ProviderScope(
      overrides: [
        darkModeProvider.overrideWith((ref) => isDarkMode),
      ],
      child: GLMInvestmentApp(
        initialRoute: hasToken ? '/home' : '/auth',
        isDarkMode: isDarkMode,
      ),
    ),
  );
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
    final darkMode = ref.watch(darkModeProvider);

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
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: AppColors.text),
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
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: AppColors.text),
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
      },
    );
  }
}