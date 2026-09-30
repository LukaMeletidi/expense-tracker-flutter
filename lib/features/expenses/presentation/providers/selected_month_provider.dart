import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month the expense list is showing. It starts at the current month
/// and never goes past it, because expenses cannot be dated in the future.
class SelectedMonthNotifier extends Notifier<CalendarMonth> {
  @override
  CalendarMonth build() => CalendarMonth.of(ref.watch(clockProvider)());

  /// Read fresh on every call, so it moves on if the app stays open over
  /// the end of a month. Used by the methods, so it reads (not watches).
  CalendarMonth get _currentMonth =>
      CalendarMonth.of(ref.read(clockProvider)());

  /// Whether [next] would move forward (false on the current month).
  bool get canGoNext => !state.next.isAfter(_currentMonth);

  void previous() => state = state.previous;

  /// Does nothing on the current month.
  void next() {
    if (canGoNext) state = state.next;
  }

  /// Shows [month], or the current month if [month] is in the future.
  void select(CalendarMonth month) {
    final current = _currentMonth;
    state = month.isAfter(current) ? current : month;
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, CalendarMonth>(
      SelectedMonthNotifier.new,
    );
