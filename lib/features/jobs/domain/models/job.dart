/// Driver job model + lifecycle state machine.
///
/// Mirrors the driver-jobs API contract. Money (`fare`) is an integer in
/// minor units (pence). The `status` field is the DRIVER lifecycle status
/// (`driverStatus` server-side), not the ops workflow status.

/// Driver-facing job lifecycle status.
///
/// State machine (must match the backend exactly):
///   offered -> accepted -> en_route -> arrived -> picked_up -> completed
/// plus `declined` (from offered) and `cancelled` (ops-driven, any non-terminal).
enum DriverJobStatus {
  offered('offered', 'Offered'),
  accepted('accepted', 'Accepted'),
  enRoute('en_route', 'En route'),
  arrived('arrived', 'Arrived'),
  pickedUp('picked_up', 'Passenger on board'),
  completed('completed', 'Completed'),
  declined('declined', 'Declined'),
  cancelled('cancelled', 'Cancelled');

  final String apiValue;
  final String displayName;

  const DriverJobStatus(this.apiValue, this.displayName);

  static DriverJobStatus fromApiValue(String? value) {
    final normalized = (value ?? 'offered').toLowerCase();
    return DriverJobStatus.values.firstWhere(
      (e) => e.apiValue == normalized,
      orElse: () => DriverJobStatus.offered,
    );
  }

  /// Terminal statuses cannot transition further.
  bool get isTerminal =>
      this == DriverJobStatus.completed ||
      this == DriverJobStatus.declined ||
      this == DriverJobStatus.cancelled;

  /// A job that has been accepted but not yet completed/cancelled.
  bool get isActive =>
      this == DriverJobStatus.accepted ||
      this == DriverJobStatus.enRoute ||
      this == DriverJobStatus.arrived ||
      this == DriverJobStatus.pickedUp;

  /// The single legal next status advance via POST /status, or null if none.
  ///
  /// This mirrors the backend's `accepted->en_route->arrived->picked_up->
  /// completed` chain. `offered` advances only via accept/decline (not this
  /// endpoint), so it returns null here.
  DriverJobStatus? get nextStatus {
    return switch (this) {
      DriverJobStatus.accepted => DriverJobStatus.enRoute,
      DriverJobStatus.enRoute => DriverJobStatus.arrived,
      DriverJobStatus.arrived => DriverJobStatus.pickedUp,
      DriverJobStatus.pickedUp => DriverJobStatus.completed,
      _ => null,
    };
  }

  /// Whether the advance to [target] is a legal transition. Used to reject
  /// illegal transitions client-side before hitting the API (which also
  /// enforces this and returns 409 on violation).
  bool canAdvanceTo(DriverJobStatus target) => nextStatus == target;

  /// Call-to-action label for advancing from this status.
  String? get advanceLabel {
    return switch (this) {
      DriverJobStatus.accepted => 'Start journey to pickup',
      DriverJobStatus.enRoute => 'Arrived at pickup',
      DriverJobStatus.arrived => 'Passenger picked up',
      DriverJobStatus.pickedUp => 'Complete job',
      _ => null,
    };
  }

  /// Whether the driver should be sending live location while in this status.
  bool get requiresLocationTracking =>
      this == DriverJobStatus.enRoute || this == DriverJobStatus.arrived;
}

/// A single driver job.
class Job {
  final String jobId;
  final String? bookingId;
  final DriverJobStatus status;
  final String pickupAddress;
  final String dropoffAddress;
  final String? scheduledTime;
  final String? vehicleType;

  /// Fare in pence (minor units).
  final int fare;
  final String? notes;
  final String? driverStatusUpdatedAt;
  final String? createdAt;

  const Job({
    required this.jobId,
    this.bookingId,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.scheduledTime,
    this.vehicleType,
    this.fare = 0,
    this.notes,
    this.driverStatusUpdatedAt,
    this.createdAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['jobId'] as String,
      bookingId: json['bookingId'] as String?,
      status: DriverJobStatus.fromApiValue(json['status'] as String?),
      pickupAddress: json['pickupAddress'] as String? ?? '',
      dropoffAddress: json['dropoffAddress'] as String? ?? '',
      scheduledTime: json['scheduledTime'] as String?,
      vehicleType: json['vehicleType'] as String?,
      // Fare is integer pence. Tolerate a numeric value arriving as num.
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      driverStatusUpdatedAt: json['driverStatusUpdatedAt'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Parsed scheduled time, or null if absent/invalid.
  DateTime? get scheduledDateTime {
    if (scheduledTime == null) return null;
    return DateTime.tryParse(scheduledTime!);
  }

  Job copyWith({DriverJobStatus? status, String? driverStatusUpdatedAt}) {
    return Job(
      jobId: jobId,
      bookingId: bookingId,
      status: status ?? this.status,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      scheduledTime: scheduledTime,
      vehicleType: vehicleType,
      fare: fare,
      notes: notes,
      driverStatusUpdatedAt: driverStatusUpdatedAt ?? this.driverStatusUpdatedAt,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Job && other.jobId == jobId;
  }

  @override
  int get hashCode => jobId.hashCode;
}
