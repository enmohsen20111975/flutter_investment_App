// ============================================================================
// مساعد الاستثمار Flutter - Multi-Market Radar Screen
// شاشة الرادار الموحّد — كل الأسواق في لوحة واحدة
//
// تعرض:
//   - بطاقات ملخّص لكل سوق (علم + اسم + عدد الأسهم + حالة السوق)
//   - أعلى 5 فرص موحّدة عبر كل الأسواق
//
// الأسواق المدعومة: EGX, US, CRYPTO, GOLD, TADAWUL, KSE, QSE
//
// المصدر: GET /api/maker-radar/multi-market?markets=EGX,US,CRYPTO,GOLD,TADAWUL,KSE,QSE
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

const _allMarkets = 'EGX,US,CRYPTO,GOLD,TADAWUL,KSE,QSE';

// ─── Provider: Multi-Market Radar Data ──────────────────────────────────
final multiMarketRadarProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return GLMApiClient.instance.getMultiMarketRadar(markets: _allMarkets);
});

class MultiMarketRadarScreen extends ConsumerWidget {
  const MultiMarketRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(multiMarketRadarProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: const Text('الرادار الموحّد'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => ref.refresh(multiMarketRadarProvider),
            ),
          ],
        ),
        body: asyncData.when(
          loading: () => const LoadingWidget(message: 'جارٍ فحص كل الأسواق...'),
          error: (e, st) => _ErrorView(
            message: 'فشل تحميل الرادار الموحّد: $e',
            onRetry: () => ref.refresh(multiMarketRadarProvider),
          ),
          data: (data) {
            if (data.isEmpty ||
                data['success'] == false ||
                (data['markets'] == null &&
                    data['summary'] == null &&
                    data['top_picks'] == null)) {
              final errMsg = data['error']?.toString() ?? 'لا توجد بيانات متاحة';
              return EmptyStateWidget(
                icon: Icons.public_off,
                message: 'تعذّر الحصول على بيانات الأسواق: $errMsg',
              );
            }
            return _MultiMarketBody(data: data);
          },
        ),
      ),
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────
class _MultiMarketBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MultiMarketBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final marketsMap = _extractMarkets(data);
    final topPicks = _extractTopPicks(data);
    final updatedAt = data['updated_at']?.toString() ??
        data['timestamp']?.toString() ??
        '—';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Top header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.gradientInfo,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.public, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${marketsMap.length} أسواق · ${topPicks.length} فرص موحّدة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'آخر تحديث: $updatedAt',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Markets grid
        if (marketsMap.isNotEmpty) ...[
          const _SectionTitle(icon: Icons.flag_outlined, text: 'ملخّص الأسواق'),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: marketsMap.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, i) {
              return _MarketCard(market: marketsMap[i]);
            },
          ),
          const SizedBox(height: 20),
        ],
        // Top picks
        if (topPicks.isNotEmpty) ...[
          const _SectionTitle(icon: Icons.emoji_events, text: 'أعلى 5 فرص موحّدة'),
          const SizedBox(height: 8),
          ...topPicks.asMap().entries.map((e) {
            return _TopPickCard(pick: e.value, rank: e.key + 1);
          }),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  List<Map<String, dynamic>> _extractMarkets(Map<String, dynamic> data) {
    dynamic raw;
    if (data['markets'] is List) {
      raw = data['markets'];
    } else if (data['markets'] is Map) {
      raw = (data['markets'] as Map).values.toList();
    } else if (data['summary'] is List) {
      raw = data['summary'];
    } else if (data['summary'] is Map) {
      raw = (data['summary'] as Map).values.toList();
    }
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic>
            ? e
            : (e is Map ? e.cast<String, dynamic>() : <String, dynamic>{}))
        .where((m) => m.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _extractTopPicks(Map<String, dynamic> data) {
    dynamic raw = data['top_picks'] ?? data['unified_top'] ?? data['top_unified'];
    if (raw is! List) return [];
    return raw
        .map((e) => e is Map<String, dynamic>
            ? e
            : (e is Map ? e.cast<String, dynamic>() : <String, dynamic>{}))
        .where((m) => m.isNotEmpty)
        .take(5)
        .toList();
  }
}

// ─── Section Title ─────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionTitle({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.quantumEmerald),
        const SizedBox(width: 8),
        Text(text, style: AppTypography.titleMedium),
      ],
    );
  }
}

// ─── Market Card ────────────────────────────────────────────────────────
class _MarketCard extends StatelessWidget {
  final Map<String, dynamic> market;
  const _MarketCard({required this.market});

  @override
  Widget build(BuildContext context) {
    final code = market['market']?.toString() ??
        market['code']?.toString() ??
        market['name']?.toString() ??
        '?';
    final stockCount = _toInt(market['stock_count'] ?? market['stocks'] ?? market['count']);
    final regime = (market['regime'] ?? market['market_regime'] ?? 'UNKNOWN').toString().toUpperCase();
    final (flag, nameAr) = _marketMeta(code);
    final (regimeColor, regimeLabelAr) = _regimeStyle(regime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.quantumGlassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top: flag + code + regime
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (nameAr.isNotEmpty)
                      Text(
                        nameAr,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stock count
          Row(
            children: [
              Icon(Icons.bar_chart, size: 14, color: AppColors.info),
              const SizedBox(width: 4),
              Text(
                '$stockCount سهم',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Regime badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: regimeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: regimeColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              regimeLabelAr,
              style: TextStyle(
                color: regimeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _marketMeta(String code) {
    switch (code.toUpperCase()) {
      case 'EGX':
        return ('🇪🇬', 'البورصة المصرية');
      case 'US':
      case 'NYSE':
      case 'NASDAQ':
        return ('🇺🇸', 'البورصة الأمريكية');
      case 'CRYPTO':
        return ('₿', 'العملات الرقمية');
      case 'GOLD':
        return ('🥇', 'الذهب');
      case 'TADAWUL':
        return ('🇸🇦', 'السوق السعودي');
      case 'KSE':
        return ('🇰🇼', 'بورصة الكويت');
      case 'QSE':
        return ('🇶🇦', 'بورصة قطر');
      case 'ADX':
        return ('🇦🇪', 'بورصة أبوظبي');
      case 'DFM':
        return ('🇦🇪', 'بورصة دبي');
      case 'BSE':
        return ('🇧🇭', 'بورصة البحرين');
      case 'MSM':
        return ('🇴🇲', 'بورصة مسقط');
      default:
        return ('🌐', code);
    }
  }

  (Color, String) _regimeStyle(String r) {
    switch (r) {
      case 'DEFENSIVE':
        return (AppColors.danger, 'دفاعي');
      case 'NORMAL':
        return (AppColors.warning, 'طبيعي');
      case 'AGGRESSIVE':
        return (AppColors.success, 'هجومي');
      case 'BULLISH':
        return (AppColors.success, 'صاعد');
      case 'BEARISH':
        return (AppColors.danger, 'هابط');
      case 'NEUTRAL':
        return (AppColors.warning, 'محايد');
      default:
        return (AppColors.textMuted, 'غير معروف');
    }
  }
}

// ─── Top Pick Card ───────────────────────────────────────────────────────
class _TopPickCard extends StatelessWidget {
  final Map<String, dynamic> pick;
  final int rank;
  const _TopPickCard({required this.pick, required this.rank});

  @override
  Widget build(BuildContext context) {
    final ticker = pick['ticker']?.toString() ??
        pick['symbol']?.toString() ??
        '?';
    final market = pick['market']?.toString() ?? '?';
    final name = pick['name']?.toString() ?? pick['name_ar']?.toString();
    final score = _toDouble(pick['score'] ?? pick['strength'] ?? pick['signal_score']);
    final price = _formatNum(pick['price'] ?? pick['last_price']);
    final signalType = pick['signal_type']?.toString() ?? pick['signal']?.toString();
    final (flag, _) = _marketMeta(market);

    final (rankColor, rankEmoji) = _rankStyle(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            rankColor.withValues(alpha: 0.18),
            AppColors.quantumGlass,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rankEmoji.isNotEmpty ? rankEmoji : '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ticker + market
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      ticker,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        market,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (name != null && name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (signalType != null && signalType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    signalType,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.quantumEmerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Score + price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                price,
                style: AppTypography.titleSmall.copyWith(color: AppColors.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, String) _marketMeta(String code) {
    switch (code.toUpperCase()) {
      case 'EGX':
        return ('🇪🇬', '');
      case 'US':
        return ('🇺🇸', '');
      case 'CRYPTO':
        return ('₿', '');
      case 'GOLD':
        return ('🥇', '');
      case 'TADAWUL':
        return ('🇸🇦', '');
      case 'KSE':
        return ('🇰🇼', '');
      case 'QSE':
        return ('🇶🇦', '');
      default:
        return ('🌐', '');
    }
  }

  (Color, String) _rankStyle(int rank) {
    switch (rank) {
      case 1:
        return (AppColors.accent, '🥇');
      case 2:
        return (Colors.grey.shade300, '🥈');
      case 3:
        return (Colors.brown.shade400, '🥉');
      default:
        return (AppColors.info, '');
    }
  }

  String _formatNum(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      if (v.abs() >= 1000) return v.toStringAsFixed(0);
      return v.toStringAsFixed(2);
    }
    return v.toString();
  }
}

// ─── Error View ───────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────
int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    if (parsed != null) return parsed;
  }
  return 0;
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v.replaceAll('%', ''));
    if (parsed != null) return parsed;
  }
  return 0;
}
