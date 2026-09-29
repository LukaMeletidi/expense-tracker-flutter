import 'package:expense_tracker/features/expenses/data/calendar_day_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = CalendarDayConverter();

  group('CalendarDayConverter.toSql', () {
    test('writes the day as zero-padded text', () {
      expect(converter.toSql(DateTime(2026, 9, 1)), '2026-09-01');
    });

    test('drops the time of day', () {
      expect(converter.toSql(DateTime(2026, 9, 1, 18, 45)), '2026-09-01');
    });

    test('uses the local day for a UTC value', () {
      final utc = DateTime.utc(2026, 9, 1, 21, 30);
      // Worked out from toLocal() so the test passes in any time zone.
      final local = utc.toLocal();
      final expected = converter.toSql(
        DateTime(local.year, local.month, local.day),
      );

      expect(converter.toSql(utc), expected);
    });
  });

  group('CalendarDayConverter.fromSql', () {
    test('reads the text back as local midnight', () {
      final result = converter.fromSql('2026-09-01');

      expect(result, DateTime(2026, 9, 1));
      expect(result.isUtc, isFalse);
    });

    test('saving then reading returns the same day', () {
      final day = DateTime(2026, 12, 31);

      expect(converter.fromSql(converter.toSql(day)), day);
    });
  });
}
