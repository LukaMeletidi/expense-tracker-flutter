import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_expense_repository.dart';

var _nextId = 1;

Expense expense(ExpenseCategory category, int amountCents, DateTime date) {
  return Expense(
    id: _nextId++,
    title: category.name,
    amountCents: amountCents,
    category: category,
    date: date,
    createdAt: date,
  );
}

/// Shows the statistics screen on 29 September 2026, with [repository]
/// behind the providers.
Future<void> pumpStatisticsScreen(
  WidgetTester tester,
  FakeExpenseRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 29, 12, 0)),
      ],
      // No automatic retry: the error test needs the error to stay put.
      retry: (_, _) => null,
      child: const MaterialApp(home: StatisticsScreen()),
    ),
  );
}

/// How far down the screen [text] is, to check the order of the rows.
double topOf(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  final september = DateTime(2026, 9, 10);

  testWidgets('shows a spinner while loading', (tester) async {
    await pumpStatisticsScreen(
      tester,
      FakeExpenseRepository()..neverEmits = true,
    );
    // pump, not pumpAndSettle: the spinner never stops moving.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error with Retry, and Retry loads again', (
    tester,
  ) async {
    final repository = FakeExpenseRepository()
      ..watchError = Exception('disk full');
    await pumpStatisticsScreen(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load statistics."), findsOneWidget);

    repository.watchError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load statistics."), findsNothing);
    expect(find.text('No expenses in September 2026.'), findsOneWidget);
  });

  testWidgets('an empty month says which month is empty', (tester) async {
    await pumpStatisticsScreen(tester, FakeExpenseRepository());
    await tester.pumpAndSettle();

    expect(find.text('No expenses in September 2026.'), findsOneWidget);
  });

  testWidgets('shows the total and each category, largest first', (
    tester,
  ) async {
    await pumpStatisticsScreen(
      tester,
      FakeExpenseRepository(
        expenses: [
          expense(ExpenseCategory.transport, 1260, september),
          expense(ExpenseCategory.health, 7500, september),
          expense(ExpenseCategory.shopping, 9500, september),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total spent'), findsOneWidget);
    expect(find.text('₾182.60'), findsOneWidget);

    // Each category with its percentage and amount.
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('52%'), findsOneWidget);
    expect(find.text('₾95.00'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('41%'), findsOneWidget);
    expect(find.text('₾75.00'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('7%'), findsOneWidget);
    expect(find.text('₾12.60'), findsOneWidget);

    // Largest first, going down the screen.
    expect(topOf(tester, 'Shopping'), lessThan(topOf(tester, 'Health')));
    expect(topOf(tester, 'Health'), lessThan(topOf(tester, 'Transport')));
  });

  testWidgets('the month bar switches the statistics to that month', (
    tester,
  ) async {
    await pumpStatisticsScreen(
      tester,
      FakeExpenseRepository(
        expenses: [
          expense(ExpenseCategory.food, 450, september),
          expense(ExpenseCategory.bills, 50000, DateTime(2026, 8, 1)),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('₾4.50'), findsWidgets);

    await tester.tap(find.byTooltip('Show previous month'));
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsOneWidget);
    expect(find.text('Bills'), findsOneWidget);
    expect(find.text('Food'), findsNothing);
    // The total and the only category are the same amount.
    expect(find.text('₾500.00'), findsNWidgets(2));
  });
}
