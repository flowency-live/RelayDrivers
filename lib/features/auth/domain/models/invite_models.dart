import 'driver_user.dart';

/// Invite verify response - shows driver info before OTP
class InviteVerifyResponse {
  final String firstName;
  final String lastName;
  final String maskedPhone;
  final String tenantId;
  final String? companyName;

  const InviteVerifyResponse({
    required this.firstName,
    required this.lastName,
    required this.maskedPhone,
    required this.tenantId,
    this.companyName,
  });

  factory InviteVerifyResponse.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] as Map<String, dynamic>? ?? {};
    return InviteVerifyResponse(
      firstName: driver['firstName'] as String? ?? '',
      lastName: driver['lastName'] as String? ?? '',
      maskedPhone: driver['maskedPhone'] as String? ?? '***',
      tenantId: json['tenantId'] as String? ?? '',
      companyName: json['companyName'] as String?,
    );
  }

  String get fullName => '$firstName $lastName';
}

/// Invite claim response - successful login after OTP
class InviteClaimResponse {
  final DriverUser driver;
  final String tenantId;
  final String token;

  const InviteClaimResponse({
    required this.driver,
    required this.tenantId,
    required this.token,
  });

  factory InviteClaimResponse.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> headers,
  ) {
    // Get token from body or Set-Cookie header
    String? token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      final setCookie = headers['set-cookie'];
      if (setCookie != null) {
        final cookieString =
            setCookie is List ? setCookie.join('; ') : setCookie.toString();
        final tokenRegex = RegExp(r'driverToken=([^;]+)');
        final match = tokenRegex.firstMatch(cookieString);
        token = match?.group(1);
      }
    }

    // Get driver data and merge top-level operators/activeOperator
    // Backend returns operators at response root, not inside driver object
    final driverData = Map<String, dynamic>.from(
      json['driver'] as Map<String, dynamic>? ?? {},
    );

    // Merge top-level fields into driver data for DriverUser parsing
    if (json['operators'] != null) {
      driverData['operators'] = json['operators'];
    }
    if (json['activeOperator'] != null) {
      driverData['activeOperator'] = json['activeOperator'];
    }

    return InviteClaimResponse(
      driver: DriverUser.fromJson(driverData),
      tenantId: json['activeOperator'] as String? ?? '',
      token: token ?? '',
    );
  }
}

/// Invite auth state machine - discriminated union
sealed class InviteAuthState {
  const InviteAuthState();
}

/// Initial state - invite code input
class InviteAuthInitial extends InviteAuthState {
  const InviteAuthInitial();
}

/// Verifying invite code
class InviteAuthVerifying extends InviteAuthState {
  final String code;
  const InviteAuthVerifying({required this.code});
}

/// Invite verified - show driver info and request OTP
class InviteAuthVerified extends InviteAuthState {
  final String code;
  final String firstName;
  final String lastName;
  final String maskedPhone;
  final String tenantId;
  final String? companyName;

  const InviteAuthVerified({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.maskedPhone,
    required this.tenantId,
    this.companyName,
  });

  String get fullName => '$firstName $lastName';
}

/// OTP sent for invite claim
class InviteAuthOtpSent extends InviteAuthState {
  final String code;
  final String phone;
  final String firstName;
  final String tenantId;
  final String? companyName;
  final DateTime sentAt;

  const InviteAuthOtpSent({
    required this.code,
    required this.phone,
    required this.firstName,
    required this.tenantId,
    this.companyName,
    required this.sentAt,
  });

  bool get canResend => DateTime.now().difference(sentAt).inSeconds >= 60;

  int get secondsUntilResend {
    final elapsed = DateTime.now().difference(sentAt).inSeconds;
    return elapsed >= 60 ? 0 : 60 - elapsed;
  }
}

/// Claiming invite (verifying OTP)
class InviteAuthClaiming extends InviteAuthState {
  final String code;
  const InviteAuthClaiming({required this.code});
}

/// Success - authenticated via invite
class InviteAuthSuccess extends InviteAuthState {
  final DriverUser driver;
  final String tenantId;

  const InviteAuthSuccess({
    required this.driver,
    required this.tenantId,
  });
}

/// Error state
class InviteAuthError extends InviteAuthState {
  final String message;
  final String? code;
  final bool isExpired;
  final bool isUsed;

  const InviteAuthError({
    required this.message,
    this.code,
    this.isExpired = false,
    this.isUsed = false,
  });
}
