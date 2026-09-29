import 'package:expense_tracker/features/expenses/domain/date_only.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dateOnly', () {
    test('turns an evening time into midnight of the same day', () {
      expect(dateOnly(DateTime(2026, 9, 1, 18, 45)), DateTime(2026, 9, 1));
    });

    test('leaves a value that is already midnight unchanged', () {
      expect(dateOnly(DateTime(2026, 9, 1)), DateTime(2026, 9, 1));
    });

    test('keeps the last moment of a day on that day', () {
      expect(
        dateOnly(DateTime(2026, 9, 1, 23, 59, 59, 999, 999)),
        DateTime(2026, 9, 1),
      );
    });

    test('converts a UTC value to the local day first', () {
      final utc = DateTime.utc(2026, 9, 1, 21, 30);
      // The expected day depends on the time zone of the machine running
      // the test, so it is worked out from toLocal() instead of hard-coded.
      final local = utc.toLocal();

      final result = dateOnly(utc);

      expect(result, DateTime(local.year, local.month, local.day));
      expect(result.isUtc, isFalse);
    });
  });
}
