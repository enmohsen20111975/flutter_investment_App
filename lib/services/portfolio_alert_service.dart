// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Alert Service
// BRIEF-048: مراقبة المحفظة اللحظية + تنبيهات TP/SL/Trailing/Whale
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/client.dart';
import 'notification_service.dart';

class PortfolioAlertService {
  PortfolioAlertService._internal();
  static final PortfolioAlertService _instance = PortfolioAlertService._internal();
  factory PortfolioAlertService() => _instance;

  final GLMApiClient _api = GLMApiClient.instance;
  final NotificationService _notif = NotificationService();

  Timer? _initialDelayTimer;
  Timer? _portfolioTimer;
  Timer? _whaleTimer;
  Timer? _priceAlertTimer;
  bool _isRunning = false;

  // آخر التنبيهات (للـ UI)
  List<Map<String, dynamic>> _portfolioAlerts = [];
  List<Map<String, dynamic>> _whaleAlerts = [];
  List<Map<String, dynamic>> get portfolioAlerts => _portfolioAlerts;
  List<Map<String, dynamic>> get whaleAlerts => _whaleAlerts;

  // Set عشان منكررش التنبيهات
  final Set<String> _firedAlertKeys = {};

  /// ابدأ المراقبة (المحفظة، الحيتان، وتنبيهات الأسعار)
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[PortfolioAlertService] Started - delayed first check by 12s');

    // تأخير الفحص المبدئي 12 ثانية حتى تنتهي الشاشة الرئيسية من الرندر بالكامل
    _initialDelayTimer?.cancel();
    _initialDelayTimer = Timer(const Duration(seconds: 12), () {
      if (!_isRunning) return;
      _checkPortfolio();
      _checkWhales();
      _checkPriceAlerts();
    });

    // مراقبة المحفظة كل 5 دقايق
    _portfolioTimer?.cancel();
    _portfolioTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkPortfolio();
    });

    // مراقبة الحيتان كل 5 دقايق
    _whaleTimer?.cancel();
    _whaleTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _checkWhales();
    });

    // مراقبة تنبيهات الأسعار كل 4 دقايق
    _priceAlertTimer?.cancel();
    _priceAlertTimer = Timer.periodic(const Duration(minutes: 4), (_) {
      _checkPriceAlerts();
    });
  }

  /// اوقف المراقبة
  void stop() {
    _isRunning = false;
    _initialDelayTimer?.cancel();
    _initialDelayTimer = null;
    _portfolioTimer?.cancel();
    _whaleTimer?.cancel();
    _priceAlertTimer?.cancel();
    _portfolioTimer = null;
    _whaleTimer = null;
    _priceAlertTimer = null;
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

  /// فحص تنبيهات الأسعار المحددة من المستخدم
  Future<void> _checkPriceAlerts() async {
    try {
      final alerts = await _api.getAlerts();
      if (alerts.isEmpty) return;

      for (final a in alerts) {
        if (!_isRunning) break;
        if (!a.isActive) continue;
        final ticker = a.symbol;
        if (ticker.isEmpty) continue;

        double currentPrice = 0.0;
        try {
          final res = await _api.dio.get(
            '/api/mobile/stocks/$ticker',
            options: Options(
              sendTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          );
          if (res.data is Map) {
            final val = res.data['price'] ??
                res.data['data']?['price'] ??
                res.data['currentPrice'] ??
                0;
            currentPrice = (val as num).toDouble();
          }
        } catch (_) {
          continue;
        }
        if (currentPrice <= 0) continue;

        final isAbove = a.condition.toUpperCase() == 'ABOVE';
        final triggered = isAbove
            ? currentPrice >= a.targetPrice
            : currentPrice <= a.targetPrice;

        if (triggered) {
          final key =
              'price_alert_${a.id}_${a.targetPrice}_${currentPrice.toStringAsFixed(2)}';
          if (_firedAlertKeys.contains(key)) continue;
          _firedAlertKeys.add(key);

          await _notif.showPortfolioAlert(
            title: '🔔 تنبيه السعر: $ticker',
            body: isAbove
                ? 'وصل سهم $ticker إلى $currentPrice ج.م متجاوزاً الهدف ${a.targetPrice} ج.م'
                : 'هبط سهم $ticker إلى $currentPrice ج.م واصلاً إلى الهدف ${a.targetPrice} ج.م',
            severity: 'critical',
            payload: ticker,
          );
        }
      }
    } catch (e) {
      debugPrint('[PortfolioAlertService] Price alerts check error: $e');
    }
  }

  /// فحص يدوي (للـ pull-to-refresh)
  Future<void> checkNow() async {
    await _checkPortfolio();
    await _checkWhales();
    await _checkPriceAlerts();
  }

  /// كل التنبيهات (محفظة + حيتان)
  List<Map<String, dynamic>> get allAlerts => [..._portfolioAlerts, ..._whaleAlerts];

  /// عدد التنبيهات الحرجة
  int get criticalCount =>
      allAlerts.where((a) => a['severity'] == 'critical').length;
}
