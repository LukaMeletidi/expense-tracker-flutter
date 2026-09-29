import 'package:expense_tracker/features/expenses/domain/date_only.dart';

/// A month in the calendar, such as September 2026, with no day or time.
///
/// Used to show one month of expenses at a time. Like `Expense`, it has
/// value equality, so two `CalendarMonth(2026, 9)` objects are equal and
/// Riverpod can tell whether the selected month really changed.
class CalendarMonth {
  const CalendarMonth(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'month must be 1 to 12');

  /// The month that [date] falls in, using the local calendar day, the same
  /// way an expense's date is stored.
  factory CalendarMonth.of(DateTime date) {
    final day = dateOnly(date);
    return CalendarMonth(day.year, day.month);
  }

  final int year;

  /// 1 for January to 12 for December, like [DateTime.month].
  final int month;

  /// The month before this one; January goes back to December of last year.
  CalendarMonth get previous =>
      month == 1 ? CalendarMonth(year - 1, 12) : CalendarMonth(year, month - 1);

  /// The month after this one; December goes on to January of next year.
  CalendarMonth get next =>
      month == 12 ? CalendarMonth(year + 1, 1) : CalendarMonth(year, month + 1);

  /// Local midnight on the 1st of this month.
  DateTime get firstDay => DateTime(year, month);

  /// Whether this month comes later in time than [other].
  bool isAfter(CalendarMonth other) =>
      year > other.year || (year == other.year && month > other.month);

  @override
  bool operator ==(Object other) =>
      other is CalendarMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  /// Makes test failures readable: `CalendarMonth(2026-09)`.
  @override
  String toString() =>
      'CalendarMonth($year-${month.toString().padLeft(2, '0')})';
}
