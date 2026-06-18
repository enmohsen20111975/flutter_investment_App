// ============================================================================
// مساعد الاستثمار Flutter - Learning Screen
// Learning content from /api/learning/content + progress tracking
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  Future<List<dynamic>>? _lessonsFuture;
  String _category = 'الكل';

  final List<String> _categories = [
    'الكل',
    'أساسيات',
    'تحليل فني',
    'تحليل أساسي',
    'إدارة محفظة',
    'كريبتو'
  ];

  @override
  void initState() {
    super.initState();
    _lessonsFuture = _fetchLessons();
  }

  Future<List<dynamic>> _fetchLessons() async {
    try {
      return await api.getLearningContent();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() => _lessonsFuture = _fetchLessons());
  }

  Future<void> _markComplete(String lessonId) async {
    try {
      await api.updateLearningProgress(lessonId);
      _refresh();
    } catch (_) {}
  }

  Color _difficultyColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'مبتدئ':
      case 'beginner':
        return AppColors.success;
      case 'متوسط':
      case 'intermediate':
        return AppColors.warning;
      case 'متقدم':
      case 'advanced':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'أساسيات':
        return AppColors.info;
      case 'تحليل فني':
        return AppColors.primary;
      case 'تحليل أساسي':
        return AppColors.success;
      case 'إدارة محفظة':
        return AppColors.warning;
      case 'كريبتو':
        return const Color(0xFFFFD700);
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
          title: const Text('التعلم',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context)),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _lessonsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const SkeletonList(itemCount: 5, itemHeight: 120);
            if (snapshot.hasError)
              return StateView(error: 'فشل تحميل المحتوى', onRetry: _refresh);
            final lessons = snapshot.data ?? [];
            if (lessons.isEmpty)
              return const StateView(
                  empty: true, emptyMessage: 'لا توجد درسات متاحة');
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: Column(children: [
                SizedBox(
                  height: 44,
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
                                onSelected: (_) =>
                                    setState(() => _category = c),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final l = lessons[index] is Map
                          ? Map<String, dynamic>.from(lessons[index])
                          : <String, dynamic>{};
                      final id = l['id']?.toString() ?? '';
                      final title =
                          l['title']?.toString() ?? l['name']?.toString() ?? '';
                      final category = l['category']?.toString() ?? '';
                      final difficulty = l['difficulty']?.toString() ??
                          l['level']?.toString() ??
                          '';
                      final progress = (l['progress'] as num?)?.toDouble() ?? 0;
                      final completed =
                          l['completed'] == true || progress == 100;
                      final duration = l['duration_minutes'] ?? l['duration'];
                      final content = l['content']?.toString() ??
                          l['description']?.toString() ??
                          '';
                      final isFiltered =
                          _category != 'الكل' && category != _category;
                      if (isFiltered) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: completed
                                  ? AppColors.success
                                  : AppColors.border),
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
                                if (completed)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                        color: AppColors.success
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.check_circle,
                                        color: AppColors.success, size: 20),
                                  ),
                              ]),
                              const SizedBox(height: 6),
                              Row(children: [
                                if (difficulty.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: _difficultyColor(difficulty)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(difficulty,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _difficultyColor(difficulty))),
                                  ),
                                const SizedBox(width: 8),
                                if (category.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: _categoryColor(category)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(category,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: _categoryColor(category))),
                                  ),
                                const Spacer(),
                                if (duration != null)
                                  Text('⏱ ${duration} د',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                              ]),
                              if (progress > 0 && !completed) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                              value: progress / 100,
                                              backgroundColor:
                                                  AppColors.surfaceMuted,
                                              color: AppColors.primary,
                                              minHeight: 5))),
                                  const SizedBox(width: 6),
                                  Text('${progress.toInt()}%',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                ]),
                              ],
                              const SizedBox(height: 8),
                              Row(children: [
                                ElevatedButton(
                                  onPressed: completed
                                      ? null
                                      : () => _markComplete(id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: completed
                                        ? AppColors.surfaceMuted
                                        : AppColors.primary,
                                    foregroundColor: completed
                                        ? AppColors.textMuted
                                        : AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                      completed ? 'مكتمل' : 'إكمال الدرس',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () =>
                                      _showDetailDialog(title, content),
                                  child: const Text('قراءة',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary)),
                                ),
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

  void _showDetailDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Text(
              content.isEmpty ? 'لا يوجد محتوى متاح لهذا الدرس.' : content,
              style: const TextStyle(fontSize: 13, height: 1.6),
              textAlign: TextAlign.justify,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إغلاق')),
          ],
        ),
      ),
    );
  }
}
