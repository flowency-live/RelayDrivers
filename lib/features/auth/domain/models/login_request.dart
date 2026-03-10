/// Login request model
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Registration request model
class RegisterRequest {
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String password;

  const RegisterRequest({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.password,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'password': password,
    };
  }
}

/// Magic link request model
class MagicLinkRequest {
  final String email;

  const MagicLinkRequest({required this.email});

  factory MagicLinkRequest.fromJson(Map<String, dynamic> json) {
    return MagicLinkRequest(
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Magic link verification request
class VerifyMagicLinkRequest {
  final String token;

  const VerifyMagicLinkRequest({required this.token});

  factory VerifyMagicLinkRequest.fromJson(Map<String, dynamic> json) {
    return VerifyMagicLinkRequest(
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token};
  }
}
