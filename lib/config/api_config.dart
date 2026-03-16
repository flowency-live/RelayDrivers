import 'environment.dart';

/// API endpoint configuration
class ApiConfig {
  static const _config = currentEnvironment;

  static String get baseUrl => _config.apiBaseUrl;

  // Driver Auth endpoints (base path: /driver)
  static const String authLogin = '/driver/auth/login';
  static const String authRegister = '/driver/auth/register';
  static const String authMagicLink = '/driver/auth/magic-link';
  static const String authVerify = '/driver/auth/verify';
  static const String authRefresh = '/driver/auth/refresh';
  static const String authSession = '/driver/auth/session';

  // OTP Auth endpoints (Phone authentication)
  static const String authRequestOtp = '/driver/auth/request-otp';
  static const String authVerifyOtp = '/driver/auth/verify-otp';
  static const String authCheckIdentity = '/driver/auth/check-identity';

  // Invite Auth endpoints (Invite-based onboarding)
  static const String authInviteVerify = '/driver/auth/invite/verify';
  static const String authInviteClaim = '/driver/auth/invite/claim';

  // Driver Profile endpoints
  static const String profile = '/driver/profile';
  static const String profilePhotoUploadUrl = '/driver/profile/photo/upload-url';
  static const String profilePhoto = '/driver/profile/photo';

  // Driver Vehicles endpoints
  static const String vehicles = '/driver/vehicles';

  // Driver Documents endpoints
  static const String documents = '/driver/documents';

  // Driver Availability endpoints
  static const String availability = '/driver/availability';

  // Driver Face Verification endpoints
  static const String faceUploadUrl = '/driver/face/upload-url';
  static const String faceRegister = '/driver/face/register';
  static const String faceVerify = '/driver/face/verify';
  static const String faceStatus = '/driver/face/status';

  // Driver Jobs endpoints (Phase 2)
  static const String jobs = '/driver/jobs';

  // Driver Notifications endpoints
  static const String notifications = '/driver/notifications';
  static const String notificationsUnreadCount = '/driver/notifications/unread-count';
  static const String notificationsReadAll = '/driver/notifications/read-all';
}
