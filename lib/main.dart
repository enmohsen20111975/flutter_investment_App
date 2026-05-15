// ============================================================================
// مساعد الاستثمار Flutter - Main Entry Point
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'screens/auth_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/watchlist_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/ai_analysis_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/stock_history_screen.dart';
import 'screens/metals_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/crypto_screen.dart';
import 'screens/zakat_screen.dart';
import 'services/notification_service.dart';
import 'services/version_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final darkModeProvider = StateProvider<bool>((ref) => false);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Check if user has auth token (simplified check)
  final bool hasToken = prefs.containsKey('auth_token');

  // Load theme preference
  final bool isDarkMode = prefs.getBool('dark_mode') ?? false;

  // Initialize notification service
  await NotificationService().init();

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
      title: 'مساعد الاستثمار',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF6366F1),
          surface: Colors.white,
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1D26),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Color(0xFFF1F5F9),
        ),
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
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
        '/ai-analysis': (_) => const AIAnalysisScreen(),
        '/subscription': (_) => const SubscriptionScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/webview': (_) => const WebViewScreen(),
        '/stock-history': (_) => const StockHistoryScreen(ticker: 'EGX'),
        '/metals': (_) => const MetalsScreen(),
        '/currency': (_) => const CurrencyScreen(),
        '/crypto': (_) => const CryptoScreen(),
        '/zakat': (_) => const ZakatScreen(),
      },
    );
  }
}