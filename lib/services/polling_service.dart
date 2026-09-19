// ============================================================================
// مساعد الاستثمار Flutter - Polling Service
// Smart live polling with adaptive intervals, backoff, and battery awareness
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/mobile_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Polling frequency configuration
class PollingConfig {
  /// Interval when market is open
  final Duration openInterval;

  /// Interval when market is closed
  final Duration closedInterval;

  const PollingConfig({
    this.openInterval  = const Duration(minutes: 7),   // was 5 min
    this.closedInterval = const Duration(minutes: 30),
  });
}

/// Service that manages smart polling for market data.
///
/// Key improvements over previous version:
/// - Market status check is merged INTO dashboard poll (not a separate timer)
/// - Exponential backoff on consecutive failures (up to 30-min cap)
/// - Guard flag prevents overlapping polls
/// - Pauses automatically when app is backgrounded (caller's responsibility)
class PollingService {
  PollingService._();
  static final PollingService _instance = PollingService._();
  static PollingService get instance => _instance;

  final MobileApiService _mobileApi = MobileApiService.instance;

  Timer? _dashboardTimer;
  bool _isMarketOpen = false;
  bool _isPaused = false;
  bool _disposed = false;
  bool _pollRunning = false;

  /// Consecutive failure count (for backoff)
  int _failureCount = 0;
  static const int _maxBackoffMinutes = 30;

  PollingConfig config = const PollingConfig();

  /// Stream controller for dashboard data updates
  final StreamController<Map<String, dynamic>> _dashboardController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream that emits new dashboard data on each successful poll
  Stream<Map<String, dynamic>> get dashboardStream => _dashboardController.stream;

  bool get isMarketOpen => _isMarketOpen;
  bool get isPaused => _isPaused;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Start polling. Fetches immediately then schedules the first timer.
  void startDashboardPolling() {
    if (_disposed) return;
    _failureCount = 0;
    _dashboardTimer?.cancel();
    // Kick off immediately (no artificial delay)
    _runPoll();
  }

  void stopAll() {
    _dashboardTimer?.cancel();
    _dashboardTimer = null;
    _isPaused = true;
  }

  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    _dashboardTimer?.cancel();
    _dashboardTimer = null;
    debugPrint('[Polling] Paused');
  }

  void resume() {
    if (_disposed || !_isPaused) return;
    _isPaused = false;
    debugPrint('[Polling] Resumed');
    _runPoll();
  }

  // ---------------------------------------------------------------------------
  // Core poll logic
  // ---------------------------------------------------------------------------

  /// Execute one poll cycle, then schedule the next timer.
  Future<void> _runPoll() async {
    if (_isPaused || _disposed || _pollRunning) return;
    _pollRunning = true;

    try {
      await _doPoll();
      _failureCount = 0;          // reset backoff on success
    } catch (e) {
      _failureCount++;
      debugPrint('[Polling] Poll failed (attempt #$_failureCount): $e');
    } finally {
      _pollRunning = false;
    }

    if (!_isPaused && !_disposed) {
      _scheduleNext();
    }
  }

  Future<void> _doPoll() async {
    // 1. Fetch market status (included in this same poll, not a separate timer)
    try {
      final status = await _mobileApi.getMarketStatus();
      final statusStr = status['status']?.toString().toLowerCase() ?? '';
      _isMarketOpen = statusStr == 'open' || statusStr == 'مفتوح';
    } catch (_) {
      // Keep last known state — non-fatal
    }

    // 2. Fetch dashboard data
    SharedPreferences? prefs;
    try { prefs = await SharedPreferences.getInstance(); } catch (_) {}
    final market = prefs?.getString('active_market') ?? 'EGX';

    final data = await _mobileApi.getDashboard(market: market, forceRefresh: true);
    if (!_disposed && data.isNotEmpty) {
      _dashboardController.add(data);
    }
  }

  void _scheduleNext() {
    _dashboardTimer?.cancel();

    // Apply exponential backoff on failures (capped)
    Duration interval;
    if (_failureCount > 0) {
      final backoffMinutes = (1 << _failureCount).clamp(1, _maxBackoffMinutes);
      interval = Duration(minutes: backoffMinutes);
      debugPrint('[Polling] Backoff active — next poll in ${interval.inMinutes} min');
    } else {
      interval = _isMarketOpen ? config.openInterval : config.closedInterval;
      debugPrint(
        '[Polling] Market ${_isMarketOpen ? "OPEN" : "CLOSED"}'
        ' — next poll in ${interval.inMinutes} min',
      );
    }

    _dashboardTimer = Timer(interval, _runPoll);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopAll();
    if (!_dashboardController.isClosed) _dashboardController.close();
  }
}

// Top-level getter
PollingService get pollingService => PollingService.instance;
