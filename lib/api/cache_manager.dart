// ============================================================================
// مساعد الاستثمار Flutter - API Cache Manager
// Implements caching with TTL and request deduplication for API calls
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic cache manager for API responses with TTL and request deduplication
class ApiCacheManager {
  ApiCacheManager._();
  static final ApiCacheManager _instance = ApiCacheManager._();
  static ApiCacheManager get instance => _instance;

  // Cache storage: key -> {data, timestamp, isLoading, completers}
  final Map<String, _CacheEntry<dynamic>> _cache = {};
  final Map<String, Completer<dynamic>> _loadingCompleters = {};

  // Default TTL values for different types of data (can be overridden)
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration shortTtl = Duration(minutes: 1);
  static const Duration longTtl = Duration(hours: 24);
  static const Duration marketTtl = Duration(minutes: 2);

  /// Fetches data with caching and deduplication
  /// 
  /// [key] Unique identifier for the cache entry
  /// [fetcher] Async function that fetches the fresh data
  /// [ttl] Time to live for cached data (defaults to 5 minutes)
  /// [forceRefresh] If true, ignores cache and fetches fresh data
  Future<T> fetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration ttl = defaultTtl,
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCachedValid(key, ttl)) {
      return _cache[key]!.data as T;
    }

    // Return existing loader if one is in progress (deduplication)
    if (_loadingCompleters.containsKey(key)) {
      return _loadingCompleters[key]!.future as Future<T>;
    }

    // Create new loader
    final completer = Completer<T>();
    _loadingCompleters[key] = completer as Completer<dynamic>;

    try {
      // Fetch fresh data
      final data = await fetcher();
      
      // Update cache
      _cache[key] = _CacheEntry<T>(
        data: data,
        timestamp: DateTime.now(),
      );
      
      // Complete the future
      completer.complete(data);
      return data;
    } catch (e) {
      // Propagate error
      completer.completeError(e);
      rethrow;
    } finally {
      // Clean up loader
      _loadingCompleters.remove(key);
    }
  }

  /// Checks if cached data exists and is still valid (not expired)
  bool _isCachedValid(String key, Duration ttl) {
    if (!_cache.containsKey(key)) return false;
    
    final entry = _cache[key]!;
    final age = DateTime.now().difference(entry.timestamp);
    return age < ttl;
  }

  /// Invalidates cache entry for key
  void invalidate(String key) {
    _cache.remove(key);
    _loadingCompleters.remove(key);
  }

  /// Invalidates all cache entries
  void invalidateAll() {
    _cache.clear();
    _loadingCompleters.clear();
  }

  /// Gets cached data if available and valid, otherwise returns null
  T? getIfValid<T>(String key, Duration ttl) {
    if (_isCachedValid(key, ttl)) {
      return _cache[key]!.data as T;
    }
    return null;
  }

  /// Gets cache entry age or null if not cached/expiry
  Duration? getAge(String key) {
    if (!_cache.containsKey(key)) return null;
    return DateTime.now().difference(_cache[key]!.timestamp);
  }

  /// Clears expired entries based on their specific TTLs
  /// Note: This is a simplified version - in practice you'd want to store TTL with each entry
  void cleanExpired() {
    // For simplicity, we'll clear all entries older than longest TTL we use
    const maxTtl = Duration(hours: 24);
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => 
      now.difference(entry.timestamp) > maxTtl);
  }
}

/// Internal cache entry class
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({
    required this.data,
    required this.timestamp,
  });
}

/// Specialized cache manager for market data with shorter TTL
class MarketDataCache {
  MarketDataCache._();
  static final MarketDataCache _instance = MarketDataCache._();
  static MarketDataCache get instance => _instance;

  Future<T> fetchMarketData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'market_$key',
      fetcher: fetcher,
      ttl: ApiCacheManager.marketTtl,
      forceRefresh: forceRefresh,
    );
  }
}

/// Specialized cache manager for static data with longer TTL
class StaticDataCache {
  StaticDataCache._();
  static final StaticDataCache _instance = StaticDataCache._();
  static StaticDataCache get instance => _instance;

  Future<T> fetchStaticData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'static_$key',
      fetcher: fetcher,
      ttl: ApiCacheManager.longTtl,
      forceRefresh: forceRefresh,
    );
  }
}

/// Specialized cache manager for user-specific data
class UserDataCache {
  UserDataCache._();
  static final UserDataCache _instance = UserDataCache._();
  static UserDataCache get instance => _instance;

  Future<T> fetchUserData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'user_$key',
      fetcher: fetcher,
      ttl: ApiCacheManager.defaultTtl,
      forceRefresh: forceRefresh,
    );
  }
}