// ============================================================================
// مساعد الاستثمار Flutter - Alerts Center Screen
// مركز التنبيهات الموحّد: قائمة + إحصائيات + فلاتر + إنشاء/حذف/تحديد الكل كمقروء
// APIs:
//   GET    /api/alerts              → api.getAlerts() (price alerts)
//   GET    /api/notifications       → user notifications (via api.dio)
//   POST   /api/alerts/create       → api.createAlert(data)
//   DELETE /api/alerts/[id]         → api.deleteAlert(id)
//   POST   /api/notifications       → mark_all_read
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../models/types.dart';
import '../widgets/state_view.dart';
import '../widgets/skeleton_loader.dart';
import '../core/app_localizations.dart';

class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({super.key});

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  // Filter: all / unread / info / warning / danger / success
  String _filter = 'all';

  static const List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'الكل', 'icon': Icons.list_rounded},
    {'key': 'unread', 'label': 'غير مقروء', 'icon': Icons.mark_chat_unread_rounded},
    {'key': 'info', 'label': 'معلومة', 'icon': Icons.info_outline_rounded},
    {'key': 'warning', 'label': 'تحذير', 'icon': Icons.warning_amber_rounded},
    {'key': 'danger', 'label': 'خطر', 'icon': Icons.dangerous_outlined},
    {'key': 'success', 'label': 'نجاح', 'icon': Icons.check_circle_outline_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  // ──────────────────────────────────────────────────────────────────────
  // API calls
  // ──────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    try {
      final response = await api.dio.get('/api/notifications');
      final data = response.data;
      List raw;
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        final list = data['notifications'] ??
            data['items'] ??
            data['data'] ??
            data['results'] ??
            const [];
        raw = list is List ? list : const [];
      } else {
        raw = const [];
      }
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('[AlertsCenter] notifications fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPriceAlerts() async {
    try {
      final alerts = await api.getAlerts();
      // Normalize PriceAlert → map for unified rendering
      return alerts.map((a) {
        final m = a.toJson();
        m['__kind'] = 'price_alert';
        m['id'] = a.id;
        m['title'] = 'تنبيه سعر: ${a.symbol}';
        m['message'] =
            '${a.condition == 'ABOVE' ? 'أعلى من' : 'أقل من'} ${a.targetPrice}';
        m['severity'] = a.condition == 'ABOVE' ? 'info' : 'warning';
        m['created_at'] = a.createdAt?.toIso8601String();
        m['is_read'] = false;
        return m;
      }).toList();
    } catch (e) {
      debugPrint('[AlertsCenter] price alerts fetch failed: $e');
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Prefer /api/notifications; if empty, fall back to price alerts.
      final notifs = await _fetchNotifications();
      final priceAlerts = await _fetchPriceAlerts();

      final merged = <Map<String, dynamic>>[];
      merged.addAll(notifs.map((n) {
        n['__kind'] = n['__kind'] ?? 'notification';
        return n;
      }));
      merged.addAll(priceAlerts);

      // Sort: unread first, then by created_at desc
      merged.sort((a, b) {
        final aRead = _isRead(a);
        final bRead = _isRead(b);
        if (aRead != bRead) return aRead ? 1 : -1;
        final aTime = _parseTime(a['created_at'] ?? a['timestamp']);
        final bTime = _parseTime(b['created_at'] ?? b['timestamp']);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _items = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _actionLoading = true);
    try {
      await api.dio.post(
        '/api/notifications',
        data: {'mark_all_read': true, 'action': 'mark_all_read'},
      );
      // Optimistic local update
      setState(() {
        for (final it in _items) {
          if (it['__kind'] == 'notification') {
            it['is_read'] = true;
          }
        }
      });
      _showSnack('تم تحديد الكل كمقروء', AppColors.success);
    } catch (e) {
      _showSnack('فشل التحديد: $e', AppColors.danger);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _markReadSingle(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    // Optimistic
    setState(() => item['is_read'] = true);
    try {
      await api.markNotificationRead(id);
    } catch (e) {
      debugPrint('[AlertsCenter] mark single read failed: $e');
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final kind = item['__kind'];
    final removed = Map<String, dynamic>.from(item);
    setState(() => _items.removeWhere((e) => identical(e, item)));

    try {
      if (kind == 'price_alert') {
        await api.deleteAlert(id);
      } else {
        // Try DELETE /api/notifications/[id]; tolerate failure
        await api.dio.delete('/api/notifications/$id');
      }
      _showSnack('تم الحذف', AppColors.textMuted);
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          _items.add(removed);
          _items.sort((a, b) {
            final aRead = _isRead(a);
            final bRead = _isRead(b);
            if (aRead != bRead) return aRead ? 1 : -1;
            final aTime = _parseTime(a['created_at'] ?? a['timestamp']);
            final bTime = _parseTime(b['created_at'] ?? b['timestamp']);
            return bTime.compareTo(aTime);
          });
        });
        _showSnack('فشل الحذف من الخادم: $e', AppColors.danger);
      }
    }
  }

  Future<void> _createAlert(Map<String, dynamic> data) async {
    try {
      await api.createAlert(data);
      _showSnack('تم إنشاء التنبيه بنجاح', AppColors.success);
      _loadAll();
    } catch (e) {
      _showSnack('فشل إنشاء التنبيه: $e', AppColors.danger);
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────
  bool _isRead(Map<String, dynamic> item) {
    final v = item['is_read'] ?? item['read'] ?? item['isRead'];
    if (v is bool) return v;
    if (v is num) return v.toInt() != 0;
    if (v is String) return v.toLowerCase() == 'true' || v == '1';
    return false;
  }

  String _severity(Map<String, dynamic> item) {
    final s = (item['severity'] ??
            item['type'] ??
            item['priority'] ??
            item['level'] ??
            'info')
        .toString()
        .toLowerCase();
    if (s.contains('warn')) return 'warning';
    if (s.contains('danger') ||
        s.contains('error') ||
        s.contains('critical')) {
      return 'danger';
    }
    if (s.contains('success') || s.contains('ok')) return 'success';
    if (s.contains('info')) return 'info';
    return s;
  }

  ({Color color, IconData icon, String label}) _severityVisual(String s) {
    switch (s) {
      case 'warning':
        return (
          color: AppColors.warning,
          icon: Icons.warning_amber_rounded,
          label: 'تحذير'
        );
      case 'danger':
        return (
          color: AppColors.danger,
          icon: Icons.dangerous_outlined,
          label: 'خطر'
        );
      case 'success':
        return (
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
          label: 'نجاح'
        );
      default:
        return (
          color: AppColors.info,
          icon: Icons.info_outline_rounded,
          label: 'معلومة'
        );
    }
  }

  DateTime _parseTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is DateTime) return v;
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    return DateTime.tryParse(v.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatTime(dynamic v) {
    if (v == null) return '';
    final dt = _parseTime(v);
    if (dt.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  bool _matchesFilter(Map<String, dynamic> item) {
    if (_filter == 'all') return true;
    if (_filter == 'unread') return !_isRead(item);
    return _severity(item) == _filter;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAr = AppLocalizations.isArabic;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'مركز التنبيهات',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديد الكل كمقروء',
              icon: _actionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Icon(Icons.done_all_rounded,
                      color: AppColors.primary),
              onPressed: _actionLoading ? null : _markAllRead,
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _loadAll,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateSheet,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          icon: const Icon(Icons.add_alert_rounded),
          label: const Text('إنشاء تنبيه'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonCard(height: 100),
          SizedBox(height: 12),
          SkeletonCard(height: 50),
          SizedBox(height: 12),
          SkeletonList(itemCount: 6, itemHeight: 90),
        ],
      );
    }

    if (_error != null && _items.isEmpty) {
      return StateView(
        error: 'فشل تحميل التنبيهات',
        onRetry: _loadAll,
      );
    }

    final filtered = _items.where(_matchesFilter).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 12),
          _buildFilterChips(),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const StateView(
                empty: true,
                emptyMessage: 'لا توجد تنبيهات مطابقة لهذا الفلتر')
          else
            ...filtered.map(_buildAlertCard).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final total = _items.length;
    final unread = _items.where((e) => !_isRead(e)).length;
    final bySeverity = <String, int>{
      'info': 0,
      'warning': 0,
      'danger': 0,
      'success': 0,
    };
    for (final it in _items) {
      final s = _severity(it);
      bySeverity[s] = (bySeverity[s] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;
        final stats = <_StatSpec>[
          _StatSpec('الإجمالي', '$total', AppColors.primary,
              Icons.notifications_rounded),
          _StatSpec('غير مقروء', '$unread', AppColors.accent,
              Icons.mark_chat_unread_rounded),
          _StatSpec('معلومة', '${bySeverity['info']}', AppColors.info,
              Icons.info_outline_rounded),
          _StatSpec('تحذير', '${bySeverity['warning']}', AppColors.warning,
              Icons.warning_amber_rounded),
          _StatSpec('خطر', '${bySeverity['danger']}', AppColors.danger,
              Icons.dangerous_outlined),
          _StatSpec('نجاح', '${bySeverity['success']}', AppColors.success,
              Icons.check_circle_outline_rounded),
        ];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats
              .map((s) => SizedBox(
                    width: (constraints.maxWidth -
                            (crossAxisCount - 1) * 8) /
                        crossAxisCount,
                    child: _statCard(s),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _statCard(_StatSpec s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(s.icon, size: 14, color: s.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
                const SizedBox(height: 2),
                Text(s.value,
                    style: TextStyle(
                        color: s.color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final key = f['key'] as String;
          final active = _filter == key;
          return GestureDetector(
            onTap: () => setState(() => _filter = key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(f['icon'] as IconData,
                      size: 13,
                      color: active
                          ? AppColors.white
                          : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      color:
                          active ? AppColors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> item) {
    final read = _isRead(item);
    final sev = _severity(item);
    final visual = _severityVisual(sev);
    final title = (item['title'] ?? item['subject'] ?? 'تنبيه').toString();
    final message = (item['message'] ??
            item['body'] ??
            item['description'] ??
            '')
        .toString();
    final time = item['created_at'] ?? item['timestamp'] ?? item['created'];
    final kind = item['__kind'] ?? 'notification';

    return Dismissible(
      key: ValueKey('${kind}_${item['id'] ?? title}_${time.hashCode}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: read ? AppColors.surface : visual.color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: read
                ? AppColors.border
                : visual.color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(visual.icon, size: 18, color: visual.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: visual.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: visual.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          visual.label,
                          style: TextStyle(
                            color: visual.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (kind == 'price_alert')
                        const Icon(Icons.price_change_outlined,
                            size: 12, color: AppColors.textMuted),
                      const Spacer(),
                      if (_formatTime(time).isNotEmpty)
                        Text(
                          _formatTime(time),
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!read && kind == 'notification')
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 20, color: AppColors.success),
                onPressed: () => _markReadSingle(item),
                tooltip: 'تحديد كمقروء',
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Create Alert Bottom Sheet
  // ──────────────────────────────────────────────────────────────────────
  void _showCreateSheet() {
    final symbolCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String condition = 'ABOVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_alert_rounded,
                                color: AppColors.primary, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('إنشاء تنبيه سعر جديد',
                                style: AppTypography.titleSmall),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sheetField(symbolCtrl, 'رمز السهم (مثال: COMI)',
                          hint: 'COMI'),
                      const SizedBox(height: 10),
                      _sheetField(priceCtrl, 'السعر المستهدف (ج.م)',
                          isNumber: true),
                      const SizedBox(height: 10),
                      _sheetField(noteCtrl, 'ملاحظة (اختياري)',
                          maxLines: 2),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('الشرط: ',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('أعلى من'),
                            selected: condition == 'ABOVE',
                            onSelected: (_) =>
                                setSheet(() => condition = 'ABOVE'),
                            selectedColor: AppColors.success,
                            labelStyle: TextStyle(
                                color: condition == 'ABOVE'
                                    ? AppColors.white
                                    : AppColors.textSecondary),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('أقل من'),
                            selected: condition == 'BELOW',
                            onSelected: (_) =>
                                setSheet(() => condition = 'BELOW'),
                            selectedColor: AppColors.danger,
                            labelStyle: TextStyle(
                                color: condition == 'BELOW'
                                    ? AppColors.white
                                    : AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final symbol =
                                symbolCtrl.text.trim().toUpperCase();
                            final price =
                                double.tryParse(priceCtrl.text) ?? 0;
                            if (symbol.isEmpty || price <= 0) {
                              _showSnack(
                                  'أدخل رمز سهم وسعر صحيح', AppColors.warning);
                              return;
                            }
                            Navigator.pop(ctx);
                            _createAlert({
                              'symbol': symbol,
                              'target_price': price,
                              'condition': condition,
                              if (noteCtrl.text.trim().isNotEmpty)
                                'note': noteCtrl.text.trim(),
                            });
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('حفظ التنبيه'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _StatSpec {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatSpec(this.label, this.value, this.color, this.icon);
}
