// ============================================================================
// مساعد الاستثمار Flutter - Notifications Screen
// Shows user notifications fetched from /api/mobile/notifications
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../api/client.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/state_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<List<dynamic>>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<dynamic>> _fetchNotifications() async {
    try {
      return await api.getMobileNotifications();
    } catch (_) {
      return [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notificationsFuture = _fetchNotifications();
    });
  }

  Future<void> _markAsRead(String id) async {
    await api.markNotificationRead(id);
    _refresh();
  }

  IconData _notificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'price_alert':
        return Icons.trending_up;
      case 'signal':
        return Icons.auto_awesome;
      case 'system':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'price_alert':
        return AppColors.success;
      case 'signal':
        return AppColors.primary;
      case 'system':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return timestamp;
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
          title: const Text('الإشعارات',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<List<dynamic>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 5);
            }
            if (snapshot.hasError) {
              return StateView(error: 'فشل تحميل الإشعارات', onRetry: _refresh);
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const StateView(
                  empty: true, emptyMessage: 'لا توجد إشعارات');
            }
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index] is Map
                      ? Map<String, dynamic>.from(notifications[index])
                      : <String, dynamic>{};
                  final id = notif['id']?.toString() ?? '';
                  final type = notif['type']?.toString();
                  final title = notif['title']?.toString() ?? 'إشعار';
                  final message = notif['message']?.toString() ?? '';
                  final time = notif['created_at']?.toString() ??
                      notif['timestamp']?.toString();
                  final isRead =
                      notif['is_read'] == true || notif['read'] == true;

                  return GestureDetector(
                    onTap: isRead ? null : () => _markAsRead(id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            isRead ? AppColors.surface : AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isRead
                              ? AppColors.border
                              : AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _notificationColor(type)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _notificationIcon(type),
                              color: _notificationColor(type),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(title,
                                          style: TextStyle(
                                            fontWeight: isRead
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                            fontSize: 13,
                                          ))),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ]),
                                if (message.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(message,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                                if (time != null && time.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(_formatTime(time),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
