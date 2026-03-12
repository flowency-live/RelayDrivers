import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/notification_providers.dart';
import '../../domain/models/driver_notification.dart';

/// Notifications page - list driver notifications
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Load notifications on page load
    Future.microtask(() {
      ref.read(notificationStateProvider.notifier).loadNotifications();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(notificationStateProvider.notifier).refreshNotifications();
  }

  void _markAllAsRead() async {
    final success =
        await ref.read(notificationStateProvider.notifier).markAllAsRead();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleNotificationTap(DriverNotification notification) async {
    // Mark as read
    if (!notification.read) {
      await ref
          .read(notificationStateProvider.notifier)
          .markAsRead(notification.notificationId);
    }

    // Handle action navigation
    if (notification.hasAction && mounted) {
      _navigateToAction(notification);
    }
  }

  void _navigateToAction(DriverNotification notification) {
    switch (notification.data.actionType) {
      case NotificationActionType.uploadPhoto:
        if (notification.data.vrn != null) {
          context.push('/vehicles/${notification.data.vrn}');
        } else {
          context.push('/vehicles');
        }
        break;
      case NotificationActionType.uploadDocument:
        context.push('/documents');
        break;
      case NotificationActionType.viewProfile:
        context.push('/profile');
        break;
      case NotificationActionType.contactSupport:
        // Could open email or support page in future
        break;
      case NotificationActionType.none:
        // No navigation
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationStateProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: switch (notificationState) {
        NotificationInitial() || NotificationLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
        NotificationError(:final message) => _ErrorView(
            message: message,
            onRetry: () {
              ref.read(notificationStateProvider.notifier).loadNotifications();
            },
          ),
        NotificationLoaded(:final notifications) => notifications.isEmpty
            ? const _EmptyNotificationsView()
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                    );
                  },
                ),
              ),
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final DriverNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  IconData get _iconData {
    switch (notification.type) {
      case DriverNotificationType.statusChange:
        return Icons.verified_outlined;
      case DriverNotificationType.documentRequest:
        return Icons.description_outlined;
      case DriverNotificationType.photoRequest:
        return Icons.camera_alt_outlined;
      case DriverNotificationType.adminMessage:
        return Icons.message_outlined;
      case DriverNotificationType.system:
        return Icons.info_outlined;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (notification.type) {
      case DriverNotificationType.statusChange:
        return Colors.green;
      case DriverNotificationType.documentRequest:
        return Colors.orange;
      case DriverNotificationType.photoRequest:
        return Colors.blue;
      case DriverNotificationType.adminMessage:
        return Theme.of(context).colorScheme.primary;
      case DriverNotificationType.system:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? theme.colorScheme.primaryContainer.withAlpha(50)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? theme.colorScheme.primary.withAlpha(100)
              : theme.colorScheme.outline.withAlpha(30),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _iconColor(context).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _iconData,
                  color: _iconColor(context),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.timeAgo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (notification.hasAction) ...[
                          const Spacer(),
                          _ActionButton(notification: notification),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DriverNotification notification;

  const _ActionButton({required this.notification});

  String get _buttonText {
    switch (notification.data.actionType) {
      case NotificationActionType.uploadPhoto:
        return 'Upload Photo';
      case NotificationActionType.uploadDocument:
        return 'Upload Document';
      case NotificationActionType.viewProfile:
        return 'View Profile';
      case NotificationActionType.contactSupport:
        return 'Contact Support';
      case NotificationActionType.none:
        return '';
    }
  }

  IconData get _buttonIcon {
    switch (notification.data.actionType) {
      case NotificationActionType.uploadPhoto:
        return Icons.camera_alt;
      case NotificationActionType.uploadDocument:
        return Icons.upload_file;
      case NotificationActionType.viewProfile:
        return Icons.person;
      case NotificationActionType.contactSupport:
        return Icons.support_agent;
      case NotificationActionType.none:
        return Icons.arrow_forward;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notification.data.actionType == NotificationActionType.none) {
      return const SizedBox.shrink();
    }

    return FilledButton.tonalIcon(
      onPressed: null, // Handled by parent InkWell
      icon: Icon(_buttonIcon, size: 16),
      label: Text(_buttonText),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see notifications here when there\'s something important to tell you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withAlpha(179),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
