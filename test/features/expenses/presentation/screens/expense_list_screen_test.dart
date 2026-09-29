import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_expense_repository.dart';

final coffee = Expense(
  id: 1,
  title: 'Coffee',
  amountCents: 450,
  category: ExpenseCategory.food,
  date: DateTime(2026, 9, 1),
  createdAt: DateTime(2026, 9, 1, 10, 0),
);

final bus = Expense(
  id: 2,
  title: 'Bus',
  amountCents: 100,
  category: ExpenseCategory.transport,
  date: DateTime(2026, 8, 31),
  createdAt: DateTime(2026, 8, 31, 9, 0),
);

/// Shows the list screen with [repository] behind expenseListProvider.
Future<void> pumpListScreen(
  WidgetTester tester,
  FakeExpenseRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      // Riverpod 3 retries failed providers on a timer; the error tests
      // need the error to stay put, and no timer left running.
      retry: (_, _) => null,
      child: const MaterialApp(home: ExpenseListScreen()),
    ),
  );
}

void main() {
  testWidgets('shows a spinner while loading', (tester) async {
    await pumpListScreen(tester, FakeExpenseRepository()..neverEmits = true);
    // pump, not pumpAndSettle: the spinner animates forever, so it never
    // "settles" and pumpAndSettle would time out.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error with Retry, and Retry loads again', (
    tester,
  ) async {
    final repository = FakeExpenseRepository()
      ..watchError = Exception('disk full');
    await pumpListScreen(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load expenses."), findsOneWidget);

    repository.watchError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load expenses."), findsNothing);
    expect(find.textContaining('No expenses yet.'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no expenses', (
    tester,
  ) async {
    await pumpListScreen(tester, FakeExpenseRepository());
    await tester.pumpAndSettle();

    expect(find.textContaining('No expenses yet.'), findsOneWidget);
  });

  testWidgets('shows each expense with category, date and amount', (
    tester,
  ) async {
    await pumpListScreen(
      tester,
      FakeExpenseRepository(expenses: [coffee, bus]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Food · Sep 1, 2026'), findsOneWidget);
    expect(find.text('₾4.50'), findsOneWidget);
    expect(find.text('Bus'), findsOneWidget);
    expect(find.text('Transport · Aug 31, 2026'), findsOneWidget);
    expect(find.text('₾1.00'), findsOneWidget);
  });

  testWidgets('swiping a row deletes that expense', (tester) async {
    final repository = FakeExpenseRepository(expenses: [coffee, bus]);
    await pumpListScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Coffee'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [coffee.id]);
    expect(find.text('Coffee'), findsNothing);
    expect(find.text('Bus'), findsOneWidget);
  });

  testWidgets('a failed delete shows a message and keeps the row', (
    tester,
  ) async {
    final repository = FakeExpenseRepository(expenses: [coffee])
      ..deleteError = Exception('disk full');
    await pumpListScreen(tester, repository);
    await tester.pumpAndSettle();

    await tester.drag(find.text('Coffee'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't delete the expense."), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
  });
}
