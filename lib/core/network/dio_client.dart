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

  /// Timestamp of last token save - used to prevent 401 invalidation race condition.
  /// On web platform, FlutterSecureStorage writes are async and may not be
  /// immediately readable. We ignore 401s during the grace period after login.
  DateTime? _lastTokenSaveTime;
  static const Duration _tokenSaveGracePeriod = Duration(seconds: 3);

  /// Track requests currently being retried to prevent infinite retry loops
  final Set<String> _retriedRequests = {};

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
    print('[DioClient] _attachToken for ${options.path}: token=${token != null ? 'present (${token.length} chars)' : 'NULL'}, lastSave=${_lastTokenSaveTime?.toIso8601String() ?? 'never'}');
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
      // Generate unique key for this request to track retries
      final requestKey =
          '${error.requestOptions.method}:${error.requestOptions.path}';

      print('[DioClient] 401 on $requestKey, lastSave=${_lastTokenSaveTime?.toIso8601String() ?? 'never'}, alreadyRetried=${_retriedRequests.contains(requestKey)}');

      // Check if we're within the grace period after a token save.
      // On web, secure storage writes are async and may not be immediately readable.
      // This prevents logout loop when navigating to home immediately after login.
      if (_lastTokenSaveTime != null &&
          !_retriedRequests.contains(requestKey)) {
        final timeSinceSave = DateTime.now().difference(_lastTokenSaveTime!);
        print('[DioClient] Grace period check: timeSinceSave=${timeSinceSave.inMilliseconds}ms, gracePeriod=${_tokenSaveGracePeriod.inMilliseconds}ms');
        if (timeSinceSave < _tokenSaveGracePeriod) {
          // Within grace period - retry the request instead of invalidating
          // This handles the race condition where API calls happen before
          // the token write is fully propagated on web platform
          try {
            final token = await _secureStorage.read(key: accessTokenKey);
            print('[DioClient] Retry read token: ${token != null ? 'present' : 'NULL'}');
            if (token != null) {
              // Mark as retried to prevent infinite loop
              _retriedRequests.add(requestKey);
              // Token exists, retry the request
              print('[DioClient] Retrying $requestKey with token');
              final retryResponse = await _retry(error.requestOptions);
              _retriedRequests.remove(requestKey);
              return handler.resolve(retryResponse);
            }
          } catch (e) {
            // Retry failed, clean up and continue with normal 401 handling
            print('[DioClient] Retry failed for $requestKey: $e');
            _retriedRequests.remove(requestKey);
          }
        }
      }

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
    // Record the save time for grace period handling
    _lastTokenSaveTime = DateTime.now();
    // Clear retry tracking for new session
    _retriedRequests.clear();
    await _secureStorage.write(key: accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
    }
    // On web platform, secure storage writes may need a brief moment to propagate.
    // Verify the write was successful by reading back.
    final verifyToken = await _secureStorage.read(key: accessTokenKey);
    print('[DioClient] saveTokens: wrote token, verify=${verifyToken != null ? 'present (${verifyToken.length} chars)' : 'NULL'}');
    if (verifyToken != accessToken) {
      // If verification fails, retry the write
      print('[DioClient] Token verification mismatch, retrying write');
      await _secureStorage.write(key: accessTokenKey, value: accessToken);
    }
  }

  Future<void> clearTokens() async {
    _lastTokenSaveTime = null; // Clear grace period on logout
    _retriedRequests.clear(); // Clear retry tracking
    await _secureStorage.delete(key: accessTokenKey);
    await _secureStorage.delete(key: refreshTokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = await _secureStorage.read(key: accessTokenKey);
    return token != null;
  }

  /// Get current access token (for biometric storage)
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: accessTokenKey);
  }
}
