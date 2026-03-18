import '../../../config/api_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/models/availability_block.dart';
import '../domain/models/working_pattern.dart';

/// Repository for driver availability API calls
class AvailabilityRepository {
  final DioClient _dioClient;

  AvailabilityRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// Get driver availability for a date range
  ///
  /// Returns working pattern and availability blocks.
  /// If no dates provided, API defaults to current week.
  Future<AvailabilityResponse> getAvailability({
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await _dioClient.dio.get(
      ApiConfig.availability,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data as Map<String, dynamic>;
    return AvailabilityResponse.fromJson(data);
  }

  /// Get availability for 12 months ahead (for calendar view)
  Future<AvailabilityResponse> getYearAvailability() async {
    final now = DateTime.now();
    final startDate = _formatDate(now);
    final endDate = _formatDate(DateTime(now.year + 1, now.month, now.day));

    return getAvailability(startDate: startDate, endDate: endDate);
  }

  /// Add or update an availability block
  Future<AvailabilityBlock> saveAvailabilityBlock({
    required String date,
    required String startTime,
    required String endTime,
    bool available = false,
    String? note,
    String? blockId,
  }) async {
    final response = await _dioClient.dio.put(
      ApiConfig.availability,
      data: {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'available': available,
        if (note != null) 'note': note,
        if (blockId != null) 'blockId': blockId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final blockData = data['block'] as Map<String, dynamic>;
    return AvailabilityBlock.fromJson(blockData);
  }

  /// Block all day for a specific date
  Future<AvailabilityBlock> blockAllDay({
    required String date,
    String? note,
  }) async {
    return saveAvailabilityBlock(
      date: date,
      startTime: '00:00',
      endTime: '23:59',
      available: false,
      note: note,
    );
  }

  /// Block a time range on a specific date
  Future<AvailabilityBlock> blockTimeRange({
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    return saveAvailabilityBlock(
      date: date,
      startTime: startTime,
      endTime: endTime,
      available: false,
      note: note,
    );
  }

  /// Delete an availability block
  ///
  /// Note: The API currently doesn't have a delete endpoint.
  /// Blocks can be "removed" by setting available=true for now.
  /// This is a placeholder for when the API supports deletion.
  Future<void> deleteBlock(String blockId) async {
    // TODO: Implement when API supports block deletion
    // For now, we can't truly delete blocks - they need to be marked as available
    throw UnimplementedError(
      'Block deletion not yet supported by API. '
      'Consider marking the block as available instead.',
    );
  }

  /// Format DateTime to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Response from availability API
class AvailabilityResponse {
  final String driverId;
  final WorkingPattern defaultPattern;
  final List<AvailabilityBlock> blocks;

  const AvailabilityResponse({
    required this.driverId,
    required this.defaultPattern,
    required this.blocks,
  });

  factory AvailabilityResponse.fromJson(Map<String, dynamic> json) {
    // Handle API response format:
    // { success: true, driverId: "...", defaultPattern: {...}, blocks: [...] }
    final patternData = json['defaultPattern'] as Map<String, dynamic>? ?? {};
    final blocksData = json['blocks'] as List<dynamic>? ?? [];

    return AvailabilityResponse(
      driverId: json['driverId'] as String? ?? '',
      defaultPattern: WorkingPattern.fromJson(patternData),
      blocks: blocksData
          .map((b) => AvailabilityBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get blocks for a specific date
  List<AvailabilityBlock> blocksForDate(DateTime date) {
    return blocks.where((b) => b.isForDate(date)).toList();
  }

  /// Check if a specific date is blocked (all day)
  bool isDateFullyBlocked(DateTime date) {
    final dayBlocks = blocksForDate(date);
    return dayBlocks.any((b) => !b.available && b.isAllDay);
  }

  /// Get availability state for a specific date
  DayAvailabilityState getDayState(DateTime date) {
    final isWorkingDay = defaultPattern.isWorkingDay(date);
    final dayBlocks = blocksForDate(date);

    return DayAvailabilityState(
      date: date,
      isWorkingDay: isWorkingDay,
      blocks: dayBlocks,
      bookingIds: const [], // TODO: Add bookings when API supports it
    );
  }
}
