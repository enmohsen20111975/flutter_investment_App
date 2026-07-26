// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Alert Service
// BRIEF-048: مراقبة المحفظة اللحظية + تنبيهات TP/SL/Trailing/Whale
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';
import 'notification_service.dart';

class PortfolioAlertService {
  PortfolioAlertService._internal();
  static final PortfolioAlertService _instance = PortfolioAlertService._internal();
  factory PortfolioAlertService() => _instance;

  final GLMApiClient _api = GLMApiClient.instance;
  final NotificationService _notif = NotificationService();

  Timer? _portfolioTimer;
  Timer? _whaleTimer;
  bool _isRunning = false;

  // آخر التنبيهات (للـ UI)
  List<Map<String, dynamic>> _portfolioAlerts = [];
  List<Map<String, dynamic>> _whaleAlerts = [];
  List<Map<String, dynamic>> get portfolioAlerts => _portfolioAlerts;
  List<Map<String, dynamic>> get whaleAlerts => _whaleAlerts;

  // Set عشان منكررش التنبيهات
  final Set<String> _firedAlertKeys = {};

  /// ابدأ المراقبة (كل 5 دقايق)
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[PortfolioAlertService] Started - polling every 5 minutes');

    // فحص فوري
    _checkPortfolio();
    _checkWhales();

    // مراقبة المحفظة كل 5 دقايق
    _portfolioTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkPortfolio();
    });

    // مراقبة الحيتان كل 5 دقايق
    _whaleTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkWhales();
    });
  }

  /// اوقف المراقبة
  void stop() {
    _isRunning = false;
    _portfolioTimer?.cancel();
    _whaleTimer?.cancel();
    _portfolioTimer = null;
    _whaleTimer = null;
    debugPrint('[PortfolioAlertService] Stopped');
  }

  bool get isRunning => _isRunning;

  /// فحص المحفظة - TP/SL/Trailing
  Future<void> _checkPortfolio() async {
    try {
      final alerts = await _api.checkPortfolioAlerts();
      _portfolioAlerts = alerts;

      // أظهر تنبيهات محلية للأحداث الجديدة
      for (final alert in alerts) {
        final key = '${alert['type']}_${alert['ticker']}_${alert['price']}';
        if (_firedAlertKeys.contains(key)) continue;
        _firedAlertKeys.add(key);

        // نظّف الـ keys القديمة (أكتر من 100)
        if (_firedAlertKeys.length > 100) {
          _firedAlertKeys.clear();
          _firedAlertKeys.add(key);
        }

        final severity = alert['severity'] ?? 'info';
        final message = alert['message'] ?? '';

        await _notif.showPortfolioAlert(
          title: severity == 'critical' ? '🚨 تنبيه طارئ' : '🎯 تنبيه محفظة',
          body: message,
          severity: severity,
          payload: alert['ticker'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[PortfolioAlertService] Portfolio check error: $e');
    }
  }

  /// فحص الحيتان - LIVE_WHALE_BUY
  Future<void> _checkWhales() async {
    try {
      final alerts = await _api.getWhaleAlerts();
      _whaleAlerts = alerts;

      for (final alert in alerts) {
        final key = 'whale_${alert['ticker']}_${alert['timestamp']}';
        if (_firedAlertKeys.contains(key)) continue;
        _firedAlertKeys.add(key);

        await _notif.showPortfolioAlert(
          title: '🐋 حوت نشط!',
          body: alert['message'] ?? 'حوت نشط في السوق',
          severity: 'info',
          payload: alert['ticker'] as String?,
        );
      }
    } catch (e) {
      debugPrint('[PortfolioAlertService] Whale check error: $e');
    }
  }

  /// فحص يدوي (للـ pull-to-refresh)
  Future<void> checkNow() async {
    await _checkPortfolio();
    await _checkWhales();
  }

  /// كل التنبيهات (محفظة + حيتان)
  List<Map<String, dynamic>> get allAlerts => [..._portfolioAlerts, ..._whaleAlerts];

  /// عدد التنبيهات الحرجة
  int get criticalCount =>
      allAlerts.where((a) => a['severity'] == 'critical').length;
}
