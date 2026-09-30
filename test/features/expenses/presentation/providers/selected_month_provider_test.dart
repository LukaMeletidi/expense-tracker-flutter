import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const september = CalendarMonth(2026, 9);
  const august = CalendarMonth(2026, 8);
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 9, 29, 12, 0);
    // The clock reads the variable on every call, so a test can move time.
    container = ProviderContainer.test(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
  });

  CalendarMonth selected() => container.read(selectedMonthProvider);
  SelectedMonthNotifier notifier() =>
      container.read(selectedMonthProvider.notifier);

  test('starts on the current month', () {
    expect(selected(), september);
  });

  test('previous goes back one month', () {
    notifier().previous();

    expect(selected(), august);
  });

  test('next does nothing on the current month', () {
    expect(notifier().canGoNext, isFalse);

    notifier().next();

    expect(selected(), september);
  });

  test('next goes forward from an earlier month', () {
    notifier().previous();
    expect(notifier().canGoNext, isTrue);

    notifier().next();

    expect(selected(), september);
  });

  test('select shows the given month', () {
    notifier().select(const CalendarMonth(2025, 12));

    expect(selected(), const CalendarMonth(2025, 12));
  });

  test('select of a future month shows the current month instead', () {
    notifier().previous();

    notifier().select(const CalendarMonth(2026, 10));

    expect(selected(), september);
  });

  test('the current month is read fresh, so a new month unlocks next', () {
    // The app was opened in September, and is still open in October.
    expect(notifier().canGoNext, isFalse);
    now = DateTime(2026, 10, 1, 9, 0);

    expect(notifier().canGoNext, isTrue);
    notifier().next();
    expect(selected(), const CalendarMonth(2026, 10));
  });
}
