// ============================================================================
// مساعد الاستثمار Flutter - Request Throttle Service
// Smart request queue with deduplication and circuit breaker
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Circuit breaker states
enum _CircuitState { closed, open, halfOpen }

/// A pending request entry in the queue
class _RequestEntry<T> {
  final String key;
  final Future<T> Function() fetcher;
  final Completer<T> completer;

  _RequestEntry({
    required this.key,
    required this.fetcher,
    required this.completer,
  });
}

/// Smart request throttle service with:
/// - Max concurrent requests (prevents server overload)
/// - Request deduplication (same key = same future)
/// - Circuit breaker (stops hammering a failing server)
class RequestThrottleService {
  RequestThrottleService._();
  static final RequestThrottleService instance = RequestThrottleService._();

  /// Maximum number of simultaneous in-flight requests
  static const int _maxConcurrent = 3;

  /// Circuit breaker: open after N consecutive failures
  static const int _failureThreshold = 3;

  /// Circuit breaker: stay open for this duration before trying again
  static const Duration _openDuration = Duration(seconds: 60);

  /// Circuit breaker: half-open test after open period
  static const Duration _halfOpenTimeout = Duration(seconds: 10);

  int _activeCount = 0;
  final List<_RequestEntry<dynamic>> _queue = [];

  /// In-flight futures keyed by request key (deduplication map)
  final Map<String, Future<dynamic>> _inFlight = {};

  // Circuit breaker state
  _CircuitState _circuitState = _CircuitState.closed;
  int _failureCount = 0;
  DateTime? _openedAt;

  /// Execute a request with throttling and deduplication.
  ///
  /// If a request with [key] is already in-flight, returns the same future.
  /// If the queue is full, the request waits until a slot is free.
  /// If the circuit breaker is open, throws immediately.
  Future<T> execute<T>({
    required String key,
    required Future<T> Function() fetcher,
    bool bypassCircuitBreaker = false,
  }) {
    // Check circuit breaker
    if (!bypassCircuitBreaker && _isCircuitOpen()) {
      return Future.error(
        StateError('[Throttle] Circuit breaker OPEN — skipping request: $key'),
      );
    }

    // Deduplication: return existing in-flight future if key matches
    final existing = _inFlight[key];
    if (existing != null) {
      debugPrint('[Throttle] Deduplicating request: $key');
      return existing as Future<T>;
    }

    final completer = Completer<T>();
    final entry = _RequestEntry<T>(
      key: key,
      fetcher: fetcher,
      completer: completer,
    );

    // Register in dedup map immediately
    _inFlight[key] = completer.future;

    if (_activeCount < _maxConcurrent) {
      _dispatch(entry);
    } else {
      debugPrint('[Throttle] Queue full ($key) — queuing (${_queue.length + 1} waiting)');
      _queue.add(entry);
    }

    return completer.future;
  }

  void _dispatch<T>(_RequestEntry<T> entry) {
    _activeCount++;
    _runEntry(entry).whenComplete(() {
      _activeCount--;
      _processQueue();
    });
  }

  Future<void> _runEntry<T>(_RequestEntry<T> entry) async {
    try {
      // Half-open: only allow one test request
      if (_circuitState == _CircuitState.halfOpen) {
        debugPrint('[Throttle] Half-open test for ${entry.key}');
      }

      final result = await entry.fetcher().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timeout: ${entry.key}'),
      );

      // Success → reset circuit breaker
      _onSuccess();
      if (!entry.completer.isCompleted) {
        entry.completer.complete(result);
      }
    } catch (e) {
      _onFailure(e);
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(e);
      }
    } finally {
      _inFlight.remove(entry.key);
    }
  }

  void _processQueue() {
    while (_queue.isNotEmpty && _activeCount < _maxConcurrent) {
      final next = _queue.removeAt(0);
      _dispatch(next);
    }
  }

  bool _isCircuitOpen() {
    if (_circuitState == _CircuitState.closed) return false;

    if (_circuitState == _CircuitState.open) {
      final elapsed = DateTime.now().difference(_openedAt!);
      if (elapsed >= _openDuration) {
        debugPrint('[Throttle] Circuit breaker → HALF-OPEN (testing)');
        _circuitState = _CircuitState.halfOpen;
        return false; // Allow one test request
      }
      return true; // Still open
    }

    // Half-open: allow request to go through
    return false;
  }

  void _onSuccess() {
    if (_circuitState != _CircuitState.closed) {
      debugPrint('[Throttle] Circuit breaker → CLOSED (recovered)');
    }
    _circuitState = _CircuitState.closed;
    _failureCount = 0;
    _openedAt = null;
  }

  void _onFailure(dynamic error) {
    // Don't count 4xx as circuit breaker failures (client errors)
    final is4xx = error.toString().contains('40');
    if (is4xx) return;

    _failureCount++;
    debugPrint('[Throttle] Failure #$_failureCount');

    if (_failureCount >= _failureThreshold && _circuitState == _CircuitState.closed) {
      debugPrint('[Throttle] Circuit breaker → OPEN (too many failures)');
      _circuitState = _CircuitState.open;
      _openedAt = DateTime.now();
    }
  }

  /// Cancel all queued requests (e.g., on logout or navigation away)
  void cancelAll({String? keyPrefix}) {
    final toRemove = keyPrefix != null
        ? _queue.where((e) => e.key.startsWith(keyPrefix)).toList()
        : List.from(_queue);
    for (final entry in toRemove) {
      _queue.remove(entry);
      _inFlight.remove(entry.key);
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(
          StateError('Request cancelled: ${entry.key}'),
        );
      }
    }
  }

  /// Reset circuit breaker manually (e.g., after user explicitly retries)
  void resetCircuitBreaker() {
    _circuitState = _CircuitState.closed;
    _failureCount = 0;
    _openedAt = null;
    debugPrint('[Throttle] Circuit breaker manually reset');
  }

  /// Current stats for debugging
  Map<String, dynamic> get stats => {
    'activeCount': _activeCount,
    'queueLength': _queue.length,
    'inFlightCount': _inFlight.length,
    'circuitState': _circuitState.name,
    'failureCount': _failureCount,
  };
}

// Top-level getter
RequestThrottleService get throttle => RequestThrottleService.instance;
