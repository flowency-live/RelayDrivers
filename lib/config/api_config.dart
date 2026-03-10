import 'environment.dart';

/// API endpoint configuration
class ApiConfig {
  static const _config = currentEnvironment;

  static String get baseUrl => _config.apiBaseUrl;

  // Driver Auth endpoints
  static const String authLogin = '/v2/driver/auth/login';
  static const String authRegister = '/v2/driver/auth/register';
  static const String authMagicLink = '/v2/driver/auth/magic-link';
  static const String authVerify = '/v2/driver/auth/verify';
  static const String authRefresh = '/v2/driver/auth/refresh';
  static const String authSession = '/v2/driver/auth/session';

  // Driver Profile endpoints
  static const String profile = '/v2/driver/profile';

  // Driver Vehicles endpoints
  static const String vehicles = '/v2/driver/vehicles';

  // Driver Documents endpoints
  static const String documents = '/v2/driver/documents';

  // Driver Availability endpoints
  static const String availability = '/v2/driver/availability';

  // Driver Face Verification endpoints
  static const String faceUploadUrl = '/v2/driver/face/upload-url';
  static const String faceRegister = '/v2/driver/face/register';
  static const String faceVerify = '/v2/driver/face/verify';
  static const String faceStatus = '/v2/driver/face/status';

  // Driver Jobs endpoints (Phase 2)
  static const String jobs = '/v2/driver/jobs';
}
