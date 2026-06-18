// ============================================================================
// مساعد الاستثمار Flutter - Market Provider
// State management for market data with ChangeNotifier
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/client.dart';
import '../api/mobile_api.dart';
import '../services/polling_service.dart';
import '../models/types.dart';

class MarketProvider extends ChangeNotifier {
  Map<String, dynamic>? _dashboardData;
  MarketOverview? _marketOverview;
  bool _isMarketOpen = false;
  bool _isLoading = false;
  String? _error;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _dashboardSubscription;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  MarketOverview? get marketOverview => _marketOverview;
  bool get isMarketOpen => _isMarketOpen;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await mobileApi.getDashboard();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MarketProvider] fetchDashboard failed: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMarketOverview([String? market]) async {
    try {
      _marketOverview = await api.getMarketOverview(market);
      notifyListeners();
    } catch (e) {
      debugPrint('[MarketProvider] fetchMarketOverview failed: $e');
    }
  }

  void startPolling() {
    _dashboardSubscription?.cancel();
    _dashboardSubscription = pollingService.dashboardStream.listen((data) {
      _dashboardData = data;
      notifyListeners();
    });
    pollingService.startDashboardPolling();
  }

  void stopPolling() {
    _dashboardSubscription?.cancel();
    pollingService.stopAll();
  }

  void refreshMarketStatus(bool isOpen) {
    _isMarketOpen = isOpen;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
