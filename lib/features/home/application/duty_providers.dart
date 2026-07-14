import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../calendar/application/calendar_providers.dart';

/// Driver on/off-duty state, backed by the availability API.
///
/// See [AvailabilityRepository.setDutyForToday] for how duty maps onto the
/// availability contract (there is no dedicated presence endpoint yet).
sealed class DutyState {
  const DutyState();
}

class DutyUnknown extends DutyState {
  const DutyUnknown();
}

class DutyLoading extends DutyState {
  /// The last-known on-duty value shown while a change is in flight, so the
  /// toggle does not flicker.
  final bool previous;
  const DutyLoading(this.previous);
}

class DutyReady extends DutyState {
  final bool onDuty;
  const DutyReady(this.onDuty);
}

class DutyErrorState extends DutyState {
  final String message;
  final bool previous;
  const DutyErrorState(this.message, this.previous);
}

class DutyNotifier extends StateNotifier<DutyState> {
  final Ref _ref;

  DutyNotifier(this._ref) : super(const DutyUnknown());

  bool get _currentValue {
    final s = state;
    if (s is DutyReady) return s.onDuty;
    if (s is DutyLoading) return s.previous;
    if (s is DutyErrorState) return s.previous;
    return false;
  }

  /// Load the current duty state from the backend.
  Future<void> load() async {
    state = DutyLoading(_currentValue);
    try {
      final onDuty =
          await _ref.read(availabilityRepositoryProvider).getDutyForToday();
      state = DutyReady(onDuty);
    } catch (e) {
      state = DutyErrorState(_parse(e), _currentValue);
    }
  }

  /// Toggle duty state and persist it. Optimistically flips, reverts on error.
  Future<void> toggle() async {
    final target = !_currentValue;
    state = DutyLoading(target);
    try {
      await _ref.read(availabilityRepositoryProvider).setDutyForToday(target);
      state = DutyReady(target);
    } catch (e) {
      state = DutyErrorState(_parse(e), !target);
    }
  }

  String _parse(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Could not update duty status. Please try again.';
  }
}

/// Duty state provider.
final dutyStateProvider =
    StateNotifierProvider<DutyNotifier, DutyState>((ref) {
  return DutyNotifier(ref);
});

/// Convenience: is the driver currently on duty?
final isOnDutyProvider = Provider<bool>((ref) {
  final state = ref.watch(dutyStateProvider);
  return switch (state) {
    DutyReady(:final onDuty) => onDuty,
    DutyLoading(:final previous) => previous,
    DutyErrorState(:final previous) => previous,
    DutyUnknown() => false,
  };
});

/// Convenience: is a duty change in flight?
final isDutyLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dutyStateProvider) is DutyLoading;
});
