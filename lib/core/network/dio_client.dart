import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/api_config.dart';
import '../../config/environment.dart';

/// Callback for when authentication is invalidated (401 with no refresh)
typedef AuthInvalidatedCallback = void Function();

/// Dio HTTP client with JWT interceptor
class DioClient {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage;
  AuthInvalidatedCallback? _onAuthInvalidated;

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  /// Set callback for when authentication is invalidated
  void setAuthInvalidatedCallback(AuthInvalidatedCallback callback) {
    _onAuthInvalidated = callback;
  }

  DioClient({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: _attachToken,
      onError: _handleTokenExpiry,
    ));

    if (currentEnvironment.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  Dio get dio => _dio;

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Add X-Tenant-Id for dev/test mode (required by backend for tenant resolution)
    final tenantId = currentEnvironment.tenantId;
    if (tenantId != null) {
      options.headers['X-Tenant-Id'] = tenantId;
    }
    handler.next(options);
  }

  Future<void> _handleTokenExpiry(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401) {
      try {
        final refreshToken = await _secureStorage.read(key: refreshTokenKey);
        if (refreshToken != null) {
          final refreshed = await _refreshToken(refreshToken);
          if (refreshed) {
            // Retry the original request
            final retryResponse = await _retry(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        // No refresh token or refresh failed - session is invalid
        await clearTokens();
        _onAuthInvalidated?.call();
      } catch (e) {
        // Refresh failed, clear tokens and notify
        await clearTokens();
        _onAuthInvalidated?.call();
      }
    }
    handler.next(error);
  }

  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final response = await Dio().post(
        '${ApiConfig.baseUrl}${ApiConfig.authRefresh}',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        if (newAccessToken != null) {
          await _secureStorage.write(key: accessTokenKey, value: newAccessToken);
        }
        if (newRefreshToken != null) {
          await _secureStorage.write(key: refreshTokenKey, value: newRefreshToken);
        }
        return true;
      }
    } catch (e) {
      // Refresh failed
    }
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _secureStorage.read(key: accessTokenKey);
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: accessTokenKey);
    await _secureStorage.delete(key: refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: accessTokenKey);
    return token != null;
  }
}
