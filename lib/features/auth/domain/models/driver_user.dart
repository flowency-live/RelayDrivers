/// Driver user model (driver-owned architecture v4.0)
///
/// New JWT structure:
/// {
///   type: 'driver',
///   driverId: 'uuid',
///   email: 'driver@example.com',
///   firstName: 'John',
///   lastName: 'Doe',
///   operators: [
///     { tenantId: 'TENANT#001', status: 'active', scopes: ['profile', 'documents', 'vehicles', 'availability'] }
///   ],
///   activeOperator: 'TENANT#001'
/// }
class DriverUser {
  final String driverId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;

  /// List of operators this driver has access to
  final List<OperatorAccess> operators;

  /// Currently active operator (may be null if no operators)
  final String? activeOperator;

  /// Legacy field - kept for backward compatibility during migration
  @Deprecated('Use activeOperator or operators list instead')
  final String? tenantId;

  /// Legacy field - kept for backward compatibility during migration
  @Deprecated('Use operators list status or compliance status instead')
  final DriverStatus? status;

  const DriverUser({
    required this.driverId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.operators = const [],
    this.activeOperator,
    this.tenantId,
    this.status,
  });

  String get fullName => '$firstName $lastName';

  /// Check if driver has any active operators
  bool get hasActiveOperators => operators.any((op) => op.status == 'active');

  /// Check if driver has access to a specific operator
  bool hasAccessTo(String operatorId) {
    return operators.any((op) => op.tenantId == operatorId && op.status == 'active');
  }

  /// Get the active operator access object
  OperatorAccess? get activeOperatorAccess {
    if (activeOperator == null) return null;
    try {
      return operators.firstWhere((op) => op.tenantId == activeOperator);
    } catch (_) {
      return operators.isNotEmpty ? operators.first : null;
    }
  }

  /// Check if driver has a specific scope with active operator
  bool hasScope(String scope) {
    final access = activeOperatorAccess;
    return access?.scopes.contains(scope) ?? false;
  }

  /// Legacy compatibility - check if active (has any granted operators)
  bool get isActive => hasActiveOperators;

  /// Legacy compatibility - check if pending (no operators yet)
  bool get isPending => operators.isEmpty;

  /// Check if driver is in onboarding state
  /// v4.0: First check if any operator has 'invited' status (needs onboarding)
  /// Legacy fallback: check status field
  bool get isOnboarding {
    // v4.0: Check if any operator is in invited state (needs onboarding confirmation)
    if (operators.isNotEmpty) {
      return operators.any((op) => op.isInvited);
    }
    // Legacy fallback
    return status == DriverStatus.onboarding;
  }

  /// Check if driver has completed onboarding before (has active operators)
  /// Used to determine if we should skip steps when joining new operator
  bool get hasCompletedOnboardingBefore => hasActiveOperators;

  factory DriverUser.fromJson(Map<String, dynamic> json) {
    // Parse operators array if present (new format)
    final operatorsList = (json['operators'] as List<dynamic>?)
        ?.map((op) => OperatorAccess.fromJson(op as Map<String, dynamic>))
        .toList() ?? [];

    return DriverUser(
      driverId: json['driverId'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      operators: operatorsList,
      activeOperator: json['activeOperator'] as String?,
      // Legacy fields (backward compatibility)
      tenantId: json['tenantId'] as String?,
      status: json['status'] != null
          ? DriverStatus.fromString(json['status'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'driverId': driverId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'operators': operators.map((op) => op.toJson()).toList(),
      'activeOperator': activeOperator,
      // Legacy fields
      if (tenantId != null) 'tenantId': tenantId,
      if (status != null) 'status': status!.value,
    };
  }

  DriverUser copyWith({
    String? driverId,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    List<OperatorAccess>? operators,
    String? activeOperator,
    String? tenantId,
    DriverStatus? status,
  }) {
    return DriverUser(
      driverId: driverId ?? this.driverId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      operators: operators ?? this.operators,
      activeOperator: activeOperator ?? this.activeOperator,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
    );
  }

  /// Switch to a different active operator
  DriverUser switchOperator(String newOperatorId) {
    if (!hasAccessTo(newOperatorId)) {
      throw ArgumentError('No access to operator: $newOperatorId');
    }
    return copyWith(activeOperator: newOperatorId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DriverUser) return false;

    return other.driverId == driverId &&
        other.email == email &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.phone == phone &&
        other.activeOperator == activeOperator &&
        _listEquals(other.operators, operators);
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      driverId,
      email,
      firstName,
      lastName,
      phone,
      activeOperator,
      Object.hashAll(operators),
    );
  }
}

/// Operator access entry from JWT
/// Represents a driver's relationship with a single operator
class OperatorAccess {
  final String tenantId;
  final String status; // 'active', 'invited', 'revoked'
  final List<String> scopes;

  const OperatorAccess({
    required this.tenantId,
    required this.status,
    this.scopes = const ['profile', 'documents', 'vehicles', 'availability'],
  });

  bool get isActive => status == 'active';
  bool get isInvited => status == 'invited';
  bool get isRevoked => status == 'revoked';

  factory OperatorAccess.fromJson(Map<String, dynamic> json) {
    return OperatorAccess(
      tenantId: json['tenantId'] as String,
      status: json['status'] as String,
      scopes: (json['scopes'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList() ?? ['profile', 'documents', 'vehicles', 'availability'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'status': status,
      'scopes': scopes,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OperatorAccess) return false;

    return other.tenantId == tenantId &&
        other.status == status &&
        DriverUser._listEquals(other.scopes, scopes);
  }

  @override
  int get hashCode => Object.hash(tenantId, status, Object.hashAll(scopes));
}

/// Driver status enum (legacy - kept for backward compatibility)
@Deprecated('Use OperatorAccess.status for per-operator status')
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
