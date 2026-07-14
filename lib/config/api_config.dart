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

  // Driver Jobs endpoints (driver-jobs API)
  static const String jobs = '/driver/jobs';
  static String jobAccept(String jobId) => '/driver/jobs/$jobId/accept';
  static String jobDecline(String jobId) => '/driver/jobs/$jobId/decline';
  static String jobStatus(String jobId) => '/driver/jobs/$jobId/status';

  // Driver Earnings endpoint (driver-jobs API)
  static const String earnings = '/driver/earnings';

  // Driver Notifications endpoints
  static const String notifications = '/driver/notifications';
  static const String notificationsUnreadCount = '/driver/notifications/unread-count';
  static const String notificationsReadAll = '/driver/notifications/read-all';

  // ---------------------------------------------------------------------------
  // NOT YET IMPLEMENTED BY BACKEND (marked TODO). These are the expected paths
  // the client is coded against; enable the callers once the routes exist.
  // ---------------------------------------------------------------------------

  /// TODO(backend): Push device-token registration. No such route exists in the
  /// deployed gateway yet. Expected contract:
  ///   POST /driver/devices  { platform: "android"|"ios"|"web", token: "<fcm>" }
  ///   -> 200 { success: true }
  static const String deviceRegister = '/driver/devices';

  /// TODO(backend): Live driver location ping while a job is en_route/arrived.
  /// No such route exists in the deployed gateway yet. Expected contract:
  ///   POST /driver/jobs/{id}/location
  ///     { lat: number, lng: number, heading?: number, speed?: number,
  ///       accuracy?: number, recordedAt: ISO8601 }
  ///   -> 200 { success: true }
  static String jobLocation(String jobId) => '/driver/jobs/$jobId/location';
}
