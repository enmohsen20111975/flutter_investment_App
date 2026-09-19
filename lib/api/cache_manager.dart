// ============================================================================
// مساعد الاستثمار Flutter - API Cache Manager
// In-memory LRU cache with optional SharedPreferences persistence,
// stale-while-revalidate, and request deduplication.
// ============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// TTL constants (centralised so screens don't hard-code their own values)
// ---------------------------------------------------------------------------
class CacheTtl {
  CacheTtl._();

  /// Live market prices — refresh every 3 minutes
  static const Duration market = Duration(minutes: 3);

  /// Stock/sector lists — relatively stable, 10 minute window
  static const Duration stockList = Duration(minutes: 10);

  /// User-specific data (portfolio, watchlist) — 5 minutes
  static const Duration userData = Duration(minutes: 5);

  /// General API responses — 5 minutes
  static const Duration normal = Duration(minutes: 5);

  /// Essentially static content (currency codes, stock info) — 24 hours
  static const Duration longLived = Duration(hours: 24);

  /// Historical OHLCV data — refresh after 6 hours
  static const Duration stockHistory = Duration(hours: 6);

  /// After expiry, serve stale data for up to this long while refreshing
  static const Duration staleGrace = Duration(minutes: 30);
}

// ---------------------------------------------------------------------------
// Internal cache entry
// ---------------------------------------------------------------------------
class _CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;
  final Duration ttl;
  DateTime lastAccess;

  _CacheEntry({
    required this.data,
    required this.fetchedAt,
    required this.ttl,
    DateTime? lastAccess,
  }) : lastAccess = lastAccess ?? fetchedAt;

  bool get isExpired => DateTime.now().difference(fetchedAt) >= ttl;

  bool get isStale {
    final age = DateTime.now().difference(fetchedAt);
    return age >= ttl && age < (ttl + CacheTtl.staleGrace);
  }
}

// ---------------------------------------------------------------------------
// Main cache manager
// ---------------------------------------------------------------------------
class ApiCacheManager {
  ApiCacheManager._();
  static final ApiCacheManager instance = ApiCacheManager._();

  // Legacy aliases kept for backward compat with existing call sites
  static const Duration defaultTtl  = CacheTtl.normal;
  static const Duration shortTtl    = Duration(minutes: 1);
  static const Duration longTtl     = CacheTtl.longLived;
  static const Duration marketTtl   = CacheTtl.market;
  static const Duration staleGrace  = CacheTtl.staleGrace;
  static const int maxEntries        = 200;

  final Map<String, _CacheEntry<dynamic>> _memory = {};

  /// Completers for in-flight fetches — deduplicates concurrent callers
  final Map<String, Completer<dynamic>> _loading = {};

  /// Generation counter — incremented on invalidateAll() to discard stale ops
  int _generation = 0;

  /// Stream that emits cache keys when their value is updated
  final StreamController<String> _updates =
      StreamController<String>.broadcast();
  Stream<String> get updates => _updates.stream;

  // ---------------------------------------------------------------------------
  // Core fetch method
  // ---------------------------------------------------------------------------

  /// Fetch [key] from cache, calling [fetcher] on a miss or after expiry.
  ///
  /// When [staleWhileRevalidate] is true (default), expired-but-not-stale data
  /// is returned immediately while a background refresh runs concurrently.
  Future<T> fetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration ttl = CacheTtl.normal,
    bool forceRefresh = false,
    bool staleWhileRevalidate = true,
    /// Whether to persist the result to SharedPreferences for next cold start
    bool persist = false,
  }) async {
    _evictExpired();

    final gen = _generation;
    final cached = _memory[key];

    // --- HIT: fresh in memory ---
    if (!forceRefresh && cached != null && !cached.isExpired) {
      cached.lastAccess = DateTime.now();
      return cached.data as T;
    }

    // --- STALE HIT: serve stale, refresh in background ---
    if (!forceRefresh && cached != null && cached.isStale && staleWhileRevalidate) {
      cached.lastAccess = DateTime.now();
      if (!_loading.containsKey(key)) {
        _refreshInBackground<T>(key: key, fetcher: fetcher, ttl: ttl, gen: gen, persist: persist);
      }
      return cached.data as T;
    }

    // --- MISS or forced refresh: check in-flight dedup ---
    final inflight = _loading[key];
    if (inflight != null) {
      return await inflight.future as T;
    }

    // --- Attempt persistent cache before network on cold miss ---
    if (!forceRefresh && cached == null && persist) {
      final persisted = await _loadPersisted<T>(key);
      if (persisted != null) {
        _store(key, persisted, ttl);
        // Refresh in background so it's up-to-date next time
        _refreshInBackground<T>(key: key, fetcher: fetcher, ttl: ttl, gen: gen, persist: persist);
        return persisted;
      }
    }

    return _fetchAndStore<T>(key: key, fetcher: fetcher, ttl: ttl, gen: gen, persist: persist);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<T> _fetchAndStore<T>({
    required String key,
    required Future<T> Function() fetcher,
    required Duration ttl,
    required int gen,
    bool persist = false,
  }) async {
    final completer = Completer<dynamic>();
    _loading[key] = completer;

    try {
      final data = await fetcher();

      // Discard if generation changed (invalidateAll was called)
      if (gen != _generation) return data;

      _store(key, data, ttl);
      if (persist) unawaited(_saveToPrefs(key, data));
      if (!completer.isCompleted) completer.complete(data);
      _notifyUpdate(key);
      return data;
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
      rethrow;
    } finally {
      if (identical(_loading[key], completer)) _loading.remove(key);
    }
  }

  void _refreshInBackground<T>({
    required String key,
    required Future<T> Function() fetcher,
    required Duration ttl,
    required int gen,
    bool persist = false,
  }) {
    unawaited(
      _fetchAndStore<T>(key: key, fetcher: fetcher, ttl: ttl, gen: gen, persist: persist)
          .catchError((Object e, StackTrace s) {
        debugPrint('[Cache] Background refresh failed for $key: $e');
        return Future<T>.error(e, s);
      }),
    );
  }

  void _store<T>(String key, T data, Duration ttl) {
    _memory[key] = _CacheEntry<T>(data: data, fetchedAt: DateTime.now(), ttl: ttl);
    _enforceLimit();
  }

  void _notifyUpdate(String key) {
    if (!_updates.isClosed) _updates.add(key);
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers (SharedPreferences)
  // ---------------------------------------------------------------------------

  Future<T?> _loadPersisted<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('_apicache_$key');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is T) return decoded;
    } catch (_) {}
    return null;
  }

  Future<void> _saveToPrefs(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data);
      // Only persist if payload is reasonable size (< 256 KB)
      if (encoded.length < 262144) {
        await prefs.setString('_apicache_$key', encoded);
      }
    } catch (e) {
      debugPrint('[Cache] Failed to persist $key: $e');
    }
  }

  Future<void> _removePersisted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('_apicache_$key');
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Public helpers — read, invalidate, evict
  // ---------------------------------------------------------------------------

  /// Get cached data without fetching (returns null if absent/expired)
  T? getCached<T>(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    entry.lastAccess = DateTime.now();
    return entry.data as T?;
  }

  /// Get cached data only if it's within [ttl] freshness
  T? getIfValid<T>(String key, Duration ttl) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.fetchedAt) >= ttl) return null;
    entry.lastAccess = DateTime.now();
    return entry.data as T?;
  }

  /// How old is the cached value?
  Duration? getAge(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    return DateTime.now().difference(entry.fetchedAt);
  }

  void invalidate(String key) {
    _memory.remove(key);
    final c = _loading.remove(key);
    if (c != null && !c.isCompleted) {
      c.completeError(StateError('Cache invalidated: $key'));
    }
    unawaited(_removePersisted(key));
  }

  void invalidateAll() {
    _generation++;
    _memory.clear();
    for (final c in _loading.values) {
      if (!c.isCompleted) c.completeError(StateError('All caches invalidated'));
    }
    _loading.clear();
  }

  void invalidatePrefix(String prefix) {
    final keys = _memory.keys.where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) invalidate(k);
  }

  void _evictExpired() {
    final now = DateTime.now();
    _memory.removeWhere((_, e) => now.difference(e.fetchedAt) > e.ttl + CacheTtl.staleGrace);
  }

  void _enforceLimit() {
    if (_memory.length <= maxEntries) return;
    final sorted = _memory.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    final removeCount = _memory.length - maxEntries;
    for (final e in sorted.take(removeCount)) _memory.remove(e.key);
  }

  // kept for compat
  void cleanExpired() => _evictExpired();

  void dispose() {
    invalidateAll();
    if (!_updates.isClosed) _updates.close();
  }
}

// ---------------------------------------------------------------------------
// Convenience sub-caches (kept for backward compatibility)
// ---------------------------------------------------------------------------

class MarketDataCache {
  MarketDataCache._();
  static final MarketDataCache instance = MarketDataCache._();

  Future<T> fetchMarketData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'market_$key',
      fetcher: fetcher,
      ttl: CacheTtl.market,
      forceRefresh: forceRefresh,
      persist: true,
    );
  }
}

class StaticDataCache {
  StaticDataCache._();
  static final StaticDataCache instance = StaticDataCache._();

  Future<T> fetchStaticData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'static_$key',
      fetcher: fetcher,
      ttl: CacheTtl.longLived,
      forceRefresh: forceRefresh,
      persist: true,
    );
  }
}

class UserDataCache {
  UserDataCache._();
  static final UserDataCache instance = UserDataCache._();

  Future<T> fetchUserData<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool forceRefresh = false,
  }) {
    return ApiCacheManager.instance.fetch<T>(
      key: 'user_$key',
      fetcher: fetcher,
      ttl: CacheTtl.userData,
      forceRefresh: forceRefresh,
    );
  }
}
