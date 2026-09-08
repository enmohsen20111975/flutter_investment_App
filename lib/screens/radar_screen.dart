// ============================================================================
// مساعد الاستثمار Flutter - Radar Screen (حركة السيولة والميكرز)
// ============================================================================
// يعرض بيانات رادار صناع السوق من /api/maker-radar:
//   - top_explosions: قائمة موحّدة مرتّبة حسب قوة الانفجار
//   - quiet_list: التجميع الهادئ
//   - pre_surge_list: ما قبل الانفجار
//   - explosive_list: انفجار سيولي
//   - surge_detector: حجم ≥ 2× (أي سهم نشط)
//   - early_break_list: اختراق مبكر
//
// كل سهم فيه: entry / target_1 / target_2 / stop / R:R / signal_type
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import 'stock_history_screen.dart';

// ─── Provider: Radar Data ─────────────────────────────────────────────────
final radarDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = GLMApiClient.instance;
  final data = await api.getMakerRadar(market: 'EGX');
  if (data.isEmpty) {
    // لو الـ cache مفيش، حرّك الـ warmup
    await api.warmupMakerRadar(market: 'EGX');
    // انتظر شوية وجيب تاني
    await Future.delayed(const Duration(seconds: 2));
    return api.getMakerRadar(market: 'EGX');
  }
  return data;
});

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});

  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radarAsync = ref.watch(radarDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رادار السيولة والميكرز'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(radarDataProvider),
            tooltip: 'تحديث',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '🏆 الأعلى انفجار', icon: Icon(Icons.local_fire_department, size: 16)),
            Tab(text: '💥 Surge', icon: Icon(Icons.bolt, size: 16)),
            Tab(text: '🚀 Pre-Surge', icon: Icon(Icons.rocket_launch, size: 16)),
            Tab(text: '🎯 Quiet', icon: Icon(Icons.visibility, size: 16)),
            Tab(text: '⚡ Early Break', icon: Icon(Icons.trending_up, size: 16)),
          ],
        ),
      ),
      body: radarAsync.when(
        loading: () => const LoadingWidget(message: 'جارٍ تحميل بيانات الرادار...'),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('فشل تحميل الرادار: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(radarDataProvider),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (data) {
          if (data.isEmpty || data['success'] == false) {
            if (data['warming_up'] == true) {
              return EmptyStateWidget(
                icon: Icons.hourglass_top,
                message: data['error']?.toString() ?? 'أول مرة تشغّل الرادار — حاول تاني خلال دقيقة',
              );
            }
            return const EmptyStateWidget(
              icon: Icons.radar,
              message: 'الرادار لسه ما تشغّلش — اضغط تحديث',
            );
          }

          // استخراج القوائم
          final topExplosions = (data['top_explosions'] as List?) ?? [];
          final surgeDetector = (data['surge_detector_list'] as List?) ?? [];
          final preSurge = (data['pre_surge_list'] as List?) ?? [];
          final quiet = (data['quiet_list'] as List?) ?? [];
          final earlyBreak = (data['early_break_list'] as List?) ?? [];

          // الـ summary
          final summary = <String, dynamic>{
            'total_scanned': data['total_scanned'] ?? 0,
            'under_microscope': data['under_microscope_count'] ?? 0,
            'explosive': data['explosive_count'] ?? 0,
            'surge_detector': data['surge_detector_count'] ?? 0,
            'pre_surge': data['pre_surge_count'] ?? 0,
            'quiet': data['quiet_count'] ?? 0,
            'early_break': data['early_break_count'] ?? 0,
            'top_explosions': data['top_explosions_count'] ?? topExplosions.length,
            'cache_age_seconds': data['cache_age_seconds'] ?? 0,
            'warmup_running': data['warmup_running'] ?? false,
          };

          return Column(
            children: [
              _buildSummaryBar(summary),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStockList(topExplosions, isTopExplosion: true),
                    _buildStockList(surgeDetector),
                    _buildStockList(preSurge),
                    _buildStockList(quiet),
                    _buildStockList(earlyBreak),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Summary Bar ────────────────────────────────────────────────────────
  Widget _buildSummaryBar(Map<String, dynamic> summary) {
    final cacheAge = summary['cache_age_seconds'] as int? ?? 0;
    final isStale = cacheAge > 900; // 15 min
    final warmupRunning = summary['warmup_running'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip('🔍 فحص', '${summary['total_scanned']}', Colors.blue),
            _summaryChip('🔬 ميكروسكوب', '${summary['under_microscope']}', Colors.purple),
            _summaryChip('🏆 انفجار', '${summary['top_explosions']}', Colors.orange),
            _summaryChip('💥 Surge', '${summary['surge_detector']}', Colors.red),
            _summaryChip('🚀 Pre', '${summary['pre_surge']}', Colors.green),
            _summaryChip('🎯 Quiet', '${summary['quiet']}', Colors.teal),
            const SizedBox(width: 8),
            if (warmupRunning)
              _statusChip('🔄 بيتسخن', Colors.amber)
            else if (isStale)
              _statusChip('⚠️ بيانات قديمة', Colors.redAccent)
            else
              _statusChip('✅ طازج', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text('$label: $value', style: const TextStyle(fontSize: 11)),
        backgroundColor: color.withOpacity(0.15),
        side: BorderSide(color: color.withOpacity(0.3)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: color.withOpacity(0.2),
        side: BorderSide(color: color),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // ─── Stock List ────────────────────────────────────────────────────────
  Widget _buildStockList(List<dynamic> stocks, {bool isTopExplosion = false}) {
    if (stocks.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.inbox_outlined,
        message: 'مفيش أسهم في القائمة دي دلوقتي',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(radarDataProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: stocks.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final stock = stocks[index] as Map<String, dynamic>;
          return _buildStockCard(stock, index + 1, isTopExplosion);
        },
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> stock, int rank, bool isTopExplosion) {
    final ticker = stock['ticker']?.toString() ?? '';
    final price = (stock['current_price'] as num?)?.toDouble() ?? 0.0;
    final volRatio = (stock['vol_ratio_now'] as num?)?.toDouble() ?? 0.0;
    final confidence = (stock['confidence_score'] as num?)?.toDouble() ?? 0.0;
    final roc10 = (stock['roc_10d'] as num?)?.toDouble();
    final path = stock['path']?.toString() ?? '';
    final killSwitch = stock['kill_switch'] as bool? ?? false;
    final expected = stock['expected']?.toString() ?? '';
    final signalType = stock['signal_type']?.toString() ?? 'BUY';
    final explosionScore = (stock['explosion_score'] as num?)?.toDouble();

    // trade_levels
    final tl = stock['trade_levels'] as Map<String, dynamic>?;
    final entry = tl != null ? (tl['entry'] as num?)?.toDouble() : null;
    final target1 = tl != null ? (tl['target_1'] as num?)?.toDouble() : null;
    final target2 = tl != null ? (tl['target_2'] as num?)?.toDouble() : null;
    final stop = tl != null ? (tl['stop'] as num?)?.toDouble() : null;
    final rr = tl != null ? (tl['risk_reward'] as num?)?.toDouble() : null;

    final isSell = signalType == 'SELL';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: killSwitch
              ? Colors.red
              : (isSell ? Colors.orange : Colors.green),
          child: Text('#$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Text(ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 8),
            if (isTopExplosion && explosionScore != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('⚡ ${explosionScore.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            const Spacer(),
            Text('${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: (roc10 ?? 0) >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (volRatio > 0)
                _miniBadge('Vol ${volRatio.toStringAsFixed(1)}×', Colors.red),
              if (confidence > 0)
                _miniBadge('ثقة ${confidence.toStringAsFixed(0)}%', _confidenceColor(confidence)),
              if (roc10 != null)
                _miniBadge('ROC10 ${roc10 >= 0 ? '+' : ''}${roc10.toStringAsFixed(1)}%',
                    roc10 >= 0 ? Colors.green : Colors.red),
              if (killSwitch)
                _miniBadge('🛑 KILL', Colors.red),
              if (isSell)
                _miniBadge('🔻 SELL', Colors.orange),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trade Levels
                if (entry != null && target1 != null && stop != null) ...[
                  const Text('🎯 مستويات التداول', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _levelsGrid(entry, target1, target2, stop, rr),
                  const SizedBox(height: 12),
                ],
                // Info
                if (expected.isNotEmpty) ...[
                  Row(
                    children: [
                      const Text('التوقع: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(child: Text(expected, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    const Text('المسار: ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(path, style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.track_changes, size: 16),
                      label: const Text('تتبّع', style: TextStyle(fontSize: 12)),
                      onPressed: () => _trackStock(ticker, entry ?? price),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.analytics, size: 16),
                      label: const Text('تفاصيل', style: TextStyle(fontSize: 12)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockHistoryScreen(ticker: ticker),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Color _confidenceColor(double conf) {
    if (conf >= 70) return Colors.green;
    if (conf >= 50) return Colors.blue;
    if (conf >= 30) return Colors.orange;
    return Colors.red;
  }

  Widget _levelsGrid(double entry, double? target1, double? target2, double stop, double? rr) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 2.0,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _levelCell('دخول', entry.toStringAsFixed(2), Colors.blue),
        if (target1 != null)
          _levelCell('هدف 1', target1.toStringAsFixed(2), Colors.green),
        if (target2 != null)
          _levelCell('هدف 2', target2.toStringAsFixed(2), Colors.teal),
        _levelCell('وقف', stop.toStringAsFixed(2), Colors.red),
        if (rr != null)
          _levelCell('R:R', rr.toStringAsFixed(1), Colors.purple),
        _levelCell('الحالة', 'BUY', Colors.green),
      ],
    );
  }

  Widget _levelCell(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _trackStock(String ticker, double entryPrice) async {
    try {
      await GLMApiClient.instance.trackRadarStock(
        ticker: ticker,
        entryPrice: entryPrice,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم تتبّع $ticker عند $entryPrice')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ فشل التتبّع: $e')),
        );
      }
    }
  }
}
