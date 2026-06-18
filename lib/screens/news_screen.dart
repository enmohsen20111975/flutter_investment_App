// ============================================================================
// مساعد الاستثمار Flutter - News Screen
// Shows news from /api/mobile/news with category filters
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';
import 'stock_history_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  Future<List<dynamic>>? _newsFuture;
  String _category = 'الكل';

  final List<String> _categories = ['الكل', 'بورصة', 'كريبتو', 'مؤشرات'];

  @override
  void initState() {
    super.initState();
    _newsFuture = _fetchNews();
  }

  Future<List<dynamic>> _fetchNews() async {
    try {
      return await api.getMobileNews();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() => _newsFuture = _fetchNews());
  }

  Color _importanceColor(String? imp) {
    switch (imp?.toLowerCase()) {
      case 'high':
      case 'مهم':
        return AppColors.danger;
      case 'medium':
      case 'متوسط':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
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
          title: const Text('الأخبار',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SkeletonList(itemCount: 5);
            if (snapshot.hasError)
              return StateView(error: 'فشل تحميل الأخبار', onRetry: _refresh);
            final news = snapshot.data ?? [];
            if (news.isEmpty)
              return const StateView(
                  empty: true, emptyMessage: 'لا توجد أخبار');
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: Column(children: [
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: _categories
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                label: Text(c,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _category == c
                                            ? AppColors.white
                                            : AppColors.textSecondary)),
                                selected: _category == c,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                    color: _category == c
                                        ? AppColors.primary
                                        : AppColors.border),
                                onSelected: (_) {
                                  setState(() => _category = c);
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: news.length,
                    itemBuilder: (context, index) {
                      final n = news[index] is Map
                          ? Map<String, dynamic>.from(news[index])
                          : <String, dynamic>{};
                      final title = n['title']?.toString() ??
                          n['headline']?.toString() ??
                          '';
                      final summary = n['summary']?.toString() ??
                          n['snippet']?.toString() ??
                          '';
                      final source = n['source']?.toString() ?? '';
                      final time = n['published_at']?.toString() ??
                          n['timestamp']?.toString() ??
                          '';
                      final importance = n['importance']?.toString() ??
                          n['priority']?.toString();
                      final tickers = n['tickers'] is List
                          ? (n['tickers'] as List)
                              .map((e) => e.toString())
                              .toList()
                          : <String>[];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14))),
                                if (importance != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: _importanceColor(importance)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(importance,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _importanceColor(importance))),
                                  ),
                              ]),
                              if (summary.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(summary,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                              if (tickers.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                    spacing: 6,
                                    children: tickers
                                        .map((t) => ActionChip(
                                              label: Text(t,
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          AppColors.primary)),
                                              backgroundColor:
                                                  AppColors.primaryMuted,
                                              padding: EdgeInsets.zero,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (_) =>
                                                            StockHistoryScreen(
                                                                ticker: t)));
                                              },
                                            ))
                                        .toList()),
                              ],
                              const SizedBox(height: 6),
                              Row(children: [
                                if (source.isNotEmpty)
                                  Text(source,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                if (source.isNotEmpty && time.isNotEmpty)
                                  const SizedBox(width: 8),
                                if (time.isNotEmpty)
                                  Text(time,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                              ]),
                            ]),
                      );
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
