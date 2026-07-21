// ============================================================================
// مساعد الاستثمار Flutter - Trading Journal Screen
// Personal trade log with notes, P/L tracking, and statistics
// API: /api/portfolio/holdings + local journal persistence
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';

class TradingJournalScreen extends StatefulWidget {
  const TradingJournalScreen({super.key});

  @override
  State<TradingJournalScreen> createState() => _TradingJournalScreenState();
}

class _TradingJournalScreenState extends State<TradingJournalScreen>
    with SingleTickerProviderStateMixin {
  static const String _kJournalKey = 'trading_journal_entries';

  late TabController _tabController;
  List<_JournalEntry> _entries = [];
  List<String> _suggestedTickers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadJournal();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadJournal() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kJournalKey);
      if (str != null) {
        final list = jsonDecode(str) as List;
        _entries = list
            .map((e) => _JournalEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _entries.sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveJournal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kJournalKey, jsonEncode(_entries.map((e) => e.toMap()).toList()));
    } catch (_) {}
  }

  Future<void> _loadSuggestions() async {
    try {
      // Pull current portfolio holdings for quick ticker suggestions
      final data = await api.getPortfolioHoldings();
      final rawHoldings = data['holdings'] ?? data['positions'] ?? data['data'];
      final tickers = <String>[];
      if (rawHoldings is List) {
        for (final h in rawHoldings) {
          if (h is Map) {
            final t = (h['ticker'] ?? h['symbol'] ?? '').toString();
            if (t.isNotEmpty && !tickers.contains(t)) tickers.add(t);
          }
        }
      }
      if (mounted) setState(() => _suggestedTickers = tickers);
    } catch (_) {}
  }

  void _showAddEntryDialog({_JournalEntry? editEntry}) {
    final tickerCtrl = TextEditingController(text: editEntry?.ticker ?? '');
    final qtyCtrl = TextEditingController(
        text: editEntry?.quantity.toString() ?? '');
    final entryCtrl = TextEditingController(
        text: editEntry?.entryPrice.toStringAsFixed(2) ?? '');
    final exitCtrl = TextEditingController(
        text: editEntry?.exitPrice?.toStringAsFixed(2) ?? '');
    final noteCtrl = TextEditingController(text: editEntry?.note ?? '');
    final strategyCtrl = TextEditingController(
        text: editEntry?.strategy ?? '');
    String action = editEntry?.action ?? 'BUY';
    String emotion = editEntry?.emotion ?? 'neutral';
    final dateCtrl = TextEditingController(
        text: editEntry?.date ?? DateTime.now().toIso8601String().substring(0, 10),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editEntry == null ? 'صفقة جديدة' : 'تعديل الصفقة',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    // Ticker field with suggestions
                    TextField(
                      controller: tickerCtrl,
                      decoration: const InputDecoration(
                        labelText: 'السهم',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setSheet(() {}),
                    ),
                    if (_suggestedTickers.isNotEmpty &&
                        tickerCtrl.text.isEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: _suggestedTickers
                            .take(6)
                            .map((t) => ActionChip(
                                  label: Text(t),
                                  backgroundColor: AppColors.surfaceMuted,
                                  onPressed: () {
                                    tickerCtrl.text = t;
                                    setSheet(() {});
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Action + emotion chips
                    Row(
                      children: [
                        Expanded(
                          child: _SegmentedChoice(
                            label: 'النوع',
                            options: const [
                              ('BUY', 'شراء'),
                              ('SELL', 'بيع'),
                            ],
                            value: action,
                            onChanged: (v) => setSheet(() => action = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dateCtrl,
                            decoration: const InputDecoration(
                              labelText: 'التاريخ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entryCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر الدخول',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: exitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'سعر الخروج (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: strategyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'الاستراتيجية (مثال: Maestro)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SegmentedChoice(
                      label: 'الحالة النفسية',
                      options: const [
                        ('calm', 'هادئ'),
                        ('greedy', 'طماع'),
                        ('fearful', 'خائف'),
                        ('neutral', 'محايد'),
                      ],
                      value: emotion,
                      onChanged: (v) => setSheet(() => emotion = v),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (editEntry != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _entries.removeWhere(
                                    (e) => e.id == editEntry.id);
                              });
                              _saveJournal();
                              Navigator.pop(ctx);
                            },
                            child: const Text('حذف',
                                style: TextStyle(color: AppColors.danger)),
                          ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final ticker = tickerCtrl.text.trim();
                            final qty = int.tryParse(qtyCtrl.text) ?? 0;
                            final entry = double.tryParse(entryCtrl.text);
                            final exit = double.tryParse(exitCtrl.text);
                            if (ticker.isEmpty || qty == 0 || entry == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('الرجاء إدخال السهم والكمية وسعر الدخول'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                              return;
                            }
                            final entry2 = _JournalEntry(
                              id: editEntry?.id ??
                                  DateTime.now().millisecondsSinceEpoch.toString(),
                              ticker: ticker,
                              action: action,
                              quantity: qty,
                              entryPrice: entry,
                              exitPrice: exit,
                              note: noteCtrl.text.trim(),
                              strategy: strategyCtrl.text.trim(),
                              emotion: emotion,
                              date: dateCtrl.text.trim(),
                            );
                            setState(() {
                              if (editEntry != null) {
                                _entries.removeWhere(
                                    (e) => e.id == editEntry.id);
                              }
                              _entries.insert(0, entry2);
                              _entries.sort((a, b) => b.date.compareTo(a.date));
                            });
                            _saveJournal();
                            Navigator.pop(ctx);
                          },
                          child: Text(editEntry == null ? 'حفظ' : 'تحديث'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _JournalStats.compute(_entries);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddEntryDialog(),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: AppColors.white),
          label: const Text('صفقة جديدة',
              style: TextStyle(color: AppColors.white)),
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 130,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.secondary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: AppColors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book_rounded,
                                color: AppColors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('يومية التداول',
                                    style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                Text('سجل صفقاتك وملاحظاتك',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Stats row
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _statColumn(
                          'الصفقات', '${stats.total}', AppColors.primary),
                    ),
                    Container(
                        width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: _statColumn('رابحة', '${stats.wins}',
                          AppColors.success),
                    ),
                    Container(
                        width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: _statColumn('خاسرة', '${stats.losses}',
                          AppColors.danger),
                    ),
                    Container(
                        width: 1, height: 36, color: AppColors.border),
                    Expanded(
                      child: _statColumn(
                        'صافي P/L',
                        '${stats.netPnl >= 0 ? '+' : ''}${stats.netPnl.toStringAsFixed(0)}',
                        stats.netPnl >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'الصفقات'),
                    Tab(text: 'تحليلات'),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEntriesTab(),
                  _buildAnalyticsTab(stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ),
      ],
    );
  }

  Widget _buildEntriesTab() {
    if (_loading) {
      return const SkeletonList(itemCount: 4, itemHeight: 110);
    }
    if (_entries.isEmpty) {
      return const StateView(
        empty: true,
        emptyMessage: 'لا توجد صفقات مسجلة. اضغط "صفقة جديدة" للبدء',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadJournal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
        itemCount: _entries.length,
        cacheExtent: 600,
        itemBuilder: (context, index) {
          final e = _entries[index];
          return RepaintBoundary(
            child: _JournalCard(
              entry: e,
              onTap: () => _showAddEntryDialog(editEntry: e),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab(_JournalStats stats) {
    if (_entries.isEmpty) {
      return const StateView(
        empty: true,
        emptyMessage: 'لا توجد بيانات لتحليلها بعد',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      children: [
        _buildAnalyticsCard(
          title: 'معدل النجاح',
          value: '${(stats.winRate * 100).toStringAsFixed(1)}%',
          color: stats.winRate >= 0.5
              ? AppColors.success
              : AppColors.danger,
          icon: Icons.verified_outlined,
        ),
        _buildAnalyticsCard(
          title: 'متوسط الربح للصفقة الرابحة',
          value:
              '${stats.avgWin >= 0 ? '+' : ''}${stats.avgWin.toStringAsFixed(2)}',
          color: AppColors.success,
          icon: Icons.trending_up_rounded,
        ),
        _buildAnalyticsCard(
          title: 'متوسط الخسارة للصفقة الخاسرة',
          value:
              '${stats.avgLoss >= 0 ? '+' : ''}${stats.avgLoss.toStringAsFixed(2)}',
          color: AppColors.danger,
          icon: Icons.trending_down_rounded,
        ),
        _buildAnalyticsCard(
          title: 'نسبة المخاطرة/العائد',
          value: stats.riskReward.toStringAsFixed(2),
          color: stats.riskReward >= 1.5
              ? AppColors.success
              : AppColors.warning,
          icon: Icons.balance_outlined,
        ),
        if (stats.byStrategy.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.insights_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('الأداء حسب الاستراتيجية',
                      style: AppTypography.titleSmall),
                ]),
                const Divider(height: 16),
                ...stats.byStrategy.entries.map((entry) {
                  final s = entry.value;
                  final color =
                      s.netPnl >= 0 ? AppColors.success : AppColors.danger;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Text('${s.wins}/${s.total}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Text(
                          '${s.netPnl >= 0 ? '+' : ''}${s.netPnl.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (stats.byEmotion.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.mood_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('الأداء حسب الحالة النفسية',
                      style: AppTypography.titleSmall),
                ]),
                const Divider(height: 16),
                ...stats.byEmotion.entries.map((entry) {
                  final label = _emotionLabel(entry.key);
                  final s = entry.value;
                  final color =
                      s.netPnl >= 0 ? AppColors.success : AppColors.danger;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        Text('${s.wins}/${s.total}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 12),
                        Text(
                          '${s.netPnl >= 0 ? '+' : ''}${s.netPnl.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withValues(alpha: 0.15),
          AppColors.surface,
        ]),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emotionLabel(String key) {
    switch (key) {
      case 'calm':
        return 'هادئ';
      case 'greedy':
        return 'طماع';
      case 'fearful':
        return 'خائف';
      default:
        return 'محايد';
    }
  }
}

// ============================================================================
// Segmented Choice
// ============================================================================
class _SegmentedChoice extends StatelessWidget {
  final String label;
  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  const _SegmentedChoice({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: options.map((o) {
            final active = o.$1 == value;
            return GestureDetector(
              onTap: () => onChanged(o.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(o.$2,
                    style: TextStyle(
                      color:
                          active ? AppColors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================================
// Journal Card
// ============================================================================
class _JournalCard extends StatelessWidget {
  final _JournalEntry entry;
  final VoidCallback onTap;

  const _JournalCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBuy = entry.action == 'BUY';
    final hasExit = entry.exitPrice != null;
    double? pnl;
    double? pnlPct;
    if (hasExit) {
      final diff = (entry.exitPrice! - entry.entryPrice) * entry.quantity;
      pnl = isBuy ? diff : -diff;
      final cost = entry.entryPrice * entry.quantity;
      pnlPct = cost > 0 ? (pnl / cost) * 100 : 0;
    }
    final color = pnl == null
        ? AppColors.warning
        : (pnl >= 0 ? AppColors.success : AppColors.danger);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border(
            right: BorderSide(color: color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isBuy ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isBuy ? 'شراء' : 'بيع',
                    style: TextStyle(
                      color: isBuy ? AppColors.success : AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.ticker,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                Text(entry.date,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _field('الكمية', '${entry.quantity}'),
                ),
                Expanded(
                  child: _field('الدخول', entry.entryPrice.toStringAsFixed(2)),
                ),
                if (hasExit)
                  Expanded(
                    child: _field(
                        'الخروج', entry.exitPrice!.toStringAsFixed(2)),
                  ),
                if (pnl != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('P/L',
                            style: TextStyle(
                                fontSize: 9, color: AppColors.textMuted)),
                        Text(
                          '${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (entry.strategy.isNotEmpty ||
                entry.emotion != 'neutral' ||
                entry.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (entry.strategy.isNotEmpty)
                    _tag('🎯 ${entry.strategy}', AppColors.primary),
                  if (entry.emotion != 'neutral')
                    _tag(_emotionIcon(entry.emotion), AppColors.accent),
                ],
              ),
              if (entry.note.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(entry.note,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  String _emotionIcon(String e) {
    switch (e) {
      case 'calm':
        return '😌 هادئ';
      case 'greedy':
        return '🤑 طماع';
      case 'fearful':
        return '😨 خائف';
      default:
        return '😐 محايد';
    }
  }
}

// ============================================================================
// Journal Stats
// ============================================================================
class _JournalStats {
  final int total;
  final int wins;
  final int losses;
  final double netPnl;
  final double avgWin;
  final double avgLoss;
  final double winRate;
  final double riskReward;
  final Map<String, _StrategyStat> byStrategy;
  final Map<String, _StrategyStat> byEmotion;

  _JournalStats({
    required this.total,
    required this.wins,
    required this.losses,
    required this.netPnl,
    required this.avgWin,
    required this.avgLoss,
    required this.winRate,
    required this.riskReward,
    required this.byStrategy,
    required this.byEmotion,
  });

  static _JournalStats compute(List<_JournalEntry> entries) {
    int wins = 0, losses = 0;
    double netPnl = 0;
    double totalWin = 0;
    double totalLoss = 0;
    final byStrategy = <String, _StrategyStat>{};
    final byEmotion = <String, _StrategyStat>{};
    for (final e in entries) {
      final pnl = e.pnl;
      if (pnl != null) {
        if (pnl >= 0) {
          wins++;
          totalWin += pnl;
        } else {
          losses++;
          totalLoss += pnl.abs();
        }
        netPnl += pnl;
      }
      // by strategy
      final stratKey = e.strategy.isEmpty ? 'بدون استراتيجية' : e.strategy;
      byStrategy.update(
        stratKey,
        (s) => s..add(pnl),
        ifAbsent: () => _StrategyStat()..add(pnl),
      );
      // by emotion
      byEmotion.update(
        e.emotion,
        (s) => s..add(pnl),
        ifAbsent: () => _StrategyStat()..add(pnl),
      );
    }
    final decided = wins + losses;
    final winRate = decided > 0 ? wins / decided : 0.0;
    final avgWin = wins > 0 ? totalWin / wins : 0.0;
    final avgLoss = losses > 0 ? totalLoss / losses : 0.0;
    final riskReward = avgLoss > 0 ? avgWin / avgLoss : (avgWin > 0 ? 99.0 : 0.0);
    return _JournalStats(
      total: entries.length,
      wins: wins,
      losses: losses,
      netPnl: netPnl,
      avgWin: avgWin,
      avgLoss: avgLoss,
      winRate: winRate,
      riskReward: riskReward,
      byStrategy: byStrategy,
      byEmotion: byEmotion,
    );
  }
}

class _StrategyStat {
  int total = 0;
  int wins = 0;
  double netPnl = 0;
  void add(double? pnl) {
    total++;
    if (pnl != null) {
      if (pnl >= 0) wins++;
      netPnl += pnl;
    }
  }
}

// ============================================================================
// Journal Entry Model
// ============================================================================
class _JournalEntry {
  final String id;
  final String ticker;
  final String action; // BUY | SELL
  final int quantity;
  final double entryPrice;
  final double? exitPrice;
  final String note;
  final String strategy;
  final String emotion;
  final String date;

  _JournalEntry({
    required this.id,
    required this.ticker,
    required this.action,
    required this.quantity,
    required this.entryPrice,
    required this.exitPrice,
    required this.note,
    required this.strategy,
    required this.emotion,
    required this.date,
  });

  double? get pnl {
    if (exitPrice == null) return null;
    final diff = (exitPrice! - entryPrice) * quantity;
    return action == 'BUY' ? diff : -diff;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'ticker': ticker,
        'action': action,
        'quantity': quantity,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'note': note,
        'strategy': strategy,
        'emotion': emotion,
        'date': date,
      };

  factory _JournalEntry.fromMap(Map<String, dynamic> m) => _JournalEntry(
        id: (m['id'] ?? '').toString(),
        ticker: (m['ticker'] ?? '').toString(),
        action: (m['action'] ?? 'BUY').toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 0,
        entryPrice: (m['entryPrice'] as num?)?.toDouble() ?? 0,
        exitPrice: (m['exitPrice'] as num?)?.toDouble(),
        note: (m['note'] ?? '').toString(),
        strategy: (m['strategy'] ?? '').toString(),
        emotion: (m['emotion'] ?? 'neutral').toString(),
        date: (m['date'] ?? '').toString(),
      );
}
