/// A time block indicating driver availability/unavailability
///
/// Used to override the default working pattern for specific dates/times.
/// When available=false, the driver is blocked for that period.
class AvailabilityBlock {
  /// Unique identifier for this block
  final String blockId;

  /// Date in YYYY-MM-DD format
  final String date;

  /// Start time in HH:MM format (24-hour)
  final String startTime;

  /// End time in HH:MM format (24-hour)
  final String endTime;

  /// Whether driver is available (false = blocked)
  final bool available;

  /// Optional note explaining the block
  final String? note;

  /// Who created this block ('driver' or 'admin')
  final String? createdBy;

  /// When this block was created
  final String? createdAt;

  const AvailabilityBlock({
    required this.blockId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.available = false,
    this.note,
    this.createdBy,
    this.createdAt,
  });

  factory AvailabilityBlock.fromJson(Map<String, dynamic> json) {
    return AvailabilityBlock(
      blockId: json['blockId'] as String,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      available: json['available'] as bool? ?? false,
      note: json['note'] as String?,
      createdBy: json['createdBy'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blockId': blockId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'available': available,
      if (note != null) 'note': note,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Parse date string to DateTime
  DateTime get dateTime => DateTime.parse(date);

  /// Check if this is an all-day block
  bool get isAllDay => startTime == '00:00' && endTime == '23:59';

  /// Check if this block is for a specific date
  bool isForDate(DateTime targetDate) {
    final blockDate = dateTime;
    return blockDate.year == targetDate.year &&
        blockDate.month == targetDate.month &&
        blockDate.day == targetDate.day;
  }

  /// Format for display (e.g., "Mar 19")
  String get formattedDate {
    final dt = dateTime;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  /// Format time range for display
  String get formattedTimeRange {
    if (isAllDay) return 'All day';
    return '$startTime - $endTime';
  }

  /// Create a new block for blocking time off
  factory AvailabilityBlock.blockTimeOff({
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) {
    return AvailabilityBlock(
      blockId: 'block-${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      startTime: startTime,
      endTime: endTime,
      available: false,
      note: note,
      createdBy: 'driver',
    );
  }

  /// Create an all-day block
  factory AvailabilityBlock.allDayBlock({
    required String date,
    String? note,
  }) {
    return AvailabilityBlock.blockTimeOff(
      date: date,
      startTime: '00:00',
      endTime: '23:59',
      note: note,
    );
  }

  AvailabilityBlock copyWith({
    String? blockId,
    String? date,
    String? startTime,
    String? endTime,
    bool? available,
    String? note,
    String? createdBy,
    String? createdAt,
  }) {
    return AvailabilityBlock(
      blockId: blockId ?? this.blockId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      available: available ?? this.available,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailabilityBlock && other.blockId == blockId;
  }

  @override
  int get hashCode => blockId.hashCode;
}

/// State for a single day on the calendar
class DayAvailabilityState {
  /// The date
  final DateTime date;

  /// Whether this is a working day (from default pattern)
  final bool isWorkingDay;

  /// Blocks for this day
  final List<AvailabilityBlock> blocks;

  /// Booking IDs for this day (if any)
  final List<String> bookingIds;

  const DayAvailabilityState({
    required this.date,
    this.isWorkingDay = true,
    this.blocks = const [],
    this.bookingIds = const [],
  });

  /// Check if day is fully blocked
  bool get isFullyBlocked => blocks.any((b) => !b.available && b.isAllDay);

  /// Check if day has any blocks
  bool get hasBlocks => blocks.isNotEmpty;

  /// Check if day has bookings
  bool get hasBookings => bookingIds.isNotEmpty;

  /// Get the availability status for display
  DayStatus get status {
    if (!isWorkingDay) return DayStatus.notWorking;
    if (isFullyBlocked) return DayStatus.blocked;
    if (hasBookings) return DayStatus.hasBooking;
    if (hasBlocks) return DayStatus.partiallyBlocked;
    return DayStatus.available;
  }

  DayAvailabilityState copyWith({
    DateTime? date,
    bool? isWorkingDay,
    List<AvailabilityBlock>? blocks,
    List<String>? bookingIds,
  }) {
    return DayAvailabilityState(
      date: date ?? this.date,
      isWorkingDay: isWorkingDay ?? this.isWorkingDay,
      blocks: blocks ?? this.blocks,
      bookingIds: bookingIds ?? this.bookingIds,
    );
  }
}

/// Status types for calendar day display
enum DayStatus {
  /// Available for bookings
  available,

  /// Has one or more bookings
  hasBooking,

  /// Fully blocked (unavailable all day)
  blocked,

  /// Partially blocked (some hours unavailable)
  partiallyBlocked,

  /// Not a working day (weekend, etc.)
  notWorking,
}
