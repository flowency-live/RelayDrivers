/// Vehicle model representing a driver's vehicle
class Vehicle {
  final String vrn;
  final String? make;
  final String? model;
  final String? colour;
  final String? vehicleType;
  final int? passengerCapacity;
  final String? taxStatus;
  final String? taxDueDate;
  final String? motStatus;
  final String? motExpiryDate;
  final String complianceStatus;
  final List<String> complianceAlerts;
  final bool canOperate;
  final String? lastApiCheck;
  final String? createdAt;

  const Vehicle({
    required this.vrn,
    this.make,
    this.model,
    this.colour,
    this.vehicleType,
    this.passengerCapacity,
    this.taxStatus,
    this.taxDueDate,
    this.motStatus,
    this.motExpiryDate,
    this.complianceStatus = 'unknown',
    this.complianceAlerts = const [],
    this.canOperate = false,
    this.lastApiCheck,
    this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vrn: json['vrn'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      colour: json['colour'] as String?,
      vehicleType: json['vehicleType'] as String?,
      passengerCapacity: json['passengerCapacity'] as int?,
      taxStatus: json['taxStatus'] as String?,
      taxDueDate: json['taxDueDate'] as String?,
      motStatus: json['motStatus'] as String?,
      motExpiryDate: json['motExpiryDate'] as String?,
      complianceStatus: json['complianceStatus'] as String? ?? 'unknown',
      complianceAlerts: (json['complianceAlerts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      canOperate: json['canOperate'] as bool? ?? false,
      lastApiCheck: json['lastApiCheck'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vrn': vrn,
      if (make != null) 'make': make,
      if (model != null) 'model': model,
      if (colour != null) 'colour': colour,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (passengerCapacity != null) 'passengerCapacity': passengerCapacity,
      if (taxStatus != null) 'taxStatus': taxStatus,
      if (taxDueDate != null) 'taxDueDate': taxDueDate,
      if (motStatus != null) 'motStatus': motStatus,
      if (motExpiryDate != null) 'motExpiryDate': motExpiryDate,
      'complianceStatus': complianceStatus,
      'complianceAlerts': complianceAlerts,
      'canOperate': canOperate,
      if (lastApiCheck != null) 'lastApiCheck': lastApiCheck,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Get display name (make and model or just VRN)
  String get displayName {
    if (make != null && model != null) {
      return '$make $model';
    }
    if (make != null) {
      return make!;
    }
    return vrn;
  }

  /// Check if MOT is expiring soon (within 30 days)
  bool get isMotExpiringSoon {
    if (motExpiryDate == null) return false;
    try {
      final expiry = DateTime.parse(motExpiryDate!);
      final daysUntilExpiry = expiry.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if MOT is expired
  bool get isMotExpired {
    if (motExpiryDate == null) return false;
    try {
      final expiry = DateTime.parse(motExpiryDate!);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Check if tax is expiring soon (within 30 days)
  bool get isTaxExpiringSoon {
    if (taxDueDate == null) return false;
    try {
      final expiry = DateTime.parse(taxDueDate!);
      final daysUntilExpiry = expiry.difference(DateTime.now()).inDays;
      return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if tax is expired/due
  bool get isTaxExpired {
    if (taxDueDate == null) return false;
    try {
      final expiry = DateTime.parse(taxDueDate!);
      return expiry.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Vehicle copyWith({
    String? vrn,
    String? make,
    String? model,
    String? colour,
    String? vehicleType,
    int? passengerCapacity,
    String? taxStatus,
    String? taxDueDate,
    String? motStatus,
    String? motExpiryDate,
    String? complianceStatus,
    List<String>? complianceAlerts,
    bool? canOperate,
    String? lastApiCheck,
    String? createdAt,
  }) {
    return Vehicle(
      vrn: vrn ?? this.vrn,
      make: make ?? this.make,
      model: model ?? this.model,
      colour: colour ?? this.colour,
      vehicleType: vehicleType ?? this.vehicleType,
      passengerCapacity: passengerCapacity ?? this.passengerCapacity,
      taxStatus: taxStatus ?? this.taxStatus,
      taxDueDate: taxDueDate ?? this.taxDueDate,
      motStatus: motStatus ?? this.motStatus,
      motExpiryDate: motExpiryDate ?? this.motExpiryDate,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      complianceAlerts: complianceAlerts ?? this.complianceAlerts,
      canOperate: canOperate ?? this.canOperate,
      lastApiCheck: lastApiCheck ?? this.lastApiCheck,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.vrn == vrn;
  }

  @override
  int get hashCode => vrn.hashCode;
}

/// DVLA lookup result before confirming vehicle addition
class DvlaLookupResult {
  final String vrn;
  final String? make;
  final String? model;
  final String? colour;
  final String? vehicleType;
  final String? taxStatus;
  final String? taxDueDate;
  final String? motStatus;
  final String? motExpiryDate;

  const DvlaLookupResult({
    required this.vrn,
    this.make,
    this.model,
    this.colour,
    this.vehicleType,
    this.taxStatus,
    this.taxDueDate,
    this.motStatus,
    this.motExpiryDate,
  });

  factory DvlaLookupResult.fromJson(Map<String, dynamic> json) {
    return DvlaLookupResult(
      vrn: json['vrn'] as String,
      make: json['make'] as String?,
      model: json['model'] as String?,
      colour: json['colour'] as String?,
      vehicleType: json['vehicleType'] as String?,
      taxStatus: json['taxStatus'] as String?,
      taxDueDate: json['taxDueDate'] as String?,
      motStatus: json['motStatus'] as String?,
      motExpiryDate: json['motExpiryDate'] as String?,
    );
  }
}
