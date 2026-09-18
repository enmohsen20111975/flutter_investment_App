// ============================================================================
// مساعد الاستثمار Flutter - Polling Service
// Smart live polling for market data with battery optimization
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/mobile_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Polling frequency configuration
class PollingConfig {
  /// Interval when market is open (default: 5 minutes)
  final Duration openInterval;

  /// Interval when market is closed (default: 30 minutes)
  final Duration closedInterval;

  const PollingConfig({
    this.openInterval = const Duration(minutes: 5),
    this.closedInterval = const Duration(minutes: 30),
  });
}

/// Service that manages smart polling for market data
class PollingService {
  PollingService._privateConstructor();
  static final PollingService _instance = PollingService._privateConstructor();
  static PollingService get instance => _instance;

  final MobileApiService _mobileApi = MobileApiService.instance;

  Timer? _dashboardTimer;
  Timer? _marketStatusTimer;
  bool _isMarketOpen = false;
  bool _isPaused = false;
  bool _disposed = false;

  /// Stream controller for dashboard data updates
  final StreamController<Map<String, dynamic>> _dashboardController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream that emits new dashboard data on each poll
  Stream<Map<String, dynamic>> get dashboardStream =>
      _dashboardController.stream;

  /// Whether the market is currently open (latest known state)
  bool get isMarketOpen => _isMarketOpen;

  /// Whether polling is currently paused
  bool get isPaused => _isPaused;

  PollingConfig config = const PollingConfig();

  /// Start polling dashboard data
  void startDashboardPolling() {
    if (_disposed) return;
    _dashboardTimer?.cancel();
    _fetchAndAdaptInterval();
  }

  /// Stop all polling
  void stopAll() {
    _dashboardTimer?.cancel();
    _dashboardTimer = null;
    _marketStatusTimer?.cancel();
    _marketStatusTimer = null;
    _isPaused = true;
  }

  /// Resume polling
  void resume() {
    if (_disposed) return;
    _isPaused = false;
    _fetchAndAdaptInterval();
  }

  /// Pause polling (e.g., when app goes to background)
  void pause() {
    _isPaused = true;
    _dashboardTimer?.cancel();
    _dashboardTimer = null;
    _marketStatusTimer?.cancel();
    _marketStatusTimer = null;
  }

  /// Fetch market status and adapt polling interval
  Future<void> _fetchAndAdaptInterval() async {
    if (_isPaused || _disposed) return;

    try {
      final status = await _mobileApi.getMarketStatus();
      final statusStr = status['status']?.toString().toLowerCase() ?? '';
      _isMarketOpen = statusStr == 'open' || statusStr == 'مفتوح';
    } catch (_) {
      // Keep last known state
    }

    if (_isPaused || _disposed) return;

    final interval =
        _isMarketOpen ? config.openInterval : config.closedInterval;
    debugPrint(
        '[Polling] Market ${_isMarketOpen ? "OPEN" : "CLOSED"} - Polling every ${interval.inMinutes}min');

    _dashboardTimer?.cancel();
    _dashboardTimer = Timer.periodic(interval, (_) async {
      if (_isPaused || _disposed) return;
      await _pollDashboard();
    });

    // Also poll market status less frequently to detect open/close changes
    _marketStatusTimer?.cancel();
    _marketStatusTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) async {
        if (_isPaused || _disposed) return;
        await _fetchAndAdaptInterval();
      },
    );
  }

  /// Poll dashboard endpoint and emit to stream
  Future<void> _pollDashboard() async {
    if (_disposed) return;
    try {
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}
      final market = prefs?.getString('active_market') ?? 'EGX';
      final data = await _mobileApi.getDashboard(market: market, forceRefresh: true);
      if (!_disposed && data.isNotEmpty) {
        _dashboardController.add(data);
      }
    } catch (e) {
      debugPrint('[Polling] Dashboard poll failed: $e');
    }
  }

  /// Cleanup resources
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopAll();
    if (!_dashboardController.isClosed) {
      _dashboardController.close();
    }
  }
}

// Top-level getter
PollingService get pollingService => PollingService.instance;
