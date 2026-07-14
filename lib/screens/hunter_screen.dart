// ============================================================================
// مساعد الاستثمار Flutter - Hunter Screen (الصياد)
// Top stock opportunities from /api/hunter/screener
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HunterScreen extends StatefulWidget {
  final int marketVersion;
  
  const HunterScreen({super.key, this.marketVersion = 0});

  @override
  State<HunterScreen> createState() => _HunterScreenState();
}

class _HunterScreenState extends State<HunterScreen> {
  String _selectedMarket = 'ALL';
  final List<String> _markets = ['ALL', 'EGX', 'TADAWUL', 'KSE', 'QSE'];
  Future<List<dynamic>>? _opportunitiesFuture;

  @override
  void initState() {
    super.initState();
    _loadActiveMarket().then((_) {
      _opportunitiesFuture = _fetchOpportunities();
    });
  }

  @override
  void didUpdateWidget(covariant HunterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketVersion != widget.marketVersion) {
      _loadActiveMarket().then((_) {
        _refresh();
      });
    }
  }

  Future<void> _loadActiveMarket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final market = prefs.getString('active_market') ?? 'EGX';
      if (mounted) {
        setState(() {
          _selectedMarket = market;
        });
      }
    } catch (_) {}
  }

  Future<List<dynamic>> _fetchOpportunities() async {
    try {
      return await api.getHunterScreener(
        market: _selectedMarket != 'ALL' ? _selectedMarket : null,
        limit: 20,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _opportunitiesFuture = _fetchOpportunities();
    });
  }

  Color _scoreColor(double score) {
    if (score >= 90) return const Color(0xFFFFD700);
    if (score >= 80) return AppColors.success;
    if (score >= 70) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.textMuted;
  }

  Color _signalColor(String? signal) {
    switch (signal?.toUpperCase().replaceAll(' ', '_')) {
      case 'BUY':
      case 'STRONG_BUY':
        return AppColors.success;
      case 'SELL':
      case 'STRONG_SELL':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _signalAr(String? signal) {
    if (signal == null || signal.isEmpty) return 'انتظار';
    final a = signal.toUpperCase().replaceAll(' ', '_');
    switch (a) {
      case 'STRONG_BUY':
        return 'شراء قوي';
      case 'BUY':
        return 'شراء';
      case 'STRONG_SELL':
        return 'بيع قوي';
      case 'SELL':
        return 'بيع';
      case 'HOLD':
        return 'احتفاظ';
      case 'AVOID':
        return 'تجنب';
      case 'ACCUMULATE':
        return 'تجميع';
      case 'REDUCE':
        return 'تخفيف';
      default:
        return signal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('الصياد - الفرص الاستثمارية',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMarket,
                  isDense: true,
                  dropdownColor: AppColors.surface,
                  items: _markets
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.text)),
                          ))
                      .toList(),
                  onChanged: (val) async {
                    if (val != null) {
                      setState(() => _selectedMarket = val);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('active_market', val);
                      } catch (_) {}
                      _refresh();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _opportunitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5, itemHeight: 180);
            }
            if (snapshot.hasError) {
              return StateView(error: 'فشل تحميل الفرص', onRetry: _refresh);
            }
            final opportunities = snapshot.data ?? [];
            if (opportunities.isEmpty) {
              return const StateView(
                  empty: true,
                  emptyMessage: 'لا توجد فرص استثمارية متاحة حالياً');
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: opportunities.length,
                itemBuilder: (context, index) {
                  final opp = opportunities[index] is Map
                      ? Map<String, dynamic>.from(opportunities[index])
                      : <String, dynamic>{};
                  return _buildOpportunityCard(opp, index);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, dynamic> opp, int index) {
    final rank = index + 1;
    final ticker = opp['ticker']?.toString() ?? opp['symbol']?.toString() ?? '';
    final name = opp['name']?.toString() ?? opp['company']?.toString() ?? '';
    final score = (opp['score'] as num?)?.toDouble() ?? 0;
    final signal = opp['signal']?.toString() ??
        opp['recommendation']?.toString() ??
        'HOLD';
    final entryPrice = (opp['entry_price'] as num?)?.toDouble() ??
        (opp['current_price'] as num?)?.toDouble();
    final targetPrice = (opp['target_price'] as num?)?.toDouble();
    final stopLoss = (opp['stop_loss'] as num?)?.toDouble();
    final riskReward = (opp['risk_reward'] as num?)?.toDouble();
    final reasoningRaw = opp['reasoning'] ??
        opp['summary'] ??
        opp['match_reasons'] ??
        opp['signals'];
    final reasoning = reasoningRaw is List
        ? reasoningRaw.map((e) => e.toString()).join(' • ')
        : reasoningRaw?.toString() ?? '';
    final nameAr = opp['name_ar']?.toString() ?? opp['nameAr']?.toString() ?? '';
    final displayName =
        nameAr.isNotEmpty ? nameAr : (name.isNotEmpty ? name : ticker);
    final scoreColor = _scoreColor(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: score >= 80
              ? scoreColor.withValues(alpha: 0.4)
              : AppColors.border,
          width: score >= 90 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Score circle
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  backgroundColor: AppColors.surfaceMuted,
                  color: scoreColor,
                ),
                Text('${score.toInt()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: scoreColor)),
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('#$rank',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ticker.isNotEmpty ? ticker : '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                if (displayName.isNotEmpty && displayName != ticker) ...[
                  const SizedBox(height: 2),
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            )),
            // Signal badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _signalColor(signal).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_signalAr(signal),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _signalColor(signal))),
            ),
          ]),
          const Divider(height: 20),
          // Prices row
          Row(children: [
            if (entryPrice != null)
              Expanded(
                  child:
                      _buildPriceCol('الدخول', entryPrice.toStringAsFixed(2))),
            if (targetPrice != null)
              Expanded(
                  child:
                      _buildPriceCol('الهدف', targetPrice.toStringAsFixed(2))),
            if (stopLoss != null)
              Expanded(
                  child: _buildPriceCol(
                      'وقف الخسارة', stopLoss.toStringAsFixed(2))),
          ]),
          if (riskReward != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Text('Risk/Reward:',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 4),
              Text('1:${riskReward.toStringAsFixed(1)}',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: riskReward >= 2
                          ? AppColors.success
                          : AppColors.warning)),
            ]),
          ],
          if (reasoning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(reasoning,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceCol(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}
