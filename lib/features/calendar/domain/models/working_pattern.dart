/// Days of the week as used by the API
enum Weekday {
  monday('monday', 'Mon', 'Monday'),
  tuesday('tuesday', 'Tue', 'Tuesday'),
  wednesday('wednesday', 'Wed', 'Wednesday'),
  thursday('thursday', 'Thu', 'Thursday'),
  friday('friday', 'Fri', 'Friday'),
  saturday('saturday', 'Sat', 'Saturday'),
  sunday('sunday', 'Sun', 'Sunday');

  final String value;
  final String shortName;
  final String fullName;

  const Weekday(this.value, this.shortName, this.fullName);

  /// Convert to DateTime.weekday value (1 = Monday, 7 = Sunday)
  int get dateTimeWeekday {
    switch (this) {
      case Weekday.monday:
        return 1;
      case Weekday.tuesday:
        return 2;
      case Weekday.wednesday:
        return 3;
      case Weekday.thursday:
        return 4;
      case Weekday.friday:
        return 5;
      case Weekday.saturday:
        return 6;
      case Weekday.sunday:
        return 7;
    }
  }

  /// Create from string value (API format)
  static Weekday fromString(String value) {
    return Weekday.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => Weekday.monday,
    );
  }

  /// Create from DateTime.weekday value
  static Weekday fromDateTime(DateTime date) {
    switch (date.weekday) {
      case 1:
        return Weekday.monday;
      case 2:
        return Weekday.tuesday;
      case 3:
        return Weekday.wednesday;
      case 4:
        return Weekday.thursday;
      case 5:
        return Weekday.friday;
      case 6:
        return Weekday.saturday;
      case 7:
        return Weekday.sunday;
      default:
        throw ArgumentError('Invalid weekday: ${date.weekday}');
    }
  }
}

/// Driver's default working pattern
///
/// Defines which days and hours the driver is typically available.
/// Individual availability blocks override this pattern for specific dates.
class WorkingPattern {
  /// Days the driver normally works
  final List<Weekday> workingDays;

  /// Start time in HH:MM format (24-hour)
  final String? workingHoursStart;

  /// End time in HH:MM format (24-hour)
  final String? workingHoursEnd;

  const WorkingPattern({
    this.workingDays = const [],
    this.workingHoursStart,
    this.workingHoursEnd,
  });

  factory WorkingPattern.fromJson(Map<String, dynamic> json) {
    return WorkingPattern(
      workingDays: (json['workingDays'] as List<dynamic>?)
              ?.map((e) => Weekday.fromString(e as String))
              .toList() ??
          const [],
      workingHoursStart: json['workingHoursStart'] as String?,
      workingHoursEnd: json['workingHoursEnd'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workingDays': workingDays.map((d) => d.value).toList(),
      if (workingHoursStart != null) 'workingHoursStart': workingHoursStart,
      if (workingHoursEnd != null) 'workingHoursEnd': workingHoursEnd,
    };
  }

  /// Check if a specific day is a working day
  bool isWorkingDay(DateTime date) {
    final weekday = Weekday.fromDateTime(date);
    return workingDays.contains(weekday);
  }

  /// Check if pattern has working hours set
  bool get hasWorkingHours =>
      workingHoursStart != null && workingHoursEnd != null;

  /// Format working hours for display (e.g., "09:00 - 18:00")
  String get formattedHours {
    if (!hasWorkingHours) return 'Not set';
    return '$workingHoursStart - $workingHoursEnd';
  }

  /// Format working days for display (e.g., "Mon-Fri")
  String get formattedDays {
    if (workingDays.isEmpty) return 'No days set';

    // Check for common patterns
    final hasMonFri = workingDays.length == 5 &&
        workingDays.contains(Weekday.monday) &&
        workingDays.contains(Weekday.tuesday) &&
        workingDays.contains(Weekday.wednesday) &&
        workingDays.contains(Weekday.thursday) &&
        workingDays.contains(Weekday.friday) &&
        !workingDays.contains(Weekday.saturday) &&
        !workingDays.contains(Weekday.sunday);

    if (hasMonFri) return 'Mon-Fri';

    final hasAllDays = workingDays.length == 7;
    if (hasAllDays) return 'Every day';

    // Return abbreviated list
    return workingDays.map((d) => d.shortName).join(', ');
  }

  /// Create default Mon-Fri 9-6 pattern
  factory WorkingPattern.defaultPattern() => const WorkingPattern(
        workingDays: [
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        ],
        workingHoursStart: '09:00',
        workingHoursEnd: '18:00',
      );

  /// Create empty pattern (no working days set)
  factory WorkingPattern.empty() => const WorkingPattern();

  WorkingPattern copyWith({
    List<Weekday>? workingDays,
    String? workingHoursStart,
    String? workingHoursEnd,
  }) {
    return WorkingPattern(
      workingDays: workingDays ?? this.workingDays,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WorkingPattern) return false;
    return _listEquals(workingDays, other.workingDays) &&
        workingHoursStart == other.workingHoursStart &&
        workingHoursEnd == other.workingHoursEnd;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(workingDays),
        workingHoursStart,
        workingHoursEnd,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
