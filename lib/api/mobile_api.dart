// ============================================================================
// مساعد الاستثمار Flutter - Mobile API Wrapper
// Unified wrapper for all mobile endpoints with retry + error handling.
// Caching is fully delegated to ApiCacheManager (no more double-storage).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'client.dart';
import '../models/types.dart';
import 'cache_manager.dart';

/// Mobile API service with retry logic and unified error handling.
class MobileApiService {
  MobileApiService._();
  static final MobileApiService _instance = MobileApiService._();
  static MobileApiService get instance => _instance;

  final GLMApiClient _api = GLMApiClient.instance;

  /// Max retry attempts for transient failures
  static const int _maxRetries = 2;

  /// Base delay for exponential backoff (ms)
  static const int _baseDelayMs = 500;

  // ---------------------------------------------------------------------------
  // Retry helper
  // ---------------------------------------------------------------------------

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
                '[MobileApi] $label — client error (${e.response?.statusCode}), no retry');
            rethrow;
          }
        }
        if (attempt >= _maxRetries) {
          debugPrint('[MobileApi] $label — all $attempt retries failed: $e');
          rethrow;
        }
        final delay = Duration(milliseconds: _baseDelayMs * (1 << attempt));
        debugPrint(
            '[MobileApi] $label — attempt $attempt failed, retrying in ${delay.inMilliseconds}ms…');
        await Future.delayed(delay);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Error messages (Arabic)
  // ---------------------------------------------------------------------------

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
          final code = error.response?.statusCode;
          if (code == 401) return 'انتهت الجلسة - يرجى تسجيل الدخول مرة أخرى';
          if (code == 403) return 'ليس لديك صلاحية للوصول إلى هذه الميزة';
          if (code == 404) return 'المورد المطلوب غير موجود';
          if (code == 429) return 'طلبات كثيرة جداً - حاول بعد قليل';
          if (code != null && code >= 500) return 'خطأ في الخادم - حاول لاحقاً';
          return 'حدث خطأ غير متوقع ($code)';
        default:
          return 'فشل الاتصال - تحقق من اتصالك بالإنترنت';
      }
    }
    return 'حدث خطأ غير متوقع';
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // NOTE: Caching is now handled entirely by ApiCacheManager (with persistence).
  //       We no longer duplicate data into SharedPreferences here.
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDashboard({
    String? market,
    bool forceRefresh = false,
  }) async {
    final marketKey = market ?? 'EGX';
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: 'mobile_dashboard_$marketKey',
      ttl: CacheTtl.market,
      forceRefresh: forceRefresh,
      persist: true,   // survives cold start
      fetcher: () => _withRetry(
        () => _api.getDashboard(market: market),
        label: 'getDashboard',
      ),
    );
  }

  Future<void> clearDashboardCache({String? market}) async {
    final marketKey = market ?? 'EGX';
    ApiCacheManager.instance.invalidate('mobile_dashboard_$marketKey');
    debugPrint('[MobileApi] Dashboard cache cleared for $market');
  }

  // ---------------------------------------------------------------------------
  // Portfolio
  // ---------------------------------------------------------------------------

  Future<PortfolioResponse> getMobilePortfolio() {
    return _withRetry(() => _api.getMobilePortfolio(), label: 'getMobilePortfolio');
  }

  Future<Map<String, dynamic>> addToMobilePortfolio(Map<String, dynamic> data) {
    return _withRetry(() => _api.addToMobilePortfolio(data), label: 'addToMobilePortfolio');
  }

  Future<Map<String, dynamic>> removeMobilePortfolio(String id) {
    return _withRetry(() => _api.removeMobilePortfolio(id), label: 'removeMobilePortfolio');
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getMobileRecommendations({String? persona}) {
    return _withRetry(
      () => _api.getMobileRecommendations(persona: persona),
      label: 'getMobileRecommendations',
    );
  }

  // ---------------------------------------------------------------------------
  // Predictions
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getMobilePredictions({int? limit, String? status}) {
    return _withRetry(
      () => _api.getMobilePredictions(limit: limit, status: status),
      label: 'getMobilePredictions',
    );
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getMobileNotifications() {
    return _withRetry(() => _api.getMobileNotifications(), label: 'getMobileNotifications');
  }

  Future<Map<String, dynamic>> markNotificationRead(String id) {
    return _withRetry(() => _api.markNotificationRead(id), label: 'markNotificationRead');
  }

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getAlertSettings() {
    return _withRetry(() => _api.getAlertSettings(), label: 'getAlertSettings');
  }

  Future<Map<String, dynamic>> createAlert(Map<String, dynamic> data) {
    return _withRetry(() => _api.createAlert(data), label: 'createAlert');
  }

  Future<bool> deleteAlert(String id) {
    return _withRetry(() => _api.deleteAlert(id), label: 'deleteAlert');
  }

  // ---------------------------------------------------------------------------
  // Hunter Screener
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getHunterScreener({String? market, int limit = 10}) {
    return _withRetry(
      () => _api.getHunterScreener(market: market, limit: limit),
      label: 'getHunterScreener',
    );
  }

  // ---------------------------------------------------------------------------
  // AI Chat
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> sendAiChat(String message,
      {Map<String, dynamic>? context}) {
    return _withRetry(
      () => _api.sendAiChat(message, context: context),
      label: 'sendAiChat',
    );
  }

  // ---------------------------------------------------------------------------
  // News
  // NOTE: Caching now fully delegated to ApiCacheManager (persist: true).
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getMobileNews({bool forceRefresh = false}) {
    return ApiCacheManager.instance.fetch<List<dynamic>>(
      key: 'mobile_news',
      ttl: CacheTtl.normal,
      forceRefresh: forceRefresh,
      persist: true,
      fetcher: () => _withRetry(() => _api.getMobileNews(), label: 'getMobileNews'),
    );
  }

  // ---------------------------------------------------------------------------
  // Learning
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getLearningContent() {
    return ApiCacheManager.instance.fetch<List<dynamic>>(
      key: 'learning_content',
      ttl: CacheTtl.longLived,
      fetcher: () => _withRetry(() => _api.getLearningContent(), label: 'getLearningContent'),
    );
  }

  Future<Map<String, dynamic>> updateLearningProgress(String lessonId) {
    return _withRetry(
      () => _api.updateLearningProgress(lessonId),
      label: 'updateLearningProgress',
    );
  }

  // ---------------------------------------------------------------------------
  // Market Status
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMarketStatus() {
    return ApiCacheManager.instance.fetch<Map<String, dynamic>>(
      key: 'market_status',
      ttl: const Duration(minutes: 3),
      fetcher: () => _withRetry(() => _api.getMarketStatus(), label: 'getMarketStatus'),
    );
  }

  // ---------------------------------------------------------------------------
  // Subscription
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSubscriptionCurrent() {
    return _withRetry(() => _api.getSubscriptionCurrent(), label: 'getSubscriptionCurrent');
  }

  Future<List<dynamic>> getSubscriptionPlansV2() {
    return ApiCacheManager.instance.fetch<List<dynamic>>(
      key: 'subscription_plans',
      ttl: CacheTtl.longLived,
      fetcher: () => _withRetry(() => _api.getSubscriptionPlansV2(), label: 'getSubscriptionPlansV2'),
    );
  }
}

// Top-level getter
MobileApiService get mobileApi => MobileApiService.instance;
