import 'driver_user.dart';

/// Identity check response - determines if user exists
class IdentityCheckResponse {
  final bool exists;
  final String? displayName;
  final String method;

  const IdentityCheckResponse({
    required this.exists,
    this.displayName,
    required this.method,
  });

  factory IdentityCheckResponse.fromJson(Map<String, dynamic> json) {
    return IdentityCheckResponse(
      exists: json['exists'] as bool? ?? false,
      displayName: json['displayName'] as String?,
      method: json['method'] as String? ?? 'phone',
    );
  }
}

/// OTP request response - confirms OTP was sent
class OtpRequestResponse {
  final bool success;
  final int expiresIn;
  final String? requestId;

  const OtpRequestResponse({
    required this.success,
    required this.expiresIn,
    this.requestId,
  });

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      success: json['success'] as bool? ?? true,
      expiresIn: json['expiresIn'] as int? ?? 300,
      requestId: json['requestId'] as String?,
    );
  }
}

/// OTP verify response - login result
class OtpVerifyResponse {
  final bool isNewDriver;
  final String? token;
  final String? refreshToken;
  final DriverUser? driver;

  const OtpVerifyResponse({
    required this.isNewDriver,
    this.token,
    this.refreshToken,
    this.driver,
  });

  factory OtpVerifyResponse.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> headers,
  ) {
    // Get token from body or Set-Cookie header
    String? token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      final setCookie = headers['set-cookie'];
      if (setCookie != null) {
        final cookieString = setCookie is List ? setCookie.join('; ') : setCookie.toString();
        final tokenRegex = RegExp(r'driverToken=([^;]+)');
        final match = tokenRegex.firstMatch(cookieString);
        token = match?.group(1);
      }
    }

    // Get refresh token from response body
    final refreshToken = json['refreshToken'] as String?;

    // Parse driver data if present, merging top-level operators/activeOperator
    DriverUser? driver;
    final rawDriverData = json['driver'];
    if (rawDriverData != null && rawDriverData is Map<String, dynamic>) {
      // Backend returns operators at response root, not inside driver object
      final driverData = Map<String, dynamic>.from(rawDriverData);

      // Merge top-level fields into driver data for DriverUser parsing
      if (json['operators'] != null) {
        driverData['operators'] = json['operators'];
      }
      if (json['activeOperator'] != null) {
        driverData['activeOperator'] = json['activeOperator'];
      }

      driver = DriverUser.fromJson(driverData);
    }

    return OtpVerifyResponse(
      isNewDriver: json['needsOnboarding'] as bool? ?? false,
      token: token,
      refreshToken: refreshToken,
      driver: driver,
    );
  }
}

/// Phone auth state machine - discriminated union
sealed class PhoneAuthState {
  const PhoneAuthState();
}

/// Initial state - phone input
class PhoneAuthInitial extends PhoneAuthState {
  const PhoneAuthInitial();
}

/// Checking if identity exists
class PhoneAuthChecking extends PhoneAuthState {
  final String phone;
  const PhoneAuthChecking({required this.phone});
}

/// OTP sent - waiting for code
class PhoneAuthOtpSent extends PhoneAuthState {
  final String phone;
  final String? displayName;
  final bool isExistingUser;
  final DateTime sentAt;

  const PhoneAuthOtpSent({
    required this.phone,
    this.displayName,
    required this.isExistingUser,
    required this.sentAt,
  });

  /// Can resend after 60 seconds
  bool get canResend => DateTime.now().difference(sentAt).inSeconds >= 60;

  /// Seconds until resend available
  int get secondsUntilResend {
    final elapsed = DateTime.now().difference(sentAt).inSeconds;
    return elapsed >= 60 ? 0 : 60 - elapsed;
  }
}

/// Verifying OTP code
class PhoneAuthVerifying extends PhoneAuthState {
  final String phone;
  const PhoneAuthVerifying({required this.phone});
}

/// Success - authenticated
class PhoneAuthSuccess extends PhoneAuthState {
  final DriverUser? driver;
  final bool isNewDriver;

  const PhoneAuthSuccess({
    this.driver,
    required this.isNewDriver,
  });
}

/// Error state
class PhoneAuthError extends PhoneAuthState {
  final String message;
  final String phone;

  const PhoneAuthError({
    required this.message,
    required this.phone,
  });
}
