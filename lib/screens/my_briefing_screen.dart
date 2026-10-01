// ============================================================================
// Ù…Ø³Ø§Ø¹Ø¯ Ø§Ù„Ø§Ø³ØªØ«Ù…Ø§Ø± Flutter - My Briefing Screen
// Ø´Ø§Ø´Ø© Â«ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ø£Ø³Ù‡Ù…ÙƒÂ» â€” Ø§Ù„Ù…Ø±Ø¢Ø© Ø§Ù„Ù€ mobile Ù„Ù„Ù€ web widget MyStocksBriefing
//
// ØªØ¹Ø±Ø¶:
//   1. Ù…Ù„Ø®Øµ Ø§Ù„Ù…Ø­ÙØ¸Ø© (Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ø­Ø§Ù„ÙŠØ© + Ø§Ù„Ù…ÙƒØ§Ø³Ø¨/Ø§Ù„Ø®Ø³Ø§Ø¦Ø± + Ø¹Ø¯Ø¯ Ø§Ù„Ø£Ø³Ù‡Ù… + Ø§Ù„ØªÙƒÙ„ÙØ©)
//   2. ØªÙ†Ø¨ÙŠÙ‡Ø§Øª ØªØ­ØªØ§Ø¬ Ù‚Ø±Ø§Ø± (top 5) â€” EXIT_RADAR > STOP_LOSS > TAKE_PROFIT > APPROACHING_TARGET
//   3. Ø¢Ø®Ø± Ø£Ø®Ø¨Ø§Ø± Ø£Ø³Ù‡Ù…Ùƒ (3 news items Ù…ÙÙ„ØªØ±Ø© Ø¨Ø£Ø³Ù‡Ù… Ù…Ø­ÙØ¸Ø© Ø§Ù„Ø¹Ù…ÙŠÙ„)
//
// Ø§Ù„Ù…ØµØ§Ø¯Ø±:
//   - GET /api/portfolio/unified-watch (Ù…Ø­ÙØ¸Ø© + ØªÙˆÙ‚Ø¹Ø§Øª + exit_radar_signal + alerts summary)
//   - GET /api/news?tickers=COMI,EGBE,...&limit=3 (Ø£Ø®Ø¨Ø§Ø± Ù…ÙÙ„ØªØ±Ø©)
//
// Ù…Ù‡Ù…Ø© FOCUS-5-TASKS (2026-10-01): ØªØ±Ø¬Ù…Ø© Ø§Ù„Ù€ 5 Ù…Ù‡Ø§Ù… Ø§Ù„Ù„ÙŠ Ø§ØªØ¹Ù…Ù„Øª ÙÙŠ Ø§Ù„Ù€ web
// Ø¥Ù„Ù‰ Flutter app Ø¹Ø´Ø§Ù† Ø§Ù„Ù…ÙˆØ¨Ø§ÙŠÙ„ ÙŠØ¨Ù‚Ù‰ Ù…ØªØ²Ø§Ù…Ù† Ù…Ø¹ ÙƒÙ„ ØªØ·ÙˆÙŠØ±.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

// â”€â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Provider Ù„Ù„Ù€ unified-watch data (portfolio + predictions + exit_radar + alerts).
final unifiedWatchProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return GLMApiClient.instance.getUnifiedWatch();
});

/// Provider Ù„Ù„Ø£Ø®Ø¨Ø§Ø± Ø§Ù„Ù…ÙÙ„ØªØ±Ø© Ø¨Ø£Ø³Ù‡Ù… Ø§Ù„Ø¹Ù…ÙŠÙ„.
/// Ø¨ÙŠØ§Ø®Ø¯ Ù‚Ø§Ø¦Ù…Ø© Ø§Ù„Ù€ tickers Ù…Ù† Ø§Ù„Ù€ unified-watch ÙˆÙŠÙÙ„ØªØ± Ø¨ÙŠÙ‡Ø§ Ø§Ù„Ø£Ø®Ø¨Ø§Ø±.
final personalizedNewsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  // Ù†Ù‚Ø±Ø£ Ø§Ù„Ù€ unifiedWatch Ø§Ù„Ø£ÙˆÙ„ Ø¹Ø´Ø§Ù† Ù†Ø¹Ø±Ù Ø§Ù„Ù€ tickers
  final watchData = await ref.watch(unifiedWatchProvider.future);
  final stocks = watchData['stocks'];
  final List<String> tickers = [];
  if (stocks is List) {
    for (final s in stocks) {
      if (s is Map && s['ticker'] is String) {
        tickers.add(s['ticker'] as String);
      }
    }
  }
  return GLMApiClient.instance.getPersonalizedNews(tickers: tickers, limit: 3);
});

// â”€â”€â”€ Constants â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AdviceTypeInfo {
  final String labelAr;
  final Color color;
  final Color bg;
  final int priority;
  const _AdviceTypeInfo(this.labelAr, this.color, this.bg, this.priority);
}

final Map<String, _AdviceTypeInfo> _adviceTypeInfo = {
  'EXIT_RADAR': _AdviceTypeInfo(
    'Ø¥Ø´Ø§Ø±Ø© Ø®Ø±ÙˆØ¬', Color(0xFFB91C1C), Color(0xFFFEF2F2), 100),
  'STOP_LOSS': _AdviceTypeInfo(
    'ÙˆÙ‚Ù Ø®Ø³Ø§Ø±Ø©', Color(0xFFB91C1C), Color(0xFFFEF2F2), 90),
  'TAKE_PROFIT': _AdviceTypeInfo(
    'Ø¬Ù†ÙŠ Ø£Ø±Ø¨Ø§Ø­', Color(0xFF047857), Color(0xFFECFDF5), 70),
  'APPROACHING_TARGET': _AdviceTypeInfo(
    'Ø§Ù‚ØªØ±Ø§Ø¨ Ù…Ù† Ø§Ù„Ù‡Ø¯Ù', Color(0xFFB45309), Color(0xFFFEF3C7), 60),
  'HOLD': _AdviceTypeInfo(
    'Ø§Ù†ØªØ¸Ø§Ø±', Colors.grey, Color(0xFFF3F4F6), 0),
};

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class MyBriefingScreen extends ConsumerWidget {
  const MyBriefingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncWatch = ref.watch(unifiedWatchProvider);
    final asyncNews = ref.watch(personalizedNewsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: const Text('ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ø£Ø³Ù‡Ù…Ùƒ'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'ØªØ­Ø¯ÙŠØ«',
              onPressed: () {
                ref.invalidate(unifiedWatchProvider);
                ref.invalidate(personalizedNewsProvider);
              },
            ),
          ],
        ),
        body: asyncWatch.when(
          loading: () => const LoadingWidget(message: 'Ø¨ÙŠØ¬ÙŠØ¨ Ù…Ø­ÙØ¸ØªÙƒ ÙˆØªÙ†Ø¨ÙŠÙ‡Ø§ØªÙƒ...'),
          error: (err, _) => EmptyStateWidget(
            message: 'ØªØ¹Ø°Ù‘Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª',
            icon: Icons.error_outline,
            actionLabel: 'Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©',
            onAction: () => ref.invalidate(unifiedWatchProvider),
          ),
          data: (data) {
            if (data['success'] != true) {
              return EmptyStateWidget(
                message: 'Ø³Ø¬Ù‘Ù„ Ø¯Ø®ÙˆÙ„Ùƒ Ø¹Ø´Ø§Ù† ØªÙ„Ø§Ù‚ÙŠ Ù…Ø­ÙØ¸ØªÙƒ + ØªÙ†Ø¨ÙŠÙ‡Ø§ØªÙƒ Ù‡Ù†Ø§',
                icon: Icons.lock_outline,
                actionLabel: 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„',
                onAction: () => ref.invalidate(unifiedWatchProvider),
              );
            }
            final stocks = data['stocks'] as List? ?? [];
            final summary = (data['summary'] as Map?) ?? <String, dynamic>{};
            final alerts =
                (summary['alerts'] as Map?) ?? <String, dynamic>{};

            if (stocks.isEmpty) {
              return const EmptyStateWidget(
                message: 'Ø£Ø¶Ù Ø£Ø³Ù‡Ù… Ù„Ù…Ø­ÙØ¸ØªÙƒ Ø¹Ø´Ø§Ù† ØªØ¨Ø¯Ø£ Ø§Ù„ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ø§Ù„Ø°ÙƒÙŠØ©',
                icon: Icons.add_circle_outline,
              );
            }

            // Sort stocks by advice priority (exit_radar first, then stop_loss, etc.)
            final sortedStocks = [...stocks]
              ..sort((a, b) {
                final aAdvice = a is Map ? a['advice'] : null;
                final bAdvice = b is Map ? b['advice'] : null;
                final aType =
                    (aAdvice is Map ? aAdvice['type'] : null) ?? 'HOLD';
                final bType =
                    (bAdvice is Map ? bAdvice['type'] : null) ?? 'HOLD';
                final aP = _adviceTypeInfo[aType]?.priority ?? 0;
                final bP = _adviceTypeInfo[bType]?.priority ?? 0;
                return bP.compareTo(aP);
              });

            final actionableStocks = sortedStocks
                .where((s) =>
                    s is Map &&
                    s['advice'] is Map &&
                    s['advice']['type'] != 'HOLD')
                .take(5)
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(unifiedWatchProvider);
                ref.invalidate(personalizedNewsProvider);
                await ref.read(unifiedWatchProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Portfolio summary
                  _PortfolioSummarySection(summary: summary),
                  const SizedBox(height: 16),

                  // 2. Actionable alerts
                  _AlertsSection(
                    alerts: alerts,
                    actionableStocks: actionableStocks,
                  ),
                  const SizedBox(height: 16),

                  // 3. Personalized news
                  _NewsSection(asyncNews: asyncNews),
                  const SizedBox(height: 24),

                  // Footer: exit_radar cache age
                  if (summary['exit_radar_cache_age_seconds'] != null)
                    _CacheFooter(
                      ageSeconds:
                          summary['exit_radar_cache_age_seconds'] as num,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// â”€â”€â”€ Sub-widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PortfolioSummarySection extends StatelessWidget {
  final Map summary;
  const _PortfolioSummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalValue = (summary['total_value'] as num?)?.toDouble() ?? 0;
    final totalCost = (summary['total_cost'] as num?)?.toDouble() ?? 0;
    final totalPnl = (summary['total_pnl'] as num?)?.toDouble() ?? 0;
    final totalPnlPct = (summary['total_pnl_pct'] as num?)?.toDouble() ?? 0;
    final portfolioStocks = (summary['portfolio_stocks'] as num?)?.toInt() ?? 0;
    final isPositive = totalPnl >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wallet, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Ù…Ù„Ø®Øµ Ø§Ù„Ù…Ø­ÙØ¸Ø©', style: AppTypography.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: [
            _miniCard(
              context,
              'Ø§Ù„Ù‚ÙŠÙ…Ø© Ø§Ù„Ø­Ø§Ù„ÙŠØ©',
              '${totalValue.toStringAsFixed(2)} Ø¬.Ù…',
              Icons.account_balance_wallet,
            ),
            _miniCard(
              context,
              'Ø§Ù„Ù…ÙƒØ§Ø³Ø¨/Ø§Ù„Ø®Ø³Ø§Ø¦Ø±',
              '${isPositive ? '+' : ''}${totalPnl.toStringAsFixed(2)} Ø¬.Ù…\n(${totalPnlPct.toStringAsFixed(1)}%)',
              isPositive ? Icons.trending_up : Icons.trending_down,
              valueColor:
                  isPositive ? Color(0xFF047857) : Color(0xFFB91C1C),
            ),
            _miniCard(
              context,
              'Ø¹Ø¯Ø¯ Ø§Ù„Ø£Ø³Ù‡Ù…',
              '$portfolioStocks',
              Icons.pie_chart_outline,
            ),
            _miniCard(
              context,
              'Ù‚ÙŠÙ…Ø© Ø§Ù„ØªÙƒÙ„ÙØ©',
              '${totalCost.toStringAsFixed(2)} Ø¬.Ù…',
              Icons.savings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniCard(BuildContext context, String label, String value,
      IconData icon,
      {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final Map alerts;
  final List actionableStocks;
  const _AlertsSection({required this.alerts, required this.actionableStocks});

  @override
  Widget build(BuildContext context) {
    final total = (alerts['total'] as num?)?.toInt() ?? 0;
    final critical = (alerts['critical'] as num?)?.toInt() ?? 0;
    final warning = (alerts['warning'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  total > 0 ? Icons.notifications_active : Icons.notifications_none,
                  size: 18,
                  color: total > 0 ? Color(0xFFB45309) : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text('ØªÙ†Ø¨ÙŠÙ‡Ø§Øª ØªØ­ØªØ§Ø¬ Ù‚Ø±Ø§Ø±', style: AppTypography.titleSmall),
              ],
            ),
            if (total > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFB45309), width: 0.5),
                ),
                child: Text(
                  '$total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (actionableStocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFF047857), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Color(0xFF047857)),
                const SizedBox(width: 8),
                Text(
                  'ÙƒÙ„ Ø£Ø³Ù‡Ù…Ùƒ ÙÙŠ ÙˆØ¶Ø¹ Ø·Ø¨ÙŠØ¹ÙŠ â€” Ù…ÙÙŠØ´ ØªÙ†Ø¨ÙŠÙ‡Ø§Øª Ù…Ø³ØªØ¹Ø¬Ù„Ø© Ø¯Ù„ÙˆÙ‚ØªÙŠ. âœ…',
                  style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: actionableStocks
                .map((s) => _AlertCard(stock: s as Map))
                .toList(),
          ),
        if (critical > 0 || warning > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                if (critical > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _severityChip('Ø­Ø±Ø¬', critical, Color(0xFFB91C1C)),
                  ),
                if (warning > 0)
                  _severityChip('ØªØ­Ø°ÙŠØ±', warning, Color(0xFFB45309)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _severityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Map stock;
  const _AlertCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final advice = (stock['advice'] as Map?) ?? <String, dynamic>{};
    final type = advice['type'] as String? ?? 'HOLD';
    final info = _adviceTypeInfo[type] ?? _adviceTypeInfo['HOLD']!;
    final reason = advice['reason'] as String? ?? '';
    final action = advice['action'] as String? ?? '';
    final pnlPct = (advice['pnl_pct'] as num?)?.toDouble() ?? 0;
    final currentPrice = (stock['current_price'] as num?)?.toDouble();
    final shares = (stock['shares'] as num?)?.toInt();
    final ticker = stock['ticker'] as String? ?? '';
    final nameAr = stock['name_ar'] as String?;
    final exitSignal = stock['exit_radar_signal'] as Map?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: info.color, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: ticker + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: info.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticker,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: info.color,
                      ),
                    ),
                    if (nameAr != null) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'â€” $nameAr',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: info.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  info.labelAr,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Reason
          Text(
            reason,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 6),
          // Footer: pnl + price + shares
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (pnlPct != 0)
                Text(
                  '${pnlPct > 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pnlPct > 0 ? Color(0xFF047857) : Color(0xFFB91C1C),
                  ),
                ),
              if (currentPrice != null)
                Text(
                  '${currentPrice.toStringAsFixed(2)} Ø¬.Ù…',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              if (shares != null && shares > 0)
                Text(
                  '$shares Ø³Ù‡Ù…',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          // Action (the DECISION â€” Task 5)
          if (action.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: info.color.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                'Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡: $action',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
          // Exit radar path label (if EXIT_RADAR)
          if (exitSignal != null && exitSignal['label_ar'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ø§Ù„Ø¥Ø´Ø§Ø±Ø©: ${exitSignal['label_ar']}',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: info.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewsSection extends ConsumerWidget {
  final AsyncValue<List<dynamic>> asyncNews;
  const _NewsSection({required this.asyncNews});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, size: 18, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Ø¢Ø®Ø± Ø£Ø®Ø¨Ø§Ø± Ø£Ø³Ù‡Ù…Ùƒ', style: AppTypography.titleSmall),
          ],
        ),
        const SizedBox(height: 8),
        asyncNews.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => const Text(
            'ØªØ¹Ø°Ù‘Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø£Ø®Ø¨Ø§Ø±',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          data: (news) {
            if (news.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ù…ÙÙŠØ´ Ø£Ø®Ø¨Ø§Ø± Ù„Ø£Ø³Ù‡Ù…Ùƒ Ø­Ø§Ù„ÙŠÙ‹Ø§ â€” Ø£Ø®Ø¨Ø§Ø± Ø§Ù„Ø³ÙˆÙ‚ ÙƒÙ„Ù‡Ø§ Ø¨ØªØ¸Ù‡Ø± ÙÙŠ ØµÙØ­Ø© Ø§Ù„Ø£Ø®Ø¨Ø§Ø±.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: news
                  .map((n) => _NewsCard(item: n as Map))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map item;
  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String? ?? '';
    final summaryAr = item['summary_ar'] as String?;
    final source = item['source'] as String?;
    final importance = (item['importance'] as num?)?.toInt() ?? 0;
    final publishedAt = item['published_at'] as String? ?? item['fetched_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (importance > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'â˜…$importance',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
            ],
          ),
          if (summaryAr != null && summaryAr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              summaryAr,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          Row(
            children: [
              if (source != null)
                Text(
                  source,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              if (source != null && publishedAt != null)
                Text(
                  ' â€¢ ',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),
              if (publishedAt != null)
                Flexible(
                  child: Text(
                    _relativeTime(publishedAt),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Ø§Ù„Ø¢Ù†';
      if (diff.inMinutes < 60) return 'Ù…Ù†Ø° ${diff.inMinutes} Ø¯Ù‚ÙŠÙ‚Ø©';
      if (diff.inHours < 24) return 'Ù…Ù†Ø° ${diff.inHours} Ø³Ø§Ø¹Ø©';
      if (diff.inDays <= 10) return 'Ù…Ù†Ø° ${diff.inDays} ÙŠÙˆÙ…';
      return 'Ù…Ù†Ø° ÙØªØ±Ø©';
    } catch (_) {
      return '';
    }
  }
}

class _CacheFooter extends StatelessWidget {
  final num ageSeconds;
  const _CacheFooter({required this.ageSeconds});

  @override
  Widget build(BuildContext context) {
    final ageMinutes = (ageSeconds / 60).round();
    final isStale = ageSeconds > 30 * 60;
    return Center(
      child: Text(
        'Ø±Ø§Ø¯Ø§Ø± Ø§Ù„Ø®Ø±ÙˆØ¬ Ø¢Ø®Ø± ØªØ­Ø¯ÙŠØ«: $ageMinutes Ø¯Ù‚ÙŠÙ‚Ø©'
        '${isStale ? ' (Ù‚Ø¯ÙŠÙ… â€” Ø§ØªØ­Ø¯Ù‘Ø« Ù‚Ø±ÙŠØ¨Ù‹Ø§)' : ''}',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade500,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
