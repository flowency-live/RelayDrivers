import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/notification_providers.dart';

/// Notification bell icon with badge for unread count
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return IconButton(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 99 ? '99+' : unreadCount.toString(),
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () {
        context.push('/notifications');
      },
      tooltip: 'Notifications',
    );
  }
}

/// Auto-refreshing notification bell that polls for new notifications
class NotificationBellWithPolling extends ConsumerStatefulWidget {
  /// Poll interval in seconds (default: 60)
  final int pollIntervalSeconds;

  const NotificationBellWithPolling({
    super.key,
    this.pollIntervalSeconds = 60,
  });

  @override
  ConsumerState<NotificationBellWithPolling> createState() =>
      _NotificationBellWithPollingState();
}

class _NotificationBellWithPollingState
    extends ConsumerState<NotificationBellWithPolling>
    with WidgetsBindingObserver {
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial load
    _loadNotifications();
    // Start polling
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isPolling = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, refresh notifications
      _loadNotifications();
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      // App went to background, stop polling
      _isPolling = false;
    }
  }

  void _loadNotifications() {
    ref.read(notificationStateProvider.notifier).refreshNotifications();
  }

  void _startPolling() async {
    if (_isPolling) return;
    _isPolling = true;

    while (_isPolling && mounted) {
      await Future.delayed(Duration(seconds: widget.pollIntervalSeconds));
      if (_isPolling && mounted) {
        ref.read(notificationStateProvider.notifier).refreshNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NotificationBell();
  }
}
