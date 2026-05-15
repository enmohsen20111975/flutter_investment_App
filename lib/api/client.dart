// ============================================================================
// مساعد الاستثمار Flutter - API Client
// Dio-based HTTP client matching the React Native API
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database.dart';
import '../models/types.dart';

// ============================================================================
// Auth API
// ============================================================================
mixin AuthApi {
  Dio get _dio;
  
  Future<AuthResponse> googleLogin(String idToken) async {
    try {
      final response = await _dio.post('/api/auth/google', data: {'id_token': idToken});
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return AuthResponse(
          success: false,
          message: data['message'] ?? data['error'] ?? 'Google sign-in failed',
          messageAr: data['message_ar'],
        );
      }
      rethrow;
    }
  }

  Future<User> getMe() async {
    final response = await _dio.get('/api/auth/me');
    return User.fromJson(response.data['user']);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', 
      '{"id":"${user.id}","email":"${user.email}","username":"${user.username ?? ""}","name":"${user.name ?? ""}","subscription_tier":"${user.subscriptionTier ?? "free"}","is_admin":${user.isAdmin ?? false}}');
  }
}

// ============================================================================
// Market API
// ============================================================================
mixin MarketApi {
  Dio get _dio;
  
Future<MarketOverview> getMarketOverview() async {
    try {
      final response = await _dio.get('/api/market/overview');
      return MarketOverview.fromJson(response.data);
    } catch (e) {
      debugPrint('[API] getMarketOverview failed: $e');
      final localIndices = await LocalDatabase.instance.getMarketIndices();
      return MarketOverview(
        indices: localIndices.map((e) => MarketIndex.fromJson(e)).toList(),
        marketStatus: MarketStatus(isOpen: null),
      );
    }
  }

  Future<Map<String, dynamic>> getMarketStatus() async {
    final response = await _dio.get('/api/market/status');
    return response.data;
  }

  Future<Map<String, dynamic>> getMarketIndices() async {
    try {
      final response = await _dio.get('/api/market/indices');
      return response.data;
    } catch (_) {
      final localIndices = await LocalDatabase.instance.getMarketIndices();
      return {'indices': localIndices};
    }
  }
}

// ============================================================================
// Stock API
// ============================================================================
mixin StockApi {
  Dio get _dio;
  
  Future<Map<String, dynamic>> getStocks([String search = '']) async {
    final queryParams = <String, dynamic>{};
    if (search.isNotEmpty) queryParams['query'] = search;
    try {
      final response = await _dio.get('/api/stocks', queryParameters: queryParams);
      return response.data;
    } catch (_) {
      final localStocks = await LocalDatabase.instance.queryStocks(search: search);
      return {'stocks': localStocks};
    }
  }

  Future<Map<String, dynamic>> getStockDetail(String ticker, {bool flat = false}) async {
    final queryParameters = flat ? {'flat': 1} : null;
    try {
      final response = await _dio.get('/api/stocks/$ticker', queryParameters: queryParameters);
      final data = response.data;
      // Handle wrapped response format: {data: {...}, source: "vps"}
      if (data is Map && data['data'] != null && data['data'] is Map) {
        final innerData = Map<String, dynamic>.from(data['data'] as Map);
        // Ensure ticker field exists
        if (innerData['ticker'] == null) innerData['ticker'] = ticker;
        return innerData;
      }
      return data;
    } catch (_) {
      final localStock = await LocalDatabase.instance.getStockDetail(ticker);
      if (localStock != null) return localStock;
      rethrow;
    }
  }

  Future<StockHistoryResponse> getStockHistory(String ticker, [int days = 30]) async {
    final response = await _dio.get('/api/stocks/$ticker/history', queryParameters: {'days': days});
    return StockHistoryResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getStockRecommendation(String ticker) async {
    try {
      final response = await _dio.get('/api/stocks/$ticker/recommendation');
      return response.data;
    } catch (_) {
      try {
        final response = await _dio.get('/api/mobile/stocks/$ticker/recommendation');
        return response.data;
      } catch (_) {
        final localRecommendation = await LocalDatabase.instance.getStockRecommendation(ticker);
        if (localRecommendation != null) return localRecommendation;
        rethrow;
      }
    }
  }

  Future<StockRecommendationResponse> getStockRecommendationTyped(String ticker) async {
    final data = await getStockRecommendation(ticker);
    return StockRecommendationResponse.fromJson(data);
  }

  Future<StockDetailResponse> getStockDetailTyped(String ticker, {bool flat = false}) async {
    final data = await getStockDetail(ticker, flat: flat);
    return StockDetailResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> getStockProfessionalAnalysis(String ticker) async {
    try {
      final response = await _dio.get('/api/stocks/$ticker/professional-analysis');
      return response.data;
    } catch (_) {
      try {
        final response = await _dio.get('/api/mobile/stocks/$ticker/professional-analysis');
        return response.data;
      } catch (_) {
        final response = await _dio.get('/api/mobile/analysis/$ticker');
        return response.data;
      }
    }
  }

  Future<Map<String, dynamic>> searchStocks(String query) async {
    final response = await _dio.get('/api/stocks/search', queryParameters: {'q': query});
    return response.data;
  }
}

// ============================================================================
// Gold & Currency API
// ============================================================================
mixin GoldApi {
  Dio get _dio;
  
  Future<GoldResponse> getGold() async {
    final response = await _dio.get('/api/market/gold');
    return GoldResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getGoldHistory({String karat = '24', int days = 30}) async {
    final response = await _dio.get('/api/market/gold/history', queryParameters: {'karat': karat, 'days': days});
    return response.data;
  }

  Future<GoldHistoryResponse> getGoldHistoryTyped({String karat = '24', int days = 30}) async {
    final response = await _dio.get('/api/market/gold/history', queryParameters: {'karat': karat, 'days': days});
    return GoldHistoryResponse.fromJson(response.data);
  }
}

mixin CurrencyApi {
  Dio get _dio;
  
Future<CurrencyResponse> getCurrency() async {
    try {
      final response = await _dio.get('/api/market/currency');
      return CurrencyResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('[API] getCurrency failed: $e');
      return CurrencyResponse(success: false, currencies: []);
    }
  }

  Future<ConversionResult> convertCurrency(String from, String to, double amount) async {
    final response = await _dio.get('/api/currency/convert', queryParameters: {
      'from': from,
      'to': to,
      'amount': amount,
    });
    return ConversionResult.fromJson(response.data);
  }
}

// ============================================================================
// Crypto API
// ============================================================================
mixin CryptoApi {
  Dio get _dio;
  
Future<Map<String, dynamic>> getCrypto() async {
    try {
      final response = await _dio.get('/api/crypto');
      return response.data;
    } catch (e) {
      debugPrint('[API] getCrypto failed: $e');
      return {'coins': []};
    }
  }

  Future<Map<String, dynamic>> getCryptoDetail(String id) async {
    final response = await _dio.get('/api/crypto/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getCryptoOHLC({required String coinId, int days = 30}) async {
    final response = await _dio.get('/api/crypto/ohlc', queryParameters: {'coin_id': coinId, 'days': days});
    return response.data;
  }
}

// ============================================================================
// Recommendations API
// ============================================================================
mixin RecommendationApi {
  Dio get _dio;
  
  Future<Map<String, dynamic>> getExpertRecommendations({String? status, String? expertName, String? ticker, int limit = 100}) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (status != null) queryParams['status'] = status;
    if (expertName != null) queryParams['expert_name'] = expertName;
    if (ticker != null) queryParams['ticker'] = ticker;

    try {
      final response = await _dio.get('/api/expert-recommendations', queryParameters: queryParams);
      return response.data;
    } catch (_) {
      final response = await _dio.get('/api/mobile/expert-recommendations', queryParameters: queryParams);
      return response.data;
    }
  }

  Future<Map<String, dynamic>> getExpertStats() async {
    try {
      final response = await _dio.get('/api/expert-recommendations/experts');
      return response.data;
    } catch (_) {
      final response = await _dio.get('/api/mobile/expert-recommendations/experts');
      return response.data;
    }
  }

  Future<Map<String, dynamic>> createExpertRecommendation(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/expert-recommendations', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateExpertRecommendation(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/expert-recommendations', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deleteExpertRecommendation(String id) async {
    final response = await _dio.delete('/api/expert-recommendations', queryParameters: {'id': id});
    return response.data;
  }
}

mixin PredictionApi {
  Dio get _dio;
  
  Future<Map<String, dynamic>> getPredictions({String? status, String? ticker, int limit = 50}) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (status != null) queryParams['status'] = status;
    if (ticker != null) queryParams['ticker'] = ticker;
    final response = await _dio.get('/api/predictions', queryParameters: queryParams);
    return response.data;
  }
}

// ============================================================================
// AI Analysis API
// ============================================================================
mixin AIApi {
  Dio get _dio;
  
  Future<Map<String, dynamic>> analyzeStock(String ticker, {String analysisType = 'technical'}) async {
    try {
      final response = await _dio.get('/api/mobile/analysis/$ticker', queryParameters: {'analysis_type': analysisType});
      return response.data;
    } catch (_) {
      final response = await _dio.post('/api/ai-analysis', data: {
        'ticker': ticker,
        'analysis_type': analysisType,
      });
      return response.data;
    }
  }

  Future<Map<String, dynamic>> getStockAnalysis(String symbol) async {
    try {
      final response = await _dio.get('/api/v2/stock/$symbol/analysis');
      return response.data;
    } catch (_) {
      final response = await _dio.get('/api/mobile/analysis/$symbol');
      return response.data;
    }
  }

  Future<Map<String, dynamic>> getAIRecommend({String? ticker}) async {
    final data = <String, dynamic>{};
    if (ticker != null) data['ticker'] = ticker;
    final response = await _dio.post('/api/v2/recommend', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getBatchAnalysis() async {
    final response = await _dio.get('/api/stocks/batch-analysis');
    return response.data;
  }
}

// ============================================================================
// Portfolio & Watchlist API
// ============================================================================
mixin PortfolioApi {
  Dio get _dio;
  
  Future<PortfolioResponse> getPortfolio() async {
    final response = await _dio.get('/api/portfolio');
    return PortfolioResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> addToPortfolio(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/portfolio', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> removeFromPortfolio(String id) async {
    final response = await _dio.delete('/api/portfolio', queryParameters: {'id': id});
    return response.data;
  }
}

mixin WatchlistApi {
  Dio get _dio;
  
  Future<WatchlistResponse> getWatchlist() async {
    final response = await _dio.get('/api/watchlist');
    return WatchlistResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> addToWatchlist(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/watchlist', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> removeFromWatchlist(String id) async {
    final response = await _dio.delete('/api/watchlist/$id');
    return response.data;
  }
}

// ============================================================================
// Main API Client
// ============================================================================
class ApiClient
    with
        AuthApi,
        MarketApi,
        StockApi,
        GoldApi,
        CurrencyApi,
        CryptoApi,
        RecommendationApi,
        PredictionApi,
        AIApi,
        PortfolioApi,
        WatchlistApi {
  static const String _productionUrl = 'https://invist.m2y.net';

  @override
  late final Dio _dio;
  String _baseUrl = _productionUrl;

  String get baseUrl => _baseUrl;
  static bool get debug => kDebugMode;
  
  Dio get dio => _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': 'ar-EG,ar;q=0.9,en;q=0.8',
        'User-Agent': 'Investment-Assistant-Flutter/2.0',
        'X-Requested-With': 'XMLHttpRequest',
      },
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (debug) {
          debugPrint('[API] ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (debug) {
          debugPrint('[API ERROR] ${error.message}');
          if (error.response != null) {
            debugPrint('[API ERROR] Status: ${error.response?.statusCode}');
            debugPrint('[API ERROR] Body: ${error.response?.data}');
          }
        }
        handler.next(error);
      },
    ));
  }

  void setBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/$'), '');
    _dio.options.baseUrl = _baseUrl;
  }

  Future<ZakatCalculation> calculateZakat(Map<String, double> data) async {
    try {
      final response = await _dio.post('/api/zakat/calculate', data: data);
      return ZakatCalculation.fromJson(response.data);
    } catch (_) {
      final response = await _dio.post('/api/mobile/zakat-calculator', data: _normalizeZakatData(data));
      return ZakatCalculation.fromJson(response.data);
    }
  }

  Map<String, dynamic> _normalizeZakatData(Map<String, double> data) {
    return {
      'cash': data['cash'] ?? 0,
      'gold_grams': data['gold_grams'] ?? data['gold_silver'] ?? 0,
      'gold_karat': data['gold_karat'] ?? 24,
      'stocks': data['stocks'] ?? 0,
      'receivables': data['receivables'] ?? 0,
      'other_assets': data['other_assets'] ?? 0,
      'debts': data['debts'] ?? 0,
      'currency': 'EGP',
    };
  }

  Future<Map<String, dynamic>> getSubscriptionPlans() async {
    final response = await _dio.get('/api/subscription/plans');
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentSubscription() async {
    final response = await _dio.get('/api/subscription/current');
    return response.data;
  }

  Future<Map<String, dynamic>> activateSubscription(String planId) async {
    final response = await _dio.post('/api/subscription/activate', data: {'plan_id': planId});
    return response.data;
  }

  Future<Map<String, dynamic>> startTrial() async {
    final response = await _dio.post('/api/subscription/start-trial');
    return response.data;
  }

  Future<Map<String, dynamic>> subscribeToPlan(String plan) async {
    final response = await _dio.post('/api/subscribe/$plan');
    return response.data;
  }

  Future<Map<String, dynamic>> createPayment({required int amount, required String plan}) async {
    final response = await _dio.post('/api/paymob/create-payment', data: {
      'amount': amount,
      'currency': 'EGP',
      'plan': plan,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getFinanceAssets() async {
    final response = await _dio.get('/api/finance/assets');
    return response.data;
  }

  Future<Map<String, dynamic>> addFinanceAsset(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/finance/assets', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getFinanceObligations() async {
    final response = await _dio.get('/api/finance/obligations');
    return response.data;
  }

  Future<Map<String, dynamic>> getFinanceReports() async {
    final response = await _dio.get('/api/finance/reports');
    return response.data;
  }

  Future<Map<String, dynamic>> runBacktest(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/backtest', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getBacktestingResults() async {
    final response = await _dio.get('/api/backtesting');
    return response.data;
  }

  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/api/health');
    return response.data;
  }
}

final api = ApiClient();