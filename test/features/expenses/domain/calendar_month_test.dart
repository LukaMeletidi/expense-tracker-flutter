import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarMonth.of', () {
    test('takes the year and month of a date', () {
      expect(
        CalendarMonth.of(DateTime(2026, 9, 29, 18, 45)),
        const CalendarMonth(2026, 9),
      );
    });

    test('uses the local day for a UTC value', () {
      // 21:30 UTC on 30 September is already 1 October east of UTC.
      final utc = DateTime.utc(2026, 9, 30, 21, 30);
      // Worked out from toLocal() so the test passes in any time zone.
      final local = utc.toLocal();

      expect(CalendarMonth.of(utc), CalendarMonth(local.year, local.month));
    });
  });

  group('CalendarMonth.next', () {
    test('moves to the next month in the same year', () {
      expect(const CalendarMonth(2026, 9).next, const CalendarMonth(2026, 10));
    });

    test('goes from December to January of the next year', () {
      expect(const CalendarMonth(2026, 12).next, const CalendarMonth(2027, 1));
    });
  });

  group('CalendarMonth.previous', () {
    test('moves to the previous month in the same year', () {
      expect(
        const CalendarMonth(2026, 9).previous,
        const CalendarMonth(2026, 8),
      );
    });

    test('goes from January back to December of the previous year', () {
      expect(
        const CalendarMonth(2027, 1).previous,
        const CalendarMonth(2026, 12),
      );
    });
  });

  test('firstDay is local midnight on the 1st', () {
    expect(const CalendarMonth(2026, 9).firstDay, DateTime(2026, 9, 1));
  });

  group('CalendarMonth equality', () {
    test('the same year and month are equal, with the same hashCode', () {
      const a = CalendarMonth(2026, 9);
      final b = CalendarMonth.of(DateTime(2026, 9, 15));

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('a different month makes them unequal', () {
      expect(
        const CalendarMonth(2026, 9),
        isNot(equals(const CalendarMonth(2026, 10))),
      );
    });

    test('a different year makes them unequal', () {
      expect(
        const CalendarMonth(2026, 9),
        isNot(equals(const CalendarMonth(2025, 9))),
      );
    });
  });

  group('CalendarMonth.isAfter', () {
    test('a later month in the same year is after', () {
      expect(
        const CalendarMonth(2026, 10).isAfter(const CalendarMonth(2026, 9)),
        isTrue,
      );
    });

    test('an earlier month is not after', () {
      expect(
        const CalendarMonth(2026, 8).isAfter(const CalendarMonth(2026, 9)),
        isFalse,
      );
    });

    test('the same month is not after itself', () {
      expect(
        const CalendarMonth(2026, 9).isAfter(const CalendarMonth(2026, 9)),
        isFalse,
      );
    });

    test('January of a later year is after December', () {
      expect(
        const CalendarMonth(2027, 1).isAfter(const CalendarMonth(2026, 12)),
        isTrue,
      );
    });
  });

  test('a month outside 1 to 12 is an error', () {
    // Variables, not literals: const CalendarMonth(2026, 0) would be
    // rejected by the compiler before the test could even run.
    var zero = 0;
    var thirteen = 13;

    expect(() => CalendarMonth(2026, zero), throwsAssertionError);
    expect(() => CalendarMonth(2026, thirteen), throwsAssertionError);
  });
}
