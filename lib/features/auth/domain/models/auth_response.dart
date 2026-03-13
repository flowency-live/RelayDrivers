import 'driver_user.dart';

/// Authentication response from login/verify endpoints
/// Backend returns: { success: true, driver: {...}, accessToken?: string }
/// accessToken is optional - backend may set it in cookie instead
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final DriverUser user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns 'driver' not 'user'
    final rawDriverData = json['driver'] ?? json['user'];
    if (rawDriverData == null) {
      throw FormatException('Response missing driver/user data');
    }

    // Backend returns operators at response root, not inside driver object
    final driverData = Map<String, dynamic>.from(rawDriverData as Map<String, dynamic>);

    // Merge top-level fields into driver data for DriverUser parsing
    if (json['operators'] != null) {
      driverData['operators'] = json['operators'];
    }
    if (json['activeOperator'] != null) {
      driverData['activeOperator'] = json['activeOperator'];
    }

    // accessToken might be in response body or extracted from cookie
    final token = json['accessToken'] as String? ?? json['token'] as String? ?? '';

    return AuthResponse(
      accessToken: token,
      refreshToken: json['refreshToken'] as String?,
      user: DriverUser.fromJson(driverData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'driver': user.toJson(),
    };
  }
}

/// Magic link request response
class MagicLinkResponse {
  final bool success;
  final String message;

  const MagicLinkResponse({
    required this.success,
    required this.message,
  });

  factory MagicLinkResponse.fromJson(Map<String, dynamic> json) {
    return MagicLinkResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
    };
  }
}
