import 'package:drift/drift.dart';
import 'package:expense_tracker/features/expenses/domain/date_only.dart';

/// Stores an expense's calendar day as text, e.g. `'2026-09-01'`.
///
/// Text is used instead of a timestamp because a timestamp is a moment:
/// if the user changes time zone, that moment can fall on a different
/// local day. `'2026-09-01'` means the same day everywhere, and because
/// it is zero-padded, sorting the text also sorts the days.
class CalendarDayConverter extends TypeConverter<DateTime, String> {
  const CalendarDayConverter();

  @override
  String toSql(DateTime value) {
    // Every write goes through here, so no caller can forget dateOnly.
    final day = dateOnly(value);
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayOfMonth';
  }

  @override
  DateTime fromSql(String fromDb) {
    // A date without a 'Z' or offset is parsed as local midnight.
    return DateTime.parse(fromDb);
  }
}
