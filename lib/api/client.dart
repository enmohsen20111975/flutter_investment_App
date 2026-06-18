// ============================================================================
// مساعد الاستثمار Flutter - API Client
// Centralized API communication with caching, error handling, and fallbacks
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'local_database.dart';
import '../models/types.dart';
import 'cache_manager.dart';
import '../services/subscription_service.dart';

class GLMApiClient {
  GLMApiClient._privateConstructor() {
    _initDio();
  }
  static final GLMApiClient _instance = GLMApiClient._privateConstructor();
  static GLMApiClient get instance => _instance;

  late final Dio _dio;
  String _baseUrl = 'https://invist.m2y.net/api';
  String? _authToken;

  late final Dio _aiDio; // Separate Dio instance for AI/long requests
  late final Dio _chartDio; // Separate Dio instance for chart data

  void _initDio() {
    // Default Dio - standard requests
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint(
            '[API Error] ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));

    // AI Dio - for long-running AI requests (120s timeout)
    _aiDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));
    _aiDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint(
            '[API AI Error] ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));

    // Chart Dio - for chart data
    _chartDio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    _chartDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        debugPrint(
            '[API Chart Error] ${error.response?.statusCode} - ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Dio get aiDio => _aiDio;
  Dio get chartDio => _chartDio;

  GLMApiClient() {
    _initDio();
  }
  GLMApiClient.create() {
    _initDio();
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Dio get dio => _dio;

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  // ============================================================================
  // Auth API
  // ============================================================================
  Future<AuthResponse> googleLogin(String idToken) async {
    try {
      debugPrint('[API Auth] Sending Google login request...');
      final response = await _dio.post('/api/auth/google', data: {
        'id_token': idToken,
      });
      final result = AuthResponse.fromJson(response.data);
      if (result.success && result.token != null) {
        await _saveAuthToken(result.token!);
        if (result.user != null) {
          await _saveUserData(result.user!);
        }
      }
      return result;
    } catch (e) {
      debugPrint('[API Auth] Google login failed: $e');
      return AuthResponse(
        success: false,
        message: 'فشل تسجيل الدخول عبر Google: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? phone}) async {
    try {
      final response = await _dio.put('/api/auth/profile', data: {
        if (phone != null) 'phone': phone,
      });
      final user = await getUser();
      if (user != null) {
        final updatedUser = User(
          id: user.id,
          email: user.email,
          username: user.username,
          name: user.name,
          image: user.image,
          isAdmin: user.isAdmin,
          subscriptionTier: user.subscriptionTier,
          defaultRiskTolerance: user.defaultRiskTolerance,
          phone: phone ?? user.phone,
          isActive: user.isActive,
          emailVerified: user.emailVerified,
          lastLogin: user.lastLogin,
          createdAt: user.createdAt,
        );
        await _saveUserData(updatedUser);
      }
      return response.data;
    } catch (e) {
      debugPrint('[API] updateProfile failed: $e');
      final user = await getUser();
      if (user != null) {
        final updatedUser = User(
          id: user.id,
          email: user.email,
          username: user.username,
          name: user.name,
          image: user.image,
          isAdmin: user.isAdmin,
          subscriptionTier: user.subscriptionTier,
          defaultRiskTolerance: user.defaultRiskTolerance,
          phone: phone ?? user.phone,
          isActive: user.isActive,
          emailVerified: user.emailVerified,
          lastLogin: user.lastLogin,
          createdAt: user.createdAt,
        );
        await _saveUserData(updatedUser);
        return {'success': true, 'message': 'تم تحديث الهاتف محلياً'};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _authToken = null;
  }

  // ============================================================================
  // Market API
  // ============================================================================
  Future<MarketOverview> getMarketOverview([String? market]) async {
    final String cacheKey =
        market != null ? 'market_overview_$market' : 'market_overview';
    return ApiCacheManager.instance.fetch<MarketOverview>(
      key: cacheKey,
      fetcher: () async {
        try {
          debugPrint('[API] Fetching market overview for $market...');
          final response =
              await _dio.get('/api/market/overview', queryParameters: {
            if (market != null) 'market': market,
          });
          debugPrint('[API] Market overview response: ${response.data.keys}');
          return MarketOverview.fromJson(response.data);
        } catch (e) {
          debugPrint('[API] getMarketOverview failed: $e');
          // Return empty fallback to prevent stuck UI
          return MarketOverview(
            indices: [],
            marketStatus: MarketStatus(isOpen: null),
            topGainers: [],
            topLosers: [],
          );
        }
      },
      ttl: ApiCacheManager.marketTtl,
    );
  }

  Future<Map<String, dynamic>> getMarketLiveData([String? market]) async {
    final String cacheKey =
        market != null ? 'market_live_data_$market' : 'market_live_data';
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: cacheKey,
      fetcher: () async {
        try {
          final response =
              await _dio.get('/api/market/live-data', queryParameters: {
            if (market != null) 'market': market,
          });
          return response.data;
        } catch (e) {
          debugPrint('[API] getMarketLiveData failed: $e');
          return {};
        }
      },
      ttl: ApiCacheManager.marketTtl,
    );
  }

  Future<Map<String, dynamic>> getMarketInvesting([String? market]) async {
    final String cacheKey =
        market != null ? 'market_investing_$market' : 'market_investing';
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: cacheKey,
      fetcher: () async {
        try {
          final response =
              await _dio.get('/api/market/investing', queryParameters: {
            if (market != null) 'market': market,
          });
          return response.data;
        } catch (e) {
          debugPrint('[API] getMarketInvesting failed: $e');
          return {};
        }
      },
      ttl: ApiCacheManager.marketTtl,
    );
  }

  Future<Map<String, dynamic>> getMarketAiInsights() async {
    try {
      final response =
          await _dio.get('/api/market/recommendations/ai-insights');
      return response.data;
    } catch (e) {
      debugPrint('[API] getMarketAiInsights failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Stock API
  // ============================================================================
  Future<Map<String, dynamic>> getStocks(
      {String search = '', String? market}) async {
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: 'stocks_${market ?? 'all'}_${search.hashCode}',
      fetcher: () async {
        final queryParams = <String, dynamic>{};
        if (search.isNotEmpty) queryParams['query'] = search;
        if (market != null) queryParams['market'] = market;
        try {
          debugPrint(
              '[API] Fetching stocks with query: $search, market: $market');
          final response =
              await _dio.get('/api/stocks', queryParameters: queryParams);
          debugPrint(
              '[API] Stocks response: ${(response.data['stocks'] as List?)?.length ?? 0} stocks');
          return response.data;
        } catch (e) {
          debugPrint('[API] getStocks failed: $e');
          try {
            final localStocks =
                await LocalDatabase.instance.queryStocks(search: search);
            return {'stocks': localStocks};
          } catch (localError) {
            debugPrint('[API] Local stocks fallback failed: $localError');
            return {'stocks': []};
          }
        }
      },
      ttl: ApiCacheManager
          .marketTtl, // Stock data doesn't change extremely frequently
    );
  }

  Future<Map<String, dynamic>> getStockMovementClassification(
      {String? market}) async {
    try {
      final data = await _dio
          .get('/api/stocks/movement-classification', queryParameters: {
        if (market != null) 'market': market,
      });
      return data.data;
    } catch (e) {
      debugPrint(
          '[API] Movement classification error (may be unavailable): $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStockFundamentals(
      {required String ticker}) async {
    try {
      final response = await _dio.get('/api/stocks/$ticker/fundamentals');
      return response.data;
    } catch (e) {
      debugPrint('[API] getStockFundamentals failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Crypto API
  // ============================================================================
  Future<Map<String, dynamic>> getCrypto() async {
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: 'crypto_data',
      fetcher: () async {
        try {
          debugPrint('[API] Fetching crypto data...');
          final response = await _dio.get('/api/crypto');
          debugPrint('[API] Crypto response keys: ${response.data.keys}');
          return response.data;
        } catch (e) {
          debugPrint('[API] getCrypto failed: $e');
          return {'coins': [], 'data': []};
        }
      },
      ttl: ApiCacheManager.marketTtl,
    );
  }

  // ============================================================================
  // MOBILE Portfolio API (CORRECT endpoints for mobile)
  // ============================================================================
  Future<PortfolioResponse> getPortfolio() async {
    // Fallback to mobile endpoint with old method name for compatibility
    return getMobilePortfolio();
  }

  Future<PortfolioResponse> getMobilePortfolio() async {
    return ApiCacheManager.instance.fetch<PortfolioResponse>(
      key: 'portfolio_data',
      fetcher: () async {
        try {
          debugPrint('[API Mobile Portfolio] Fetching...');
          final response = await _dio.get('/api/mobile/portfolio');
          debugPrint(
              '[API Mobile Portfolio] Response items: ${(response.data["items"] as List?)?.length ?? 0}');
          return PortfolioResponse.fromJson(response.data);
        } on DioException catch (e) {
          debugPrint('[API Mobile Portfolio] DioException: ${e.type}');
          if (e.response?.statusCode == 401) {
            debugPrint('[API Mobile Portfolio] Unauthorized');
          }
          return PortfolioResponse(positions: [], summary: null);
        } catch (e) {
          debugPrint('[API Mobile Portfolio] failed: $e');
          return PortfolioResponse(positions: [], summary: null);
        }
      },
      ttl: const Duration(minutes: 2),
    );
  }

  Future<Map<String, dynamic>> analyzePortfolio() async {
    try {
      final result = await _dio.post('/api/portfolio/analyze');
      return result.data;
    } catch (e) {
      debugPrint('[Portfolio] Analysis error: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE Portfolio CRUD (CORRECT endpoints)
  // ============================================================================
  Future<Map<String, dynamic>> addToPortfolio(Map<String, dynamic> data) async {
    return addToMobilePortfolio(data);
  }

  Future<Map<String, dynamic>> addToMobilePortfolio(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/mobile/portfolio', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] addToMobilePortfolio failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeFromPortfolio(String id) async {
    return removeMobilePortfolio(id);
  }

  Future<Map<String, dynamic>> removeMobilePortfolio(String id) async {
    try {
      final response = await _dio
          .delete('/api/mobile/portfolio', queryParameters: {'id': id});
      return response.data;
    } catch (e) {
      debugPrint('[API] removeMobilePortfolio failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPortfolioIntelligence() async {
    try {
      final response = await _dio.get('/api/mobile/portfolio/intelligence');
      return response.data;
    } catch (e) {
      debugPrint('[API] getPortfolioIntelligence failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Watchlist API
  // ============================================================================
  Future<WatchlistResponse> getWatchlist() async {
    return ApiCacheManager.instance.fetch<WatchlistResponse>(
      key: 'watchlist_data',
      fetcher: () async {
        try {
          debugPrint('[API Watchlist] Fetching...');
          final response = await _dio.get('/api/watchlist');
          debugPrint(
              '[API Watchlist] Response items: ${(response.data["items"] as List?)?.length ?? 0}');
          return WatchlistResponse.fromJson(response.data);
        } catch (e) {
          debugPrint('[API] getWatchlist failed: $e');
          return WatchlistResponse(success: false, items: [], total: 0);
        }
      },
      ttl: const Duration(minutes: 2),
    );
  }

  Future<WatchlistResponse> getWatchlistEnhanced() async {
    return ApiCacheManager.instance.fetch<WatchlistResponse>(
      key: 'watchlist_enhanced',
      fetcher: () async {
        try {
          debugPrint('[API Watchlist] Fetching enhanced...');
          final response = await _dio.get('/api/watchlist-enhanced');
          debugPrint(
              '[API Watchlist] Enhanced response items: ${(response.data["items"] as List?)?.length ?? 0}');
          return WatchlistResponse.fromJson(response.data);
        } catch (e) {
          debugPrint('[API] getWatchlistEnhanced failed: $e');
          return WatchlistResponse(success: false, items: [], total: 0);
        }
      },
      ttl: const Duration(minutes: 2),
    );
  }

  Future<Map<String, dynamic>> addToWatchlist(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/watchlist', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] addToWatchlist failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> removeFromWatchlist(String id) async {
    try {
      final response = await _dio.delete('/api/watchlist/$id');
      return response.data;
    } catch (e) {
      debugPrint('[API] removeFromWatchlist failed: $e');
      rethrow;
    }
  }

  // ============================================================================
  // Metals API (Gold/Silver)
  // ============================================================================
  Future<List<dynamic>> getGoldPrices() async {
    try {
      final response = await _dio.get('/api/metals');
      return response.data;
    } catch (e) {
      debugPrint('[API] getGoldPrices failed: $e');
      return [];
    }
  }

  // ============================================================================
  // Currency API
  // ============================================================================
  Future<List<dynamic>> getCurrencyList() async {
    try {
      final response = await _dio.get('/api/currency/list');
      return response.data;
    } catch (e) {
      debugPrint('[API] getCurrencyList failed: $e');
      return [];
    }
  }

  // ============================================================================
  // Zakat API
  // ============================================================================
  Future<Map<String, dynamic>> calculateZakat(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/zakat/calculate', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] calculateZakat failed: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE Recommendations API (CORRECT endpoints)
  // ============================================================================
  Future<List<dynamic>> getRecommendations() async {
    return getMobileRecommendations();
  }

  Future<List<dynamic>> getMobileRecommendations({String? persona}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (persona != null) queryParams['persona'] = persona;
      final response = await _dio.get('/api/mobile/recommendations',
          queryParameters: queryParams);
      if (response.data is List) return response.data;
      return response.data['recommendations'] ?? response.data['data'] ?? [];
    } catch (e) {
      debugPrint('[API] getMobileRecommendations failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMorningReports() async {
    try {
      final response = await _dio.get('/api/reports/morning');
      return response.data;
    } catch (e) {
      debugPrint('[API] getMorningReports failed: $e');
      return {};
    }
  }

  // ============================================================================
  // AI Analysis API
  // ============================================================================
  Future<Map<String, dynamic>> getLiveAnalysis() async {
    try {
      final response = await _dio.get('/api/v2/live-analysis');
      return response.data;
    } catch (e) {
      debugPrint('[API] getLiveAnalysis failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Subscription API
  // ============================================================================
  Future<Map<String, dynamic>> getCurrentSubscription() async {
    return getSubscriptionCurrent();
  }

  Future<Map<String, dynamic>> getSubscriptionCurrent() async {
    try {
      final response = await _dio.get('/api/subscription/current');
      return response.data;
    } catch (e) {
      debugPrint('[API] getSubscriptionCurrent failed: $e');
      return {};
    }
  }

  Future<List<dynamic>> getSubscriptionPlansV2() async {
    try {
      final response = await _dio.get('/api/subscription/plans');
      return response.data is List
          ? response.data
          : (response.data['plans'] ?? []);
    } catch (e) {
      debugPrint('[API] getSubscriptionPlansV2 failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> upgradeSubscription(String planId) async {
    try {
      final response = await _dio.post('/api/subscription/upgrade', data: {
        'plan_id': planId,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] upgradeSubscription failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> subscribeToPlan(String planId) async {
    try {
      final response = await _dio.post('/api/subscription/subscribe', data: {
        'plan_id': planId,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] subscribeToPlan failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> startTrial() async {
    try {
      final response = await _dio.post('/api/subscription/trial');
      return response.data;
    } catch (e) {
      debugPrint('[API] startTrial failed: $e');
      return {};
    }
  }

  Future<FeatureAccessResult> checkSubscriptionAccess(String feature) async {
    try {
      final response = await _dio.post('/api/subscription/check-access', data: {
        'feature': feature,
      });
      return FeatureAccessResult.fromJson(response.data);
    } catch (e) {
      debugPrint('[API] checkSubscriptionAccess failed: $e');
      return FeatureAccessResult(
        feature: feature,
        hasAccess: false,
        reason: 'Failed to check access',
        reasonEn: 'Failed to check access',
        tier: 'free',
      );
    }
  }

  // ============================================================================
  // Local Database API (for fallback)
  // ============================================================================
  Future<List<Map<String, dynamic>>> getLocalStocks(
      {String search = ''}) async {
    return await LocalDatabase.instance.queryStocks(search: search);
  }

  Future<Map<String, dynamic>?> getLocalStockDetail(String ticker) async {
    return await LocalDatabase.instance.getStockDetail(ticker);
  }

  Future<List<Map<String, dynamic>>> getLocalStockHistory(String ticker,
      {int days = 30}) async {
    return await LocalDatabase.instance.getStockHistory(ticker, days: days);
  }

  // ============================================================================
  // Stock History Screen Methods
  // ============================================================================
  Future<StockHistoryResponse> getStockHistory(String ticker,
      {int days = 30}) async {
    try {
      final response = await _dio
          .get('/api/stocks/$ticker/history', queryParameters: {'days': days});
      return StockHistoryResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('[API] getStockHistory failed: $e');
      return StockHistoryResponse(data: [], summary: null);
    }
  }

  Future<Map<String, dynamic>> getStockDetail(String ticker,
      {bool flat = false}) async {
    try {
      final response = await _dio
          .get('/api/stocks/$ticker', queryParameters: {'flat': flat});
      return response.data;
    } catch (e) {
      debugPrint('[API] getStockDetail failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStockRecommendation(String ticker) async {
    try {
      final response = await _dio.get('/api/stocks/$ticker/recommendation');
      return response.data;
    } catch (e) {
      debugPrint('[API] getStockRecommendation failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStockProfessionalAnalysis(
      String ticker) async {
    try {
      final response =
          await _dio.get('/api/stocks/$ticker/professional-analysis');
      return response.data;
    } catch (e) {
      debugPrint('[API] getStockProfessionalAnalysis failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStockNews(String ticker) async {
    try {
      final response = await _dio.get('/api/stocks/$ticker/news');
      return response.data;
    } catch (e) {
      debugPrint('[API] getStockNews failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Currency Screen Methods
  // ============================================================================
  Future<dynamic> getCurrency() async {
    try {
      final response = await _dio.get('/api/currency');
      return response.data;
    } catch (e) {
      debugPrint('[API] getCurrency failed: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> convertCurrency(
      String from, String to, double amount) async {
    try {
      final response = await _dio.post('/api/currency/convert',
          data: {'from': from, 'to': to, 'amount': amount});
      return response.data;
    } catch (e) {
      debugPrint('[API] convertCurrency failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Crypto Detail Screen Methods
  // ============================================================================
  Future<Map<String, dynamic>> getCryptoDetail(String coinId) async {
    try {
      final response = await _dio.get('/api/crypto/$coinId');
      return response.data;
    } catch (e) {
      debugPrint('[API] getCryptoDetail failed: $e');
      return {};
    }
  }

  Future<List<dynamic>> getCryptoOHLC(
      {required String coinId, required int days}) async {
    try {
      final response = await _dio
          .get('/api/crypto/$coinId/ohlc', queryParameters: {'days': days});
      return response.data;
    } catch (e) {
      debugPrint('[API] getCryptoOHLC failed: $e');
      return [];
    }
  }

  // ============================================================================
  // AI Analysis Screen Methods
  // ============================================================================
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/api/health');
      return response.data;
    } catch (e) {
      debugPrint('[API] healthCheck failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getBatchAnalysis() async {
    try {
      final response = await _dio.get('/api/ai/batch-analysis');
      return response.data;
    } catch (e) {
      debugPrint('[API] getBatchAnalysis failed: $e');
      return {};
    }
  }

  Future<List<dynamic>> getPredictions() async {
    return getMobilePredictions();
  }

  Future<List<dynamic>> getMobilePredictions(
      {int? limit, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (status != null) queryParams['status'] = status;
      final response = await _aiDio.get('/api/mobile/predictions',
          queryParameters: queryParams);
      if (response.data is List) return response.data;
      return response.data['predictions'] ?? response.data['data'] ?? [];
    } catch (e) {
      debugPrint('[API] getMobilePredictions failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPredictionPerformance(
      {String? month, String? market}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (market != null) queryParams['market'] = market;
      final response = await _aiDio.get('/api/predictions/performance',
          queryParameters: queryParams);
      return response.data;
    } catch (e) {
      debugPrint('[API] getPredictionPerformance failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getGlobalPredictions() async {
    try {
      final response = await _aiDio.get('/api/global-predictions');
      return response.data;
    } catch (e) {
      debugPrint('[API] getGlobalPredictions failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> analyzeStock(String ticker) async {
    try {
      final response =
          await _dio.post('/api/ai/analyze-stock', data: {'ticker': ticker});
      return response.data;
    } catch (e) {
      debugPrint('[API] analyzeStock failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Subscription Screen Methods
  // ============================================================================
  Future<List<dynamic>> getSubscriptionPlans() async {
    try {
      final response = await _dio.get('/api/subscription/plans');
      return response.data;
    } catch (e) {
      debugPrint('[API] getSubscriptionPlans failed: $e');
      return [];
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (e) {
      debugPrint('[API] logout failed: $e');
    }
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = _baseUrl;
  }

  Future<Map<String, dynamic>> getExpertRecommendations(
      {String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      final response = await _dio.get('/api/recommendations/expert',
          queryParameters: queryParams);
      return response.data;
    } catch (e) {
      debugPrint('[API] getExpertRecommendations failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _dio.get('/api/auth/me');
      return response.data;
    } catch (e) {
      debugPrint('[API] getMe failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Unified Multi-Market APIs
  // ============================================================================
  Future<Map<String, dynamic>> getUnifiedMarkets() async {
    try {
      final response = await _dio.get('/api/v2/unified/markets');
      return response.data;
    } catch (e) {
      debugPrint('[API] getUnifiedMarkets failed: $e');
      return {};
    }
  }

  Future<List<dynamic>> getUnifiedPersonas() async {
    try {
      final response = await _dio.get('/api/v2/unified/personas');
      return response.data is List
          ? response.data
          : (response.data['personas'] ?? []);
    } catch (e) {
      debugPrint('[API] getUnifiedPersonas failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getUnifiedConfig(
      {required String market, required String persona}) async {
    try {
      final response =
          await _dio.get('/api/v2/unified/config', queryParameters: {
        'market': market,
        'persona': persona,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] getUnifiedConfig failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> scanUnifiedMarket({
    required String market,
    required String persona,
    int topN = 20,
    int minScore = 65,
  }) async {
    try {
      final response = await _dio.post('/api/v2/unified/scan', data: {
        'market': market,
        'persona': persona,
        'top_n': topN,
        'min_score': minScore,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] scanUnifiedMarket failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> analyzeUnifiedStock({
    required String ticker,
    required String market,
    required String persona,
    double? support,
    double? resistance,
  }) async {
    try {
      final response = await _dio.post('/api/v2/unified/analyze', data: {
        'ticker': ticker,
        'market': market,
        'persona': persona,
        if (support != null) 'support': support,
        if (resistance != null) 'resistance': resistance,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] analyzeUnifiedStock failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getMaestroAnalysis(String ticker,
      {required String market, required String persona}) async {
    try {
      final response =
          await _dio.get('/api/maestro/stock/$ticker', queryParameters: {
        'market': market,
        'persona': persona,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] getMaestroAnalysis failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Backtesting APIs
  // ============================================================================
  Future<Map<String, dynamic>> runBacktest({
    required String strategy,
    required String ticker,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.post('/api/backtest', data: {
        'strategy': strategy,
        'ticker': ticker,
        'start_date': startDate,
        'end_date': endDate,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] runBacktest failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getBacktestingResults({
    String? action,
    String? persona,
    int? year,
    int? month,
    int? weeks,
  }) async {
    try {
      final response = await _dio.get('/api/backtesting', queryParameters: {
        if (action != null) 'action': action,
        if (persona != null) 'persona': persona,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
        if (weeks != null) 'weeks': weeks,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] getBacktestingResults failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> runUnifiedBacktest(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/backtesting/unified', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] runUnifiedBacktest failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> runKimiBacktest() async {
    try {
      final response = await _dio.get('/api/kimi/backtest/run');
      return response.data;
    } catch (e) {
      debugPrint('[API] runKimiBacktest failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> runWalkForward() async {
    try {
      final response = await _dio.get('/api/walk-forward/run');
      return response.data;
    } catch (e) {
      debugPrint('[API] runWalkForward failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Learning & AI Self-Learning APIs
  // ============================================================================
  Future<Map<String, dynamic>> getUnifiedLearningStatus() async {
    try {
      final response = await _dio.get('/api/unified-learning/status');
      return response.data;
    } catch (e) {
      debugPrint('[API] getUnifiedLearningStatus failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> runIterativeLearning() async {
    try {
      final response = await _dio.post('/api/unified-learning/iterative');
      return response.data;
    } catch (e) {
      debugPrint('[API] runIterativeLearning failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> runIntelligentLearning() async {
    try {
      final response = await _dio.post('/api/unified-learning/intelligent');
      return response.data;
    } catch (e) {
      debugPrint('[API] runIntelligentLearning failed: $e');
      return {};
    }
  }

  Future<List<dynamic>> getUnifiedLearningIndicators() async {
    try {
      final response = await _dio.get('/api/unified-learning/indicators');
      return response.data is List
          ? response.data
          : (response.data['indicators'] ?? []);
    } catch (e) {
      debugPrint('[API] getUnifiedLearningIndicators failed: $e');
      return [];
    }
  }

  Future<List<dynamic>> getUnifiedLearningPatterns() async {
    try {
      final response = await _dio.get('/api/unified-learning/patterns');
      return response.data is List
          ? response.data
          : (response.data['patterns'] ?? []);
    } catch (e) {
      debugPrint('[API] getUnifiedLearningPatterns failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> mineUnifiedLearningLessons() async {
    try {
      final response = await _dio.post('/api/unified-learning/mine-lessons');
      return response.data;
    } catch (e) {
      debugPrint('[API] mineUnifiedLearningLessons failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Payment Verification APIs
  // ============================================================================
  Future<Map<String, dynamic>> verifyGooglePlayReceipt(
      String receiptData) async {
    try {
      final response =
          await _dio.post('/api/google-play/verify-receipt', data: {
        'receipt_data': receiptData,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] verifyGooglePlayReceipt failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> verifyInstapayPayment(
      String txHashOrDetails) async {
    try {
      final response = await _dio.post('/api/instapay/verify', data: {
        'tx_hash': txHashOrDetails,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] verifyInstapayPayment failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> createPaymobPayment({
    required double amount,
    required String currency,
    required String planId,
  }) async {
    try {
      final response = await _dio.post('/api/paymob/create-payment', data: {
        'amount': amount,
        'currency': currency,
        'plan_id': planId,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] createPaymobPayment failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Metals API (Gold & Silver)
  // ============================================================================
  Future<Map<String, dynamic>> getGold() async {
    try {
      final response = await _dio.get('/api/mobile/gold');
      return response.data;
    } catch (e) {
      debugPrint('[API] getGold failed: $e');
      try {
        final response = await _dio.get('/api/metals/gold');
        return response.data;
      } catch (_) {
        return {};
      }
    }
  }

  Future<List<dynamic>> getGoldHistory(
      {required String karat, required int days}) async {
    try {
      final response =
          await _dio.get('/api/mobile/gold/history', queryParameters: {
        'karat': karat,
        'days': days,
      });
      return response.data is List
          ? response.data
          : (response.data['history'] ?? []);
    } catch (e) {
      debugPrint('[API] getGoldHistory failed: $e');
      try {
        final response =
            await _dio.get('/api/metals/gold/history', queryParameters: {
          'karat': karat,
          'days': days,
        });
        return response.data is List
            ? response.data
            : (response.data['history'] ?? []);
      } catch (_) {
        return [];
      }
    }
  }

  // ============================================================================
  // MOBILE Dashboard API
  // ============================================================================
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      debugPrint('[API] Fetching mobile dashboard...');
      final response = await _dio.get('/api/mobile/dashboard');
      return response.data;
    } catch (e) {
      debugPrint('[API] getDashboard failed: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE Notifications API
  // ============================================================================
  Future<List<dynamic>> getMobileNotifications() async {
    try {
      final response = await _dio.get('/api/mobile/notifications');
      if (response.data is List) return response.data;
      return response.data['notifications'] ?? response.data['data'] ?? [];
    } catch (e) {
      debugPrint('[API] getMobileNotifications failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) async {
    try {
      final response =
          await _dio.post('/api/mobile/notifications', data: {'id': id});
      return response.data;
    } catch (e) {
      debugPrint('[API] markNotificationRead failed: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE Alerts API
  // ============================================================================
  Future<Map<String, dynamic>> getAlertSettings() async {
    try {
      final response = await _dio.get('/api/mobile/alerts/settings');
      return response.data;
    } catch (e) {
      debugPrint('[API] getAlertSettings failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.post('/api/mobile/alerts/settings', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] createAlert failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> deleteAlert(String id) async {
    try {
      final response = await _dio
          .delete('/api/mobile/alerts/settings', queryParameters: {'id': id});
      return response.data;
    } catch (e) {
      debugPrint('[API] deleteAlert failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Hunter/Screener API
  // ============================================================================
  Future<List<dynamic>> getHunterScreener(
      {String? market, int limit = 10}) async {
    try {
      final response = await _dio.get('/api/hunter/screener', queryParameters: {
        if (market != null) 'market': market,
        'limit': limit,
      });
      if (response.data is List) return response.data;
      return response.data['opportunities'] ?? response.data['data'] ?? [];
    } catch (e) {
      debugPrint('[API] getHunterScreener failed: $e');
      return [];
    }
  }

  // ============================================================================
  // AI Chat API
  // ============================================================================
  Future<Map<String, dynamic>> sendAiChat(String message,
      {Map<String, dynamic>? context}) async {
    try {
      final response = await _aiDio.post('/api/ai/chat', data: {
        'message': message,
        if (context != null) 'context': context,
      });
      return response.data;
    } catch (e) {
      debugPrint('[API] sendAiChat failed: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE News API
  // ============================================================================
  Future<List<dynamic>> getMobileNews() async {
    try {
      final response = await _dio.get('/api/mobile/news');
      if (response.data is List) return response.data;
      return response.data['news'] ??
          response.data['articles'] ??
          response.data['data'] ??
          [];
    } catch (e) {
      debugPrint('[API] getMobileNews failed: $e');
      return [];
    }
  }

  // ============================================================================
  // Learning Content API
  // ============================================================================
  Future<List<dynamic>> getLearningContent() async {
    try {
      final response = await _dio.get('/api/learning/content');
      if (response.data is List) return response.data;
      return response.data['content'] ??
          response.data['lessons'] ??
          response.data['data'] ??
          [];
    } catch (e) {
      debugPrint('[API] getLearningContent failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> updateLearningProgress(String lessonId) async {
    try {
      final response = await _dio
          .post('/api/learning/progress', data: {'lesson_id': lessonId});
      return response.data;
    } catch (e) {
      debugPrint('[API] updateLearningProgress failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Market Status API
  // ============================================================================
  Future<Map<String, dynamic>> getMarketStatus() async {
    try {
      final response = await _dio.get('/api/market/status');
      return response.data;
    } catch (e) {
      debugPrint('[API] getMarketStatus failed: $e');
      return {};
    }
  }

  // ============================================================================
  // MOBILE Zakat API
  // ============================================================================
  Future<Map<String, dynamic>> getMobileZakat(
      Map<String, dynamic> params) async {
    try {
      final response = await _dio.get('/api/mobile/zakat-calculator',
          queryParameters: params);
      return response.data;
    } catch (e) {
      debugPrint('[API] getMobileZakat failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Watchlist Intelligence API
  // ============================================================================
  Future<Map<String, dynamic>> getWatchlistIntelligence() async {
    try {
      final response = await _dio.get('/api/mobile/watchlist/intelligence');
      return response.data;
    } catch (e) {
      debugPrint('[API] getWatchlistIntelligence failed: $e');
      return {};
    }
  }

  // ============================================================================
  // Crypto Recommendations API
  // ============================================================================
  Future<List<dynamic>> getCryptoRecommendations(
      {int limit = 10, String? risk}) async {
    try {
      final response =
          await _dio.get('/api/crypto/recommendations', queryParameters: {
        'limit': limit,
        if (risk != null) 'risk': risk,
      });
      if (response.data is List) return response.data;
      return response.data['recommendations'] ?? response.data['data'] ?? [];
    } catch (e) {
      debugPrint('[API] getCryptoRecommendations failed: $e');
      return [];
    }
  }

  // ============================================================================
  // Finance Asset APIs
  // ============================================================================
  Future<List<dynamic>> getFinanceAssets() async {
    try {
      final response = await _dio.get('/api/finance/assets');
      return response.data is List
          ? response.data
          : (response.data['assets'] ?? []);
    } catch (e) {
      debugPrint('[API] getFinanceAssets failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addFinanceAsset(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/finance/assets', data: data);
      return response.data;
    } catch (e) {
      debugPrint('[API] addFinanceAsset failed: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> deleteFinanceAsset(String id) async {
    try {
      final response = await _dio.delete('/api/finance/assets/$id');
      return response.data;
    } catch (e) {
      debugPrint('[API] deleteFinanceAsset failed: $e');
      return {};
    }
  }
}

// Top-level getter for backward compatibility
GLMApiClient get api => GLMApiClient.instance;
