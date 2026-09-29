import 'dart:async';

import 'package:expense_tracker/core/router/app_router.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/date_only.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_expense_repository.dart';

/// Starts the real app on the list and taps + to open the add screen, so
/// saving (which pops back to the list) works exactly as in the app.
Future<void> openAddScreen(
  WidgetTester tester,
  FakeExpenseRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [expenseRepositoryProvider.overrideWithValue(repository)],
      retry: (_, _) => null,
      child: ExpenseTrackerApp(router: createAppRouter()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
}

Future<void> enterField(WidgetTester tester, String label, String text) {
  return tester.enterText(find.widgetWithText(TextFormField, label), text);
}

Future<void> tapSave(WidgetTester tester) async {
  // The form scrolls, so make sure the button is on screen before tapping.
  await tester.ensureVisible(find.byType(FilledButton));
  await tester.tap(find.byType(FilledButton));
}

void main() {
  testWidgets('saving an empty form shows errors and saves nothing', (
    tester,
  ) async {
    final repository = FakeExpenseRepository();
    await openAddScreen(tester, repository);

    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(repository.addCalls, 0);
  });

  testWidgets('an invalid amount shows an error', (tester) async {
    final repository = FakeExpenseRepository();
    await openAddScreen(tester, repository);

    await enterField(tester, 'Title', 'Coffee');
    await enterField(tester, 'Amount', 'abc');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid amount, like 4.50'), findsOneWidget);
    expect(repository.addCalls, 0);
  });

  testWidgets('a valid form saves every value and returns to the list', (
    tester,
  ) async {
    final repository = FakeExpenseRepository();
    await openAddScreen(tester, repository);

    await enterField(tester, 'Title', 'Coffee');
    await enterField(tester, 'Amount', '4,50');
    await enterField(tester, 'Note (optional)', ' Morning coffee ');
    // Open the dropdown (it shows the current value, 'Other'), pick Food.
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    // .last: while the menu is open, 'Food' can appear more than once.
    await tester.tap(find.text('Food').last);
    await tester.pumpAndSettle();
    await tapSave(tester);
    await tester.pumpAndSettle();

    final saved = repository.expenses.single;
    expect(saved.title, 'Coffee');
    expect(saved.amountCents, 450);
    expect(saved.category, ExpenseCategory.food);
    expect(saved.date, dateOnly(DateTime.now()));
    expect(saved.note, 'Morning coffee');

    // Back on the list, which already shows the new expense.
    expect(find.text('Add expense'), findsNothing);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('₾4.50'), findsOneWidget);
  });

  testWidgets('an empty note is saved as null', (tester) async {
    final repository = FakeExpenseRepository();
    await openAddScreen(tester, repository);

    await enterField(tester, 'Title', 'Bus');
    await enterField(tester, 'Amount', '1');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(repository.expenses.single.note, isNull);
    expect(repository.expenses.single.category, ExpenseCategory.other);
  });

  testWidgets('the picked date is saved', (tester) async {
    final repository = FakeExpenseRepository();
    await openAddScreen(tester, repository);
    final now = DateTime.now();
    // The 1st of this month is always allowed: it is never in the future.
    final firstOfMonth = DateTime(now.year, now.month, 1);

    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await enterField(tester, 'Title', 'Rent');
    await enterField(tester, 'Amount', '500');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(repository.expenses.single.date, firstOfMonth);
  });

  testWidgets('a failed save shows a message and stays on the form', (
    tester,
  ) async {
    final repository = FakeExpenseRepository()
      ..addError = Exception('disk full');
    await openAddScreen(tester, repository);

    await enterField(tester, 'Title', 'Coffee');
    await enterField(tester, 'Amount', '4.50');
    await tapSave(tester);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't save the expense."), findsOneWidget);
    expect(find.text('Add expense'), findsOneWidget);
    // The button is enabled again, so the user can try once more.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('tapping Save twice saves only once', (tester) async {
    final gate = Completer<void>();
    final repository = FakeExpenseRepository()..addGate = gate;
    await openAddScreen(tester, repository);

    await enterField(tester, 'Title', 'Coffee');
    await enterField(tester, 'Amount', '4.50');
    await tapSave(tester);
    // pump, not pumpAndSettle: the save is still running and its spinner
    // keeps animating, so the screen would never "settle".
    await tester.pump();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);

    gate.complete();
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(repository.expenses, hasLength(1));
  });
}
