import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import '../../features/auth/application/providers.dart';
import '../network/dio_client.dart';
import '../utils/app_logger.dart';

/// Background/terminated-state message handler.
///
/// MUST be a top-level (or static) function - the plugin invokes it in a
/// separate isolate with no access to app state. We keep it minimal: log and
/// let the OS display the notification. The jobs list is refreshed when the
/// app next comes to the foreground (see [PushNotificationService]).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // A separate isolate: initialise Firebase before touching any plugin.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase config not present in this build; nothing to do.
  }
  AppLogger.debug('[Push] background message: ${message.messageId}');
}

/// Message types the backend sends in `data.type`. A `new_job` message triggers
/// a jobs-list refresh so the driver sees the offer without polling.
class PushMessageType {
  static const String newJob = 'new_job';
  static const String jobUpdated = 'job_updated';
  static const String jobCancelled = 'job_cancelled';
}

/// Wraps Firebase Cloud Messaging: permission, token registration, and
/// foreground/background handlers. Safe to construct on any platform - if
/// Firebase is not configured (no google-services.json / GoogleService-Info),
/// [initialize] no-ops instead of throwing.
class PushNotificationService {
  final DioClient _dioClient;

  PushNotificationService({required DioClient dioClient})
      : _dioClient = dioClient;

  /// Called when a `new_job` (or job update) message arrives while the app is
  /// running. Wired by the app root to refresh the jobs provider.
  void Function()? onJobsShouldRefresh;

  bool _initialized = false;

  /// Initialise FCM: request permission, register the token, and attach
  /// handlers. Guarded so a missing Firebase config does not crash startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No Firebase config in this build (see FIREBASE_SETUP.md). Push is
      // disabled rather than fatal - the app still runs.
      AppLogger.debug('[Push] Firebase not configured; push disabled: $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.debug(
      '[Push] permission: ${settings.authorizationStatus}',
    );

    // Background/terminated handler (top-level function).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from a notification (background -> foreground).
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.debug('[Push] opened from notification: ${message.messageId}');
      onJobsShouldRefresh?.call();
    });

    // Token registration + rotation.
    try {
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }
      messaging.onTokenRefresh.listen(_registerToken);
    } catch (e) {
      AppLogger.error('[Push] token retrieval failed', e);
    }

    _initialized = true;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final type = message.data['type'];
    AppLogger.debug('[Push] foreground message type=$type');
    if (type == PushMessageType.newJob ||
        type == PushMessageType.jobUpdated ||
        type == PushMessageType.jobCancelled) {
      onJobsShouldRefresh?.call();
    }
  }

  /// Register the FCM token with the backend so it can target this device.
  Future<void> _registerToken(String token) async {
    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
    AppLogger.debug('[Push] registering token ($platform)');

    // TODO(backend): POST /driver/devices is not yet deployed (see
    // ApiConfig.deviceRegister). Until the route exists this call will 404 and
    // is swallowed; the token is still obtained so registration works the
    // moment the endpoint ships. Expected body: { platform, token }.
    try {
      await _dioClient.dio.post(
        ApiConfig.deviceRegister,
        data: {'platform': platform, 'token': token},
      );
    } catch (e) {
      AppLogger.debug(
        '[Push] token registration failed (endpoint may not exist yet): $e',
      );
    }
  }
}

/// Push notification service provider (singleton per container).
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService(dioClient: ref.watch(dioClientProvider));
});
