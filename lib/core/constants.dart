// ============================================================================
// مساعد الاستثمار Flutter - Core Constants
// API URLs, timeouts, padding system, and app-wide constants
// ============================================================================

class AppConstants {
  AppConstants._();

  // ============================================================================
  // API Configuration
  // ============================================================================
  static const String baseUrl = 'https://invist.m2y.net';
  static const String apiPrefix = '/api';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration aiConnectTimeout = Duration(seconds: 30);
  static const Duration aiReceiveTimeout = Duration(seconds: 120);
  static const Duration chartConnectTimeout = Duration(seconds: 15);
  static const Duration chartReceiveTimeout = Duration(seconds: 15);

  // ============================================================================
  // Pagination
  // ============================================================================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // ============================================================================
  // Caching
  // ============================================================================
  static const Duration cacheTtl = Duration(minutes: 5);
  static const Duration subscriptionCacheTtl = Duration(minutes: 5);

  // ============================================================================
  // Polling Intervals
  // ============================================================================
  static const Duration notificationPollInterval = Duration(seconds: 30);
  static const Duration dashboardPollInterval = Duration(seconds: 30);

  // ============================================================================
  // Padding System (4pt grid)
  // ============================================================================
  static const double paddingXs = 4;
  static const double paddingSm = 8;
  static const double paddingMd = 12;
  static const double paddingBase = 16;
  static const double paddingLg = 20;
  static const double paddingXl = 24;
  static const double paddingXxl = 32;
  static const double paddingXxxl = 40;
  static const double paddingXxxxl = 48;

  // ============================================================================
  // Border Radius
  // ============================================================================
  static const double radiusNone = 0;
  static const double radiusXs = 2;
  static const double radiusSm = 6;
  static const double radiusBase = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusXxxl = 28;
  static const double radiusFull = 9999;

  // ============================================================================
  // Font Sizes
  // ============================================================================
  static const double fontSizeXs = 10;
  static const double fontSizeSm = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSizeXxl = 24;
  static const double fontSizeXxxl = 30;
  static const double fontSizeXxxxl = 36;

  // ============================================================================
  // Subscription Limits
  // ============================================================================
  static const int freeTierWatchlistLimit = 3;
  static const int freeTierPortfolioLimit = 3;

  // ============================================================================
  // Feature Gates
  // ============================================================================
  static const String featureStockHistoryRecommendation = 'stock_history_recommendation';
  static const String featureStockHistoryAnalysis = 'stock_history_analysis';
  static const String featureAiAnalysis = 'ai_analysis';
  static const String featureWatchlistAdd = 'watchlist_add';
  static const String featurePortfolioAdd = 'portfolio_add';

  // ============================================================================
  // Animation Durations
  // ============================================================================
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ============================================================================
  // SharedPreferences Keys
  // ============================================================================
  static const String prefAuthToken = 'auth_token';
  static const String prefUserData = 'user_data';
  static const String prefDarkMode = 'dark_mode';
  static const String prefActiveMarket = 'active_market';
  static const String prefServerUrl = 'server_url';
  static const String prefSubscriptionCache = 'subscription_cache';
  static const String prefNotifiedIds = 'notified_notification_ids';
}
