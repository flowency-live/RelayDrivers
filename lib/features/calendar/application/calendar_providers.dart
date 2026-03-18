import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/availability_block.dart';
import '../domain/models/working_pattern.dart';
import '../infrastructure/availability_repository.dart';

/// Availability repository provider
final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AvailabilityRepository(dioClient: dioClient);
});

/// Calendar state
sealed class CalendarState {
  const CalendarState();
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  final WorkingPattern workingPattern;
  final List<AvailabilityBlock> blocks;
  final DateTime viewingMonth;

  const CalendarLoaded({
    required this.workingPattern,
    required this.blocks,
    required this.viewingMonth,
  });

  /// Get blocks for a specific date
  List<AvailabilityBlock> blocksForDate(DateTime date) {
    return blocks.where((b) => b.isForDate(date)).toList();
  }

  /// Check if a date is fully blocked
  bool isDateFullyBlocked(DateTime date) {
    return blocksForDate(date).any((b) => !b.available && b.isAllDay);
  }

  /// Get day state for a specific date
  DayAvailabilityState getDayState(DateTime date) {
    return DayAvailabilityState(
      date: date,
      isWorkingDay: workingPattern.isWorkingDay(date),
      blocks: blocksForDate(date),
      bookingIds: const [], // TODO: Add bookings
    );
  }

  /// Copy with new values
  CalendarLoaded copyWith({
    WorkingPattern? workingPattern,
    List<AvailabilityBlock>? blocks,
    DateTime? viewingMonth,
  }) {
    return CalendarLoaded(
      workingPattern: workingPattern ?? this.workingPattern,
      blocks: blocks ?? this.blocks,
      viewingMonth: viewingMonth ?? this.viewingMonth,
    );
  }
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
}

class CalendarSaving extends CalendarState {
  final WorkingPattern workingPattern;
  final List<AvailabilityBlock> blocks;
  final DateTime viewingMonth;

  const CalendarSaving({
    required this.workingPattern,
    required this.blocks,
    required this.viewingMonth,
  });
}

/// Calendar notifier
class CalendarNotifier extends StateNotifier<CalendarState> {
  final AvailabilityRepository _repository;

  CalendarNotifier({required AvailabilityRepository repository})
      : _repository = repository,
        super(const CalendarInitial());

  /// Load availability data
  Future<void> loadAvailability() async {
    state = const CalendarLoading();

    try {
      final response = await _repository.getYearAvailability();
      state = CalendarLoaded(
        workingPattern: response.defaultPattern,
        blocks: response.blocks,
        viewingMonth: DateTime.now(),
      );
    } catch (e) {
      state = CalendarError(_parseError(e));
    }
  }

  /// Change the viewing month
  void setViewingMonth(DateTime month) {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      state = currentState.copyWith(viewingMonth: month);
    }
  }

  /// Go to previous month
  void previousMonth() {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final current = currentState.viewingMonth;
      state = currentState.copyWith(
        viewingMonth: DateTime(current.year, current.month - 1),
      );
    }
  }

  /// Go to next month
  void nextMonth() {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final current = currentState.viewingMonth;
      state = currentState.copyWith(
        viewingMonth: DateTime(current.year, current.month + 1),
      );
    }
  }

  /// Block all day for a specific date
  Future<bool> blockAllDay({
    required String date,
    String? note,
  }) async {
    return _saveBlock(
      date: date,
      startTime: '00:00',
      endTime: '23:59',
      note: note,
    );
  }

  /// Block a time range
  Future<bool> blockTimeRange({
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    return _saveBlock(
      date: date,
      startTime: startTime,
      endTime: endTime,
      note: note,
    );
  }

  /// Save a block (internal)
  Future<bool> _saveBlock({
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    final currentState = state;
    if (currentState is! CalendarLoaded) return false;

    state = CalendarSaving(
      workingPattern: currentState.workingPattern,
      blocks: currentState.blocks,
      viewingMonth: currentState.viewingMonth,
    );

    try {
      final newBlock = await _repository.saveAvailabilityBlock(
        date: date,
        startTime: startTime,
        endTime: endTime,
        available: false,
        note: note,
      );

      state = CalendarLoaded(
        workingPattern: currentState.workingPattern,
        blocks: [...currentState.blocks, newBlock],
        viewingMonth: currentState.viewingMonth,
      );
      return true;
    } catch (e) {
      state = CalendarLoaded(
        workingPattern: currentState.workingPattern,
        blocks: currentState.blocks,
        viewingMonth: currentState.viewingMonth,
      );
      return false;
    }
  }

  /// Remove a block (mark as available)
  Future<bool> removeBlock(String blockId) async {
    final currentState = state;
    if (currentState is! CalendarLoaded) return false;

    // Find the block to get its date and times
    final block = currentState.blocks.firstWhere(
      (b) => b.blockId == blockId,
      orElse: () => throw Exception('Block not found'),
    );

    state = CalendarSaving(
      workingPattern: currentState.workingPattern,
      blocks: currentState.blocks,
      viewingMonth: currentState.viewingMonth,
    );

    try {
      // Save with available=true to effectively remove the block
      await _repository.saveAvailabilityBlock(
        date: block.date,
        startTime: block.startTime,
        endTime: block.endTime,
        available: true, // Mark as available to "remove" the block
        blockId: blockId,
      );

      // Remove from local state
      final updatedBlocks = currentState.blocks
          .where((b) => b.blockId != blockId)
          .toList();

      state = CalendarLoaded(
        workingPattern: currentState.workingPattern,
        blocks: updatedBlocks,
        viewingMonth: currentState.viewingMonth,
      );
      return true;
    } catch (e) {
      state = CalendarLoaded(
        workingPattern: currentState.workingPattern,
        blocks: currentState.blocks,
        viewingMonth: currentState.viewingMonth,
      );
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Calendar state provider
final calendarStateProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final repository = ref.watch(availabilityRepositoryProvider);
  return CalendarNotifier(repository: repository);
});

/// Provider for the current viewing month
final viewingMonthProvider = Provider<DateTime>((ref) {
  final state = ref.watch(calendarStateProvider);
  if (state is CalendarLoaded) return state.viewingMonth;
  if (state is CalendarSaving) return state.viewingMonth;
  return DateTime.now();
});

/// Provider for the working pattern
final workingPatternProvider = Provider<WorkingPattern>((ref) {
  final state = ref.watch(calendarStateProvider);
  if (state is CalendarLoaded) return state.workingPattern;
  if (state is CalendarSaving) return state.workingPattern;
  return WorkingPattern.empty();
});

/// Provider for all availability blocks
final availabilityBlocksProvider = Provider<List<AvailabilityBlock>>((ref) {
  final state = ref.watch(calendarStateProvider);
  if (state is CalendarLoaded) return state.blocks;
  if (state is CalendarSaving) return state.blocks;
  return [];
});

/// Provider for blocks on the current viewing month
final monthBlocksProvider = Provider<List<AvailabilityBlock>>((ref) {
  final blocks = ref.watch(availabilityBlocksProvider);
  final viewingMonth = ref.watch(viewingMonthProvider);

  return blocks.where((block) {
    final blockDate = block.dateTime;
    return blockDate.year == viewingMonth.year &&
        blockDate.month == viewingMonth.month;
  }).toList();
});

/// Provider for checking if calendar is loading
final calendarIsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(calendarStateProvider);
  return state is CalendarLoading;
});

/// Provider for checking if calendar is saving
final calendarIsSavingProvider = Provider<bool>((ref) {
  final state = ref.watch(calendarStateProvider);
  return state is CalendarSaving;
});
