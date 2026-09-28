// ============================================================================
// مساعد الاستثمار Flutter - Exit Radar Screen
// شاشة رادار الخروج — كشف علامات التوزيع
//
// تعرض:
//   - 5 مسارات خروج قابلة للطي (X1 → X5)
//   - كل مسار يعرض قائمة الأسهم مع (التيكر + السعر + السبب)
//   - ملخّص علوي بعدد إشارات الخروج لكل مسار
//
// المصدر: GET /api/maker-radar/exit-radar?market=EGX
//
// مسارات الخروج الخمسة (تتوافق مع Next.js /api/maker-radar/exit-radar):
//   X1: Momentum Loss — فقدان الزخم
//   X2: Distribution — توزيع الميكرز
//   X3: Volume Climax — ذروة حجم
//   X4: Trend Break — كسر الاتجاه
//   X5: Weakness Pattern — نمط ضعف
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

// ─── Provider: Exit Radar Data ───────────────────────────────────────────
final exitRadarProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return GLMApiClient.instance.getExitRadar(market: 'EGX');
});

class ExitRadarScreen extends ConsumerWidget {
  const ExitRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(exitRadarProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.quantumBg,
        appBar: AppBar(
          backgroundColor: AppColors.quantumBg,
          elevation: 0,
          title: const Text('رادار الخروج'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
              onPressed: () => ref.refresh(exitRadarProvider),
            ),
          ],
        ),
        body: asyncData.when(
          loading: () => const LoadingWidget(message: 'جارٍ مسح إشارات الخروج...'),
          error: (e, st) => _ErrorView(
            message: 'فشل تحميل رادار الخروج: $e',
            onRetry: () => ref.refresh(exitRadarProvider),
          ),
          data: (data) {
            if (data.isEmpty ||
                data['success'] == false ||
                data['paths'] == null && data['exit_paths'] == null) {
              final errMsg = data['error']?.toString() ?? 'لا توجد إشارات خروج حالياً';
              return EmptyStateWidget(
                icon: Icons.logout_outlined,
                message: 'تعذّر الحصول على رادار الخروج: $errMsg',
              );
            }
            return _ExitRadarBody(data: data);
          },
        ),
      ),
    );
  }
}

// ─── Body ───────────────────────────────────────────────────────────────
class _ExitRadarBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExitRadarBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final paths = _extractPaths(data);
    final updatedAt = data['updated_at']?.toString() ??
        data['timestamp']?.toString() ??
        '—';
    final totalStocks = paths.values.fold<int>(0, (sum, list) => sum + list.length);

    return Column(
      children: [
        // Top summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.quantumGlass,
            border: Border(bottom: BorderSide(color: AppColors.quantumGlassBorder)),
          ),
          child: Row(
            children: [
              _SummaryChip(label: 'إجمالي الأسهم', value: '$totalStocks', color: AppColors.danger),
              const SizedBox(width: 8),
              _SummaryChip(label: 'المسارات', value: '${paths.length}/5', color: AppColors.warning),
              const SizedBox(width: 8),
              _SummaryChip(label: 'السوق', value: data['market']?.toString() ?? 'EGX', color: AppColors.info),
              const Spacer(),
              Text(
                'آخر تحديث: $updatedAt',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        // List of 5 collapsible exit paths
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: _buildPathSections(paths),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPathSections(Map<String, List<dynamic>> paths) {
    // Always show all 5 paths in order X1→X5
    const order = ['X1', 'X2', 'X3', 'X4', 'X5'];
    return order.map((code) {
      final stocks = paths[code] ?? const [];
      return _ExitPathSection(code: code, stocks: stocks);
    }).toList();
  }

  Map<String, List<dynamic>> _extractPaths(Map<String, dynamic> data) {
    // Try several common shapes: { paths: {X1:[...], X2:[...]} } | { exit_paths: {...} } | flat map { X1:[...] }
    Map<String, dynamic> raw = {};
    if (data['paths'] is Map) {
      raw = (data['paths'] as Map).cast<String, dynamic>();
    } else if (data['exit_paths'] is Map) {
      raw = (data['exit_paths'] as Map).cast<String, dynamic>();
    } else {
      // Maybe flat map at top level — filter to X1..X5 keys
      for (final k in data.keys) {
        if (RegExp(r'^X[1-5]$').hasMatch(k)) {
          raw[k] = data[k];
        }
      }
    }
    final result = <String, List<dynamic>>{};
    for (final entry in raw.entries) {
      final code = entry.key.toUpperCase();
      if (entry.value is List) {
        result[code] = entry.value as List;
      } else if (entry.value is Map) {
        // Maybe { stocks: [...] }
        final inner = entry.value as Map;
        if (inner['stocks'] is List) {
          result[code] = inner['stocks'] as List;
        } else if (inner['items'] is List) {
          result[code] = inner['items'] as List;
        } else {
          result[code] = [];
        }
      } else {
        result[code] = [];
      }
    }
    return result;
  }
}

// ─── Single Exit Path Section (collapsible) ─────────────────────────────
class _ExitPathSection extends StatefulWidget {
  final String code;
  final List<dynamic> stocks;
  const _ExitPathSection({required this.code, required this.stocks});

  @override
  State<_ExitPathSection> createState() => _ExitPathSectionState();
}

class _ExitPathSectionState extends State<_ExitPathSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final (labelAr, emoji, color) = _pathMeta(widget.code);
    final hasStocks = widget.stocks.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.quantumGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.code,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(labelAr, style: AppTypography.titleMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasStocks
                          ? AppColors.danger.withValues(alpha: 0.18)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.stocks.length}',
                      style: AppTypography.titleSmall.copyWith(
                        color: hasStocks ? AppColors.danger : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: hasStocks
                  ? Column(
                      children: widget.stocks
                          .map((s) => _StockExitCard(stock: s, pathColor: color))
                          .toList(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'لا توجد إشارات في هذا المسار',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  (String, String, Color) _pathMeta(String code) {
    switch (code) {
      case 'X1':
        return ('فقدان الزخم', '📉', AppColors.warning);
      case 'X2':
        return ('توزيع الميكرز', '💧', AppColors.danger);
      case 'X3':
        return ('ذروة الحجم', '📊', AppColors.info);
      case 'X4':
        return ('كسر الاتجاه', '🔻', AppColors.danger);
      case 'X5':
        return ('نمط ضعف', '⚠️', AppColors.warning);
      default:
        return ('مسار خروج', '🚪', AppColors.textMuted);
    }
  }
}

// ─── Stock Exit Card ─────────────────────────────────────────────────────
class _StockExitCard extends StatelessWidget {
  final dynamic stock;
  final Color pathColor;
  const _StockExitCard({required this.stock, required this.pathColor});

  @override
  Widget build(BuildContext context) {
    final m = stock is Map<String, dynamic>
        ? stock as Map<String, dynamic>
        : (stock is Map ? (stock as Map).cast<String, dynamic>() : <String, dynamic>{});

    final ticker = m['ticker']?.toString() ?? m['symbol']?.toString() ?? '—';
    final name = m['name']?.toString() ?? m['name_ar']?.toString();
    final price = _formatNum(m['price'] ?? m['last_price']);
    final changePct = _toDouble(m['change_pct'] ?? m['change_percent'] ?? m['change']);
    final reason = m['reason']?.toString() ??
        m['exit_reason']?.toString() ??
        m['signal']?.toString() ??
        'إشارة خروج';
    final strength = _toDouble(m['strength'] ?? m['score'] ?? m['confidence']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pathColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Ticker badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: pathColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              ticker,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pathColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + reason
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null && name.isNotEmpty)
                  Text(
                    name,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    ticker,
                    style: AppTypography.titleSmall,
                    maxLines: 1,
                  ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Price + change
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: AppTypography.titleSmall.copyWith(
                  color: changePct < 0 ? AppColors.danger : AppColors.text,
                ),
              ),
              if (changePct != 0)
                Text(
                  '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: changePct >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
              if (strength > 0)
                Text(
                  'قوة: ${(strength * 100).toStringAsFixed(0)}%',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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

// ─── Summary Chip ────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final parsed = double.tryParse(v.replaceAll('%', ''));
    if (parsed != null) return parsed;
  }
  return 0;
}
