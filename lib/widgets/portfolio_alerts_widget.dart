// ============================================================================
// مساعد الاستثمار Flutter - Portfolio Alerts Widget
// BRIEF-048: عرض تنبيهات المحفظة (TP/SL/Trailing) + الحيتان + Win Rate
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../api/client.dart';
import '../services/portfolio_alert_service.dart';

class PortfolioAlertsWidget extends StatefulWidget {
  const PortfolioAlertsWidget({super.key});

  @override
  State<PortfolioAlertsWidget> createState() => _PortfolioAlertsWidgetState();
}

class _PortfolioAlertsWidgetState extends State<PortfolioAlertsWidget>
    with WidgetsBindingObserver {
  final GLMApiClient _api = GLMApiClient.instance;
  final PortfolioAlertService _alertService = PortfolioAlertService();

  List<Map<String, dynamic>> _portfolioAlerts = [];
  List<Map<String, dynamic>> _whaleAlerts = [];
  Map<String, dynamic> _ledger = {};
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    // تحديث كل 5 دقايق
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadData());
    // ابدأ المراقبة في الخلفية
    _alertService.start();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); // تحديث لما المستخدم يرجع للتطبيق
    }
  }

  Future<void> _loadData() async {
    try {
      // اجيب تنبيهات المحفظة
      final alerts = await _api.checkPortfolioAlerts();
      // اجيب تنبيهات الحيتان
      final whales = await _api.getWhaleAlerts();
      // اجيب سجل التوقعات + Win Rate
      final ledger = await _api.getLiveMonitorLedger();

      if (mounted) {
        setState(() {
          _portfolioAlerts = alerts;
          _whaleAlerts = whales;
          _ledger = ledger;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[PortfolioAlertsWidget] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('جاري فحص المحفظة...'),
        ),
      );
    }

    final winRate = (_ledger['win_rate'] ?? 0).toDouble();
    final totalSignals = _ledger['total_signals'] ?? 0;
    final wins = _ledger['wins'] ?? 0;
    final losses = _ledger['losses'] ?? 0;
    final criticalCount = _portfolioAlerts.where((a) => a['severity'] == 'critical').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ===== Win Rate Card =====
          _buildWinRateCard(winRate, totalSignals, wins, losses),

          const SizedBox(height: 8),

          // ===== Portfolio Alerts =====
          if (_portfolioAlerts.isNotEmpty) ...[
            _buildSectionHeader(
              '🛡️ تنبيهات المحفظة',
              '${_portfolioAlerts.length} تنبيه',
              criticalCount > 0 ? Colors.red : Colors.green,
            ),
            ..._portfolioAlerts.map((a) => _buildAlertCard(a)),
            const SizedBox(height: 8),
          ],

          // ===== Whale Alerts =====
          if (_whaleAlerts.isNotEmpty) ...[
            _buildSectionHeader(
              '🐋 تنبيهات الحيتان',
              '${_whaleAlerts.length} إشارة',
              Colors.purple,
            ),
            ..._whaleAlerts.map((a) => _buildAlertCard(a)),
            const SizedBox(height: 8),
          ],

          // ===== Empty State =====
          if (_portfolioAlerts.isEmpty && _whaleAlerts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
                    const SizedBox(height: 8),
                    const Text(
                      'لا توجد تنبيهات حالياً',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'المحفظة تحت المراقبة كل 5 دقايق',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWinRateCard(double winRate, int total, int wins, int losses) {
    final color = winRate >= 70
        ? Colors.green
        : winRate >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('📊 أداء المنصة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${winRate.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: winRate / 100,
                backgroundColor: Colors.grey.shade200,
                color: color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('إجمالي', total.toString(), Colors.blue),
                _buildStat('نجاح', wins.toString(), Colors.green),
                _buildStat('فشل', losses.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'info';
    final type = alert['type'] ?? '';
    final ticker = alert['ticker'] ?? '';
    final message = alert['message'] ?? '';

    Color cardColor;
    IconData icon;
    switch (severity) {
      case 'critical':
        cardColor = Colors.red.shade50;
        icon = Icons.warning;
        break;
      case 'warning':
        cardColor = Colors.orange.shade50;
        icon = Icons.trending_up;
        break;
      default:
        cardColor = type == 'LIVE_WHALE_BUY'
            ? Colors.purple.shade50
            : Colors.green.shade50;
        icon = type == 'LIVE_WHALE_BUY' ? Icons.water_drop : Icons.flag;
    }

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severity == 'critical' ? Colors.red : (type == 'LIVE_WHALE_BUY' ? Colors.purple : Colors.green),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          '$ticker · ${_getTypeLabel(type)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(message, style: const TextStyle(fontSize: 12)),
        trailing: severity == 'critical'
            ? const Icon(Icons.priority_high, color: Colors.red)
            : null,
        onTap: () {
          // TODO: Navigate to chart for this ticker
        },
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'TARGET_HIT':
        return 'تحقيق هدف';
      case 'OB_BREACH':
        return 'كسر وقف خسارة';
      case 'TRAILING_STOP':
        return 'Trailing Stop';
      case 'LIVE_WHALE_BUY':
        return 'حوت نشط';
      default:
        return type;
    }
  }
}
