// ============================================================================
// مساعد الاستثمار Flutter - Mobile API Wrapper
// Unified wrapper for all mobile endpoints with retry + error handling
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'client.dart';
import 'cache_manager.dart';
import '../models/types.dart';

/// Mobile API service with retry logic and unified error handling
class MobileApiService {
  MobileApiService._privateConstructor();
  static final MobileApiService _instance =
      MobileApiService._privateConstructor();
  static MobileApiService get instance => _instance;

  final GLMApiClient _api = GLMApiClient.instance;

  /// Max retry attempts for failed requests
  static const int _maxRetries = 3;

  /// Base delay for exponential backoff (ms)
  static const int _baseDelayMs = 500;

  /// Execute an API call with automatic retry + exponential backoff
  Future<T> _withRetry<T>(
    Future<T> Function() call, {
    String label = 'API call',
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await call();
      } catch (e) {
        attempt++;
        if (e is DioException) {
          // Don't retry on 4xx errors (client errors)
          if (e.response != null &&
              e.response!.statusCode! >= 400 &&
              e.response!.statusCode! < 500) {
            debugPrint(
                '[MobileApi] $label - Client error (${e.response?.statusCode}), not retrying');
            rethrow;
          }
        }
        if (attempt >= _maxRetries) {
          debugPrint('[MobileApi] $label - All $attempt retries failed: $e');
          rethrow;
        }
        final delay = Duration(milliseconds: _baseDelayMs * (1 << attempt));
        debugPrint(
            '[MobileApi] $label - Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
  }

  /// Unified error message in Arabic
  String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'تعذر الاتصال بالخادم - تحقق من اتصالك بالإنترنت';
        case DioExceptionType.receiveTimeout:
          return 'انتهت مهلة الاستجابة - حاول مرة أخرى';
        case DioExceptionType.connectionError:
          return 'لا يوجد اتصال بالإنترنت';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401)
            return 'انتهت الجلسة - يرجى تسجيل الدخول مرة أخرى';
          if (statusCode == 403) return 'ليس لديك صلاحية للوصول إلى هذه الميزة';
          if (statusCode == 404) return 'المورد المطلوب غير موجود';
          if (statusCode == 429) return 'طلبات كثيرة جداً - حاول بعد قليل';
          if (statusCode != null && statusCode >= 500)
            return 'خطأ في الخادم - حاول لاحقاً';
          return 'حدث خطأ غير متوقع (${error.response?.statusCode})';
        default:
          return 'فشل الاتصال - تحقق من اتصالك بالإنترنت';
      }
    }
    return 'حدث خطأ غير متوقع';
  }

  // ============================================================================
  // Mobile Dashboard
  // ============================================================================

  Future<Map<String, dynamic>> getDashboard({String? market, bool forceRefresh = false}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    final cacheKey = 'cached_mobile_dashboard_${market ?? "EGX"}';
    
    if (!forceRefresh && prefs != null) {
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final Map<String, dynamic> cachedData = jsonDecode(cachedStr) as Map<String, dynamic>;
          debugPrint('[MobileApi] Returning cached dashboard data for $market');
          _fetchAndCacheDashboard(prefs, market);
          return cachedData;
        } catch (e) {
          debugPrint('[MobileApi] Failed to parse cached dashboard: $e');
        }
      }
    }

    final data = await _withRetry(
      () => _api.getDashboard(market: market),
      label: 'getDashboard',
    );

    if (prefs != null && data.isNotEmpty) {
      await prefs.setString(cacheKey, jsonEncode(data));
    }
    return data;
  }

  Future<void> _fetchAndCacheDashboard(SharedPreferences prefs, String? market) async {
    try {
      final data = await _api.getDashboard(market: market);
      if (data.isNotEmpty) {
        final cacheKey = 'cached_mobile_dashboard_${market ?? "EGX"}';
        await prefs.setString(cacheKey, jsonEncode(data));
        debugPrint('[MobileApi] Background dashboard cache updated successfully for $market.');
      }
    } catch (e) {
      debugPrint('[MobileApi] Background dashboard fetch failed: $e');
    }
  }

  Future<void> clearDashboardCache({String? market}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_mobile_dashboard_${market ?? "EGX"}';
      await prefs.remove(cacheKey);
      debugPrint('[MobileApi] Dashboard cache cleared for $market');
    } catch (e) {
      debugPrint('[MobileApi] Failed to clear dashboard cache: $e');
    }
  }

  // ============================================================================
  // Mobile Portfolio
  // ============================================================================

  Future<PortfolioResponse> getMobilePortfolio() {
    return _withRetry(
      () => _api.getMobilePortfolio(),
      label: 'getMobilePortfolio',
    );
  }

  Future<Map<String, dynamic>> addToMobilePortfolio(Map<String, dynamic> data) {
    return _withRetry(
      () => _api.addToMobilePortfolio(data),
      label: 'addToMobilePortfolio',
    );
  }

  Future<Map<String, dynamic>> removeMobilePortfolio(String id) {
    return _withRetry(
      () => _api.removeMobilePortfolio(id),
      label: 'removeMobilePortfolio',
    );
  }

  // ============================================================================
  // Mobile Recommendations
  // ============================================================================

  Future<List<dynamic>> getMobileRecommendations({String? persona}) {
    return _withRetry(
      () => _api.getMobileRecommendations(persona: persona),
      label: 'getMobileRecommendations',
    );
  }

  // ============================================================================
  // Mobile Predictions
  // ============================================================================

  Future<List<dynamic>> getMobilePredictions({int? limit, String? status}) {
    return _withRetry(
      () => _api.getMobilePredictions(limit: limit, status: status),
      label: 'getMobilePredictions',
    );
  }

  // ============================================================================
  // Notifications
  // ============================================================================

  Future<List<dynamic>> getMobileNotifications() {
    return _withRetry(
      () => _api.getMobileNotifications(),
      label: 'getMobileNotifications',
    );
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) {
    return _withRetry(
      () => _api.markNotificationRead(id),
      label: 'markNotificationRead',
    );
  }

  // ============================================================================
  // Alerts
  // ============================================================================

  Future<Map<String, dynamic>> getAlertSettings() {
    return _withRetry(
      () => _api.getAlertSettings(),
      label: 'getAlertSettings',
    );
  }

  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> data) {
    return _withRetry(
      () => _api.createAlert(data),
      label: 'createAlert',
    );
  }

  Future<Map<String, dynamic>> deleteAlert(String id) {
    return _withRetry(
      () => _api.deleteAlert(id),
      label: 'deleteAlert',
    );
  }

  // ============================================================================
  // Hunter Screener
  // ============================================================================

  Future<List<dynamic>> getHunterScreener({String? market, int limit = 10}) {
    return _withRetry(
      () => _api.getHunterScreener(market: market, limit: limit),
      label: 'getHunterScreener',
    );
  }

  // ============================================================================
  // AI Chat
  // ============================================================================

  Future<Map<String, dynamic>> sendAiChat(String message,
      {Map<String, dynamic>? context}) {
    return _withRetry(
      () => _api.sendAiChat(message, context: context),
      label: 'sendAiChat',
    );
  }

  // ============================================================================
  // News
  // ============================================================================

  Future<List<dynamic>> getMobileNews({bool forceRefresh = false}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}

    if (!forceRefresh && prefs != null) {
      final cachedStr = prefs.getString('cached_mobile_news');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        try {
          final List<dynamic> cachedData = jsonDecode(cachedStr) as List<dynamic>;
          debugPrint('[MobileApi] Returning cached news data');
          _fetchAndCacheNews(prefs);
          return cachedData;
        } catch (e) {
          debugPrint('[MobileApi] Failed to parse cached news: $e');
        }
      }
    }

    final data = await _withRetry(
      () => _api.getMobileNews(),
      label: 'getMobileNews',
    );

    if (prefs != null && data.isNotEmpty) {
      await prefs.setString('cached_mobile_news', jsonEncode(data));
    }
    return data;
  }

  Future<void> _fetchAndCacheNews(SharedPreferences prefs) async {
    try {
      final data = await _api.getMobileNews();
      if (data.isNotEmpty) {
        await prefs.setString('cached_mobile_news', jsonEncode(data));
        debugPrint('[MobileApi] Background news cache updated successfully.');
      }
    } catch (e) {
      debugPrint('[MobileApi] Background news fetch failed: $e');
    }
  }

  // ============================================================================
  // Learning Content
  // ============================================================================

  Future<List<dynamic>> getLearningContent() {
    return _withRetry(
      () => _api.getLearningContent(),
      label: 'getLearningContent',
    );
  }

  Future<Map<String, dynamic>> updateLearningProgress(String lessonId) {
    return _withRetry(
      () => _api.updateLearningProgress(lessonId),
      label: 'updateLearningProgress',
    );
  }

  // ============================================================================
  // Market Status
  // ============================================================================

  Future<Map<String, dynamic>> getMarketStatus() {
    return _withRetry(
      () => _api.getMarketStatus(),
      label: 'getMarketStatus',
    );
  }

  // ============================================================================
  // Subscription
  // ============================================================================

  Future<Map<String, dynamic>> getSubscriptionCurrent() {
    return _withRetry(
      () => _api.getSubscriptionCurrent(),
      label: 'getSubscriptionCurrent',
    );
  }

  Future<List<dynamic>> getSubscriptionPlansV2() {
    return _withRetry(
      () => _api.getSubscriptionPlansV2(),
      label: 'getSubscriptionPlansV2',
    );
  }
}

// Top-level getter
MobileApiService get mobileApi => MobileApiService.instance;
