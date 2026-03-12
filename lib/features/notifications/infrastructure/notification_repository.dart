import 'package:dio/dio.dart';
import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/driver_notification.dart';

/// Repository for driver notification operations
class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository(this._dioClient);

  /// Get all notifications for the driver
  /// [unreadOnly] - If true, only return unread notifications
  /// [limit] - Max number of notifications to return
  Future<NotificationListResult> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.notifications,
        queryParameters: {
          'unreadOnly': unreadOnly.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final notificationsJson = response.data['notifications'] as List<dynamic>;
        final notifications = notificationsJson
            .map((json) => DriverNotification.fromJson(json as Map<String, dynamic>))
            .toList();
        final unreadCount = response.data['unreadCount'] as int? ?? 0;

        return NotificationListResult(
          notifications: notifications,
          unreadCount: unreadCount,
        );
      }

      throw Exception(response.data['error'] ?? 'Failed to get notifications');
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Network error';
      throw Exception(message);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConfig.notificationsUnreadCount,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['count'] as int? ?? 0;
      }

      throw Exception(response.data['error'] ?? 'Failed to get unread count');
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Network error';
      throw Exception(message);
    }
  }

  /// Mark a notification as read
  Future<DriverNotification> markAsRead(String notificationId) async {
    try {
      final response = await _dioClient.dio.put(
        '${ApiConfig.notifications}/$notificationId/read',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return DriverNotification.fromJson(
          response.data['notification'] as Map<String, dynamic>,
        );
      }

      throw Exception(response.data['error'] ?? 'Failed to mark as read');
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Network error';
      throw Exception(message);
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _dioClient.dio.put(
        ApiConfig.notificationsReadAll,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['updatedCount'] as int? ?? 0;
      }

      throw Exception(response.data['error'] ?? 'Failed to mark all as read');
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Network error';
      throw Exception(message);
    }
  }
}

/// Result class for notification list with unread count
class NotificationListResult {
  final List<DriverNotification> notifications;
  final int unreadCount;

  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });
}
