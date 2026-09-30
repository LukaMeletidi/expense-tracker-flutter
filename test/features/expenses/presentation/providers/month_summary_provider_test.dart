import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/month_summary_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_container.dart';
import '../../../../helpers/wait_for.dart';

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

    final summary = await waitFor(container, monthSummaryProvider, (_) => true);

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

    final summary = await waitFor(
      container,
      monthSummaryProvider,
      (s) => s.totalCents == 550,
    );

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
    await waitFor(container, monthSummaryProvider, (s) => s.totalCents == 450);

    container.read(selectedMonthProvider.notifier).previous();

    final august = await waitFor(
      container,
      monthSummaryProvider,
      (s) => s.totalCents == 50000,
    );
    expect(august.categories.single.category, ExpenseCategory.bills);
  });
}
