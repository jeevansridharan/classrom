// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await notificationService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: notificationService.userNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications Yet',
              subtitle: 'When classmates answer your doubts or upvote your answers, you will be notified here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final item = notifications[index];
              final isUnread = !item.read;

              return ListTile(
                tileColor: isUnread ? AppColors.primary.withOpacity(0.08) : null,
                leading: CircleAvatar(
                  backgroundColor: _getIconBgColor(item.type),
                  child: Icon(_getIconData(item.type), color: Colors.white, size: 20),
                ),
                title: Text(
                  item.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.body, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(item.createdAt),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                trailing: isUnread
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
                onTap: () {
                  notificationService.markAsRead(item.id);
                  if (item.referenceId.isNotEmpty) {
                    context.push('/question/${item.referenceId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'accepted':
        return AppColors.accent;
      case 'upvote':
        return AppColors.secondary;
      case 'new_answer':
        return AppColors.primary;
      default:
        return AppColors.surfaceVariant;
    }
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'accepted':
        return Icons.verified_rounded;
      case 'upvote':
        return Icons.thumb_up_rounded;
      case 'new_answer':
        return Icons.question_answer_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
