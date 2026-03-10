import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/auth_response.dart';
import '../domain/models/driver_user.dart';
import '../domain/models/login_request.dart';

/// Auth repository - infrastructure layer
/// Handles API calls and token storage
class AuthRepository {
  final DioClient _dioClient;

  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Extract token from Set-Cookie header
  /// Cookie format: driverToken=xxx; HttpOnly; Secure; ...
  String? _extractTokenFromCookie(dynamic setCookieHeader) {
    if (setCookieHeader == null) return null;

    String cookieString;
    if (setCookieHeader is List) {
      cookieString = setCookieHeader.join('; ');
    } else {
      cookieString = setCookieHeader.toString();
    }

    // Find driverToken=xxx pattern
    final tokenRegex = RegExp(r'driverToken=([^;]+)');
    final match = tokenRegex.firstMatch(cookieString);
    return match?.group(1);
  }

  /// Parse auth response, extracting token from body or Set-Cookie header
  AuthResponse _parseAuthResponse(
    Map<String, dynamic> data,
    Map<String, dynamic> headers,
  ) {
    // Try to get token from response body first
    String? token = data['accessToken'] as String?;

    // If not in body, extract from Set-Cookie header
    if (token == null || token.isEmpty) {
      token = _extractTokenFromCookie(headers['set-cookie']);
    }

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token received');
    }

    // Get driver data
    final driverData = data['driver'] ?? data['user'];
    if (driverData == null) {
      throw Exception('No driver data in response');
    }

    return AuthResponse(
      accessToken: token,
      refreshToken: data['refreshToken'] as String?,
      user: DriverUser.fromJson(driverData as Map<String, dynamic>),
    );
  }

  /// Register new driver
  Future<AuthResponse> register(RegisterRequest request) async {
    final response = await _dioClient.dio.post(
      ApiConfig.authRegister,
      data: request.toJson(),
    );
    return _parseAuthResponse(
      response.data as Map<String, dynamic>,
      response.headers.map,
    );
  }

  /// Login with email and password
  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _dioClient.dio.post(
      ApiConfig.authLogin,
      data: request.toJson(),
    );
    return _parseAuthResponse(
      response.data as Map<String, dynamic>,
      response.headers.map,
    );
  }

  /// Request magic link email
  Future<MagicLinkResponse> requestMagicLink(MagicLinkRequest request) async {
    final response = await _dioClient.dio.post(
      ApiConfig.authMagicLink,
      data: request.toJson(),
    );
    return MagicLinkResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify magic link token
  Future<AuthResponse> verifyMagicLink(VerifyMagicLinkRequest request) async {
    final response = await _dioClient.dio.post(
      ApiConfig.authVerify,
      data: request.toJson(),
    );
    return _parseAuthResponse(
      response.data as Map<String, dynamic>,
      response.headers.map,
    );
  }

  /// Get current session
  Future<DriverUser> getSession() async {
    final response = await _dioClient.dio.get(ApiConfig.authSession);
    final data = response.data as Map<String, dynamic>;
    // Session endpoint returns { success: true, driver: {...} }
    final driverData = data['driver'] ?? data;
    return DriverUser.fromJson(driverData as Map<String, dynamic>);
  }

  /// Store tokens securely
  Future<void> saveTokens(AuthResponse authResponse) async {
    await _dioClient.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
  }

  /// Clear tokens (logout)
  Future<void> clearTokens() async {
    await _dioClient.clearTokens();
  }

  /// Check if user has valid token
  Future<bool> hasValidToken() async {
    return _dioClient.hasValidToken();
  }
}
