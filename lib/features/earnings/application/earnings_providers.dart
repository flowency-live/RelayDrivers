import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/earnings.dart';
import '../infrastructure/earnings_repository.dart';

/// Earnings repository provider.
final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return EarningsRepository(dioClient: dioClient);
});

/// Selectable date ranges for the earnings screen.
enum EarningsRange {
  thisWeek('This week'),
  thisMonth('This month'),
  lastMonth('Last month'),
  last30Days('Last 30 days');

  final String label;
  const EarningsRange(this.label);

  /// Resolve to an inclusive (from, to) pair as YYYY-MM-DD strings.
  ({String from, String to}) resolve([DateTime? now]) {
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    switch (this) {
      case EarningsRange.thisWeek:
        // Monday as start of week.
        final start = day.subtract(Duration(days: day.weekday - 1));
        return (from: _fmt(start), to: _fmt(day));
      case EarningsRange.thisMonth:
        final start = DateTime(day.year, day.month, 1);
        return (from: _fmt(start), to: _fmt(day));
      case EarningsRange.lastMonth:
        final start = DateTime(day.year, day.month - 1, 1);
        final end = DateTime(day.year, day.month, 0); // last day of prev month
        return (from: _fmt(start), to: _fmt(end));
      case EarningsRange.last30Days:
        final start = day.subtract(const Duration(days: 29));
        return (from: _fmt(start), to: _fmt(day));
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Currently selected range.
final earningsRangeProvider =
    StateProvider<EarningsRange>((ref) => EarningsRange.thisWeek);

/// Earnings state.
sealed class EarningsState {
  const EarningsState();
}

class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

class EarningsLoaded extends EarningsState {
  final EarningsSummary summary;
  const EarningsLoaded(this.summary);
}

class EarningsErrorState extends EarningsState {
  final String message;
  const EarningsErrorState(this.message);
}

/// Earnings notifier - loads the summary for a given range.
class EarningsNotifier extends StateNotifier<EarningsState> {
  final EarningsRepository _repository;

  EarningsNotifier({required EarningsRepository repository})
      : _repository = repository,
        super(const EarningsInitial());

  Future<void> load(EarningsRange range) async {
    state = const EarningsLoading();
    try {
      final resolved = range.resolve();
      final summary = await _repository.getEarnings(
        from: resolved.from,
        to: resolved.to,
      );
      state = EarningsLoaded(summary);
    } catch (e) {
      state = EarningsErrorState(_parseError(e));
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Earnings state provider.
final earningsStateProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>((ref) {
  final repository = ref.watch(earningsRepositoryProvider);
  return EarningsNotifier(repository: repository);
});

/// Today's earnings, used by the home dashboard card. Loads the single-day
/// range for the current date.
final todayEarningsProvider = FutureProvider<EarningsSummary>((ref) async {
  final repository = ref.watch(earningsRepositoryProvider);
  final now = DateTime.now();
  final today =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return repository.getEarnings(from: today, to: today);
});
