/// Driver notification types
enum DriverNotificationType {
  statusChange('status_change', 'Status Change'),
  documentRequest('document_request', 'Document Request'),
  photoRequest('photo_request', 'Photo Request'),
  adminMessage('admin_message', 'Message'),
  system('system', 'System');

  final String value;
  final String label;
  const DriverNotificationType(this.value, this.label);

  static DriverNotificationType fromString(String value) {
    return DriverNotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DriverNotificationType.system,
    );
  }
}

/// Notification action types
enum NotificationActionType {
  uploadDocument('upload_document', 'Upload Document'),
  uploadPhoto('upload_photo', 'Upload Photo'),
  viewProfile('view_profile', 'View Profile'),
  contactSupport('contact_support', 'Contact Support'),
  none('none', 'None');

  final String value;
  final String label;
  const NotificationActionType(this.value, this.label);

  static NotificationActionType fromString(String value) {
    return NotificationActionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationActionType.none,
    );
  }
}

/// Driver notification model
class DriverNotification {
  final String notificationId;
  final DriverNotificationType type;
  final String title;
  final String body;
  final NotificationData data;
  final bool read;
  final String? readAt;
  final String createdAt;

  const DriverNotification({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    this.readAt,
    required this.createdAt,
  });

  factory DriverNotification.fromJson(Map<String, dynamic> json) {
    return DriverNotification(
      notificationId: json['notificationId'] as String,
      type: DriverNotificationType.fromString(json['type'] as String? ?? 'system'),
      title: json['title'] as String,
      body: json['body'] as String,
      data: NotificationData.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
      read: json['read'] as bool? ?? false,
      readAt: json['readAt'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data.toJson(),
      'read': read,
      if (readAt != null) 'readAt': readAt,
      'createdAt': createdAt,
    };
  }

  /// Check if notification has an action button
  bool get hasAction => data.actionType != NotificationActionType.none;

  /// Get time ago string for display
  String get timeAgo {
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);

      if (difference.inDays > 7) {
        return '${created.day}/${created.month}/${created.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (_) {
      return createdAt;
    }
  }

  DriverNotification copyWith({
    String? notificationId,
    DriverNotificationType? type,
    String? title,
    String? body,
    NotificationData? data,
    bool? read,
    String? readAt,
    String? createdAt,
  }) {
    return DriverNotification(
      notificationId: notificationId ?? this.notificationId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      read: read ?? this.read,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Additional data attached to notifications
class NotificationData {
  final NotificationActionType actionType;
  final String? newStatus;
  final String? entityId;
  final String? vrn;

  const NotificationData({
    this.actionType = NotificationActionType.none,
    this.newStatus,
    this.entityId,
    this.vrn,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      actionType: NotificationActionType.fromString(json['actionType'] as String? ?? 'none'),
      newStatus: json['newStatus'] as String?,
      entityId: json['entityId'] as String?,
      vrn: json['vrn'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.value,
      if (newStatus != null) 'newStatus': newStatus,
      if (entityId != null) 'entityId': entityId,
      if (vrn != null) 'vrn': vrn,
    };
  }
}
