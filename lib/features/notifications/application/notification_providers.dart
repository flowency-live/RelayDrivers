import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/driver_notification.dart';
import '../infrastructure/notification_repository.dart';

/// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return NotificationRepository(dioClient);
});

/// Notification state
sealed class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<DriverNotification> notifications;
  final int unreadCount;
  const NotificationLoaded(this.notifications, this.unreadCount);
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
}

/// Notification notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;

  NotificationNotifier({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationInitial());

  /// Load notifications from API
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    state = const NotificationLoading();

    try {
      final result = await _repository.getNotifications(unreadOnly: unreadOnly);
      state = NotificationLoaded(result.notifications, result.unreadCount);
    } catch (e) {
      state = NotificationError(_parseError(e));
    }
  }

  /// Refresh notifications (keep current state while loading)
  Future<void> refreshNotifications({bool unreadOnly = false}) async {
    try {
      final result = await _repository.getNotifications(unreadOnly: unreadOnly);
      state = NotificationLoaded(result.notifications, result.unreadCount);
    } catch (e) {
      // Keep current state on refresh failure
    }
  }

  /// Mark a notification as read
  Future<bool> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return false;

    try {
      await _repository.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.notificationId == notificationId) {
          return DriverNotification(
            notificationId: n.notificationId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            read: true,
            readAt: DateTime.now().toIso8601String(),
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      final newUnreadCount =
          updatedNotifications.where((n) => !n.read).length;
      state = NotificationLoaded(updatedNotifications, newUnreadCount);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return false;

    try {
      await _repository.markAllAsRead();

      // Update local state - mark all as read
      final now = DateTime.now().toIso8601String();
      final updatedNotifications = currentState.notifications.map((n) {
        if (!n.read) {
          return DriverNotification(
            notificationId: n.notificationId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            read: true,
            readAt: now,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();

      state = NotificationLoaded(updatedNotifications, 0);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Notification state provider
final notificationStateProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository: repository);
});

/// Convenience provider for notification list
final notificationListProvider = Provider<List<DriverNotification>>((ref) {
  final state = ref.watch(notificationStateProvider);
  if (state is NotificationLoaded) return state.notifications;
  return [];
});

/// Provider for unread count (for notification badge)
final unreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationStateProvider);
  if (state is NotificationLoaded) return state.unreadCount;
  return 0;
});

/// Provider for unread notifications only
final unreadNotificationsProvider = Provider<List<DriverNotification>>((ref) {
  final notifications = ref.watch(notificationListProvider);
  return notifications.where((n) => !n.read).toList();
});
