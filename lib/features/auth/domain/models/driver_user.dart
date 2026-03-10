/// Driver user model (manual implementation - no code generation needed)
class DriverUser {
  final String driverId;
  final String? tenantId; // Optional - may not be in API response
  final String email;
  final String firstName;
  final String lastName;
  final DriverStatus status;
  final String? phone;

  const DriverUser({
    required this.driverId,
    this.tenantId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phone,
  });

  String get fullName => '$firstName $lastName';

  bool get isActive => status == DriverStatus.active;
  bool get isPending => status == DriverStatus.pending;
  bool get isOnboarding => status == DriverStatus.onboarding;

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    return DriverUser(
      driverId: json['driverId'] as String,
      tenantId: json['tenantId'] as String?,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      status: DriverStatus.fromString(json['status'] as String),
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'tenantId': tenantId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'status': status.value,
      'phone': phone,
    };
  }

  DriverUser copyWith({
    String? driverId,
    String? tenantId,
    String? email,
    String? firstName,
    String? lastName,
    DriverStatus? status,
    String? phone,
  }) {
    return DriverUser(
      driverId: driverId ?? this.driverId,
      tenantId: tenantId ?? this.tenantId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      status: status ?? this.status,
      phone: phone ?? this.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverUser &&
        other.driverId == driverId &&
        other.tenantId == tenantId &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.status == status &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return Object.hash(
      driverId,
      tenantId,
      email,
      firstName,
      lastName,
      status,
      phone,
    );
  }
}

/// Driver status enum
enum DriverStatus {
  pending('pending'),
  onboarding('onboarding'),
  active('active'),
  suspended('suspended');

  final String value;
  const DriverStatus(this.value);

  static DriverStatus fromString(String value) {
    return DriverStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DriverStatus.pending,
    );
  }
}
