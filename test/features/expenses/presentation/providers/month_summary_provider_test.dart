import 'dart:async';

import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/month_summary.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/month_summary_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_container.dart';

/// Waits until the summary passes [condition]. The database answers a
/// moment after each change, so reading straight away could be too early.
Future<MonthSummary> waitForSummary(
  ProviderContainer container,
  bool Function(MonthSummary summary) condition,
) {
  final completer = Completer<MonthSummary>();
  final subscription = container.listen(monthSummaryProvider, (_, next) {
    final summary = next.value;
    if (summary != null && condition(summary) && !completer.isCompleted) {
      completer.complete(summary);
    }
  }, fireImmediately: true);
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(subscription.close);
}

Future<void> addExpense(
  ProviderContainer container,
  ExpenseCategory category,
  int amountCents,
  DateTime date,
) {
  return container
      .read(expenseListProvider.notifier)
      .add(
        title: 'Test',
        amountCents: amountCents,
        category: category,
        date: date,
      );
}

void main() {
  test('an empty month gives an empty summary', () async {
    final container = createInMemoryContainer();

    final summary = await waitForSummary(container, (_) => true);

    expect(summary.isEmpty, isTrue);
    expect(summary.totalCents, 0);
  });

  test("sums up the selected month's expenses", () async {
    final container = createInMemoryContainer();
    await addExpense(
      container,
      ExpenseCategory.transport,
      100,
      DateTime(2026, 9, 2),
    );
    await addExpense(
      container,
      ExpenseCategory.food,
      450,
      DateTime(2026, 9, 1),
    );

    final summary = await waitForSummary(container, (s) => s.totalCents == 550);

    expect(summary.categories.map((c) => c.category), [
      ExpenseCategory.food,
      ExpenseCategory.transport,
    ]);
  });

  test('follows a change of the selected month', () async {
    final container = createInMemoryContainer();
    // August first: adding switches to the new expense's month, so the
    // September expense, added last, leaves September selected.
    await addExpense(
      container,
      ExpenseCategory.bills,
      50000,
      DateTime(2026, 8, 1),
    );
    await addExpense(
      container,
      ExpenseCategory.food,
      450,
      DateTime(2026, 9, 1),
    );
    await waitForSummary(container, (s) => s.totalCents == 450);

    container.read(selectedMonthProvider.notifier).previous();

    final august = await waitForSummary(
      container,
      (s) => s.totalCents == 50000,
    );
    expect(august.categories.single.category, ExpenseCategory.bills);
  });
}
