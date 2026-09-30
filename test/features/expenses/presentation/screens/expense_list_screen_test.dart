import 'dart:async';

import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/core/sharing/file_sharer.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_expense_repository.dart';
import '../../../../helpers/fake_file_sharer.dart';

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
  date: DateTime(2026, 9, 2),
  createdAt: DateTime(2026, 9, 2, 9, 0),
);

/// "Now" for every test here, so the list always shows September 2026,
/// whatever the real date is.
final testNow = DateTime(2026, 9, 29, 12, 0);

/// Shows the list screen with [repository] behind expenseListProvider.
///
/// Sharing always goes to a fake, [sharer] if given: the real share_plus
/// plugin cannot run inside a test.
Future<void> pumpListScreen(
  WidgetTester tester,
  FakeExpenseRepository repository, {
  FakeFileSharer? sharer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => testNow),
        fileSharerProvider.overrideWithValue(sharer ?? FakeFileSharer()),
      ],
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
    expect(
      find.textContaining('No expenses in September 2026.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state when there are no expenses', (
    tester,
  ) async {
    await pumpListScreen(tester, FakeExpenseRepository());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('No expenses in September 2026.'),
      findsOneWidget,
    );
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
    expect(find.text('Transport · Sep 2, 2026'), findsOneWidget);
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

  group('month bar', () {
    final rent = Expense(
      id: 3,
      title: 'Rent',
      amountCents: 50000,
      category: ExpenseCategory.bills,
      date: DateTime(2026, 8, 15),
      createdAt: DateTime(2026, 8, 15, 9, 0),
    );

    IconButton nextButton(WidgetTester tester) => tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right),
    );

    testWidgets('shows the current month, with next disabled', (tester) async {
      await pumpListScreen(tester, FakeExpenseRepository());
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(nextButton(tester).onPressed, isNull);
    });

    testWidgets('previous shows that month, and next comes back', (
      tester,
    ) async {
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee, rent]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);

      await tester.tap(find.byTooltip('Show previous month'));
      await tester.pumpAndSettle();

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Coffee'), findsNothing);
      expect(nextButton(tester).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Show next month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Rent'), findsNothing);
    });

    testWidgets('an empty month says which month is empty', (tester) async {
      await pumpListScreen(tester, FakeExpenseRepository(expenses: [coffee]));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Show previous month'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No expenses in August 2026.'),
        findsOneWidget,
      );
    });
  });

  group('total line', () {
    testWidgets("shows the month's total above the list", (tester) async {
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee, bus]),
      );
      await tester.pumpAndSettle();

      // ₾4.50 + ₾1.00
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('₾5.50'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Total')).dy,
        lessThan(tester.getTopLeft(find.text('Coffee')).dy),
      );
    });

    testWidgets('updates after a delete', (tester) async {
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee, bus]),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Coffee'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      // Only the bus is left: its row and the total both show ₾1.00.
      expect(find.text('₾5.50'), findsNothing);
      expect(find.text('₾1.00'), findsNWidgets(2));
    });

    testWidgets('follows the selected month', (tester) async {
      final rent = Expense(
        id: 3,
        title: 'Rent',
        amountCents: 50000,
        category: ExpenseCategory.bills,
        date: DateTime(2026, 8, 15),
        createdAt: DateTime(2026, 8, 15, 9, 0),
      );
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee, rent]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Show previous month'));
      await tester.pumpAndSettle();

      // August has only the rent: its row and the total both show ₾500.00.
      expect(find.text('₾500.00'), findsNWidgets(2));
    });

    testWidgets('is not shown for an empty month', (tester) async {
      await pumpListScreen(tester, FakeExpenseRepository());
      await tester.pumpAndSettle();

      expect(find.text('Total'), findsNothing);
    });
  });

  group('details sheet', () {
    final lunch = Expense(
      id: 4,
      title: 'Lunch',
      amountCents: 1800,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 3),
      createdAt: DateTime(2026, 9, 3, 13, 0),
      note: 'With the team\nPaid by card',
    );

    testWidgets('tapping a row shows that expense, with its note', (
      tester,
    ) async {
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [lunch, bus]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, September 3, 2026'), findsOneWidget);
      expect(find.text('With the team\nPaid by card'), findsOneWidget);
    });

    testWidgets('shows the tapped expense, not another one', (tester) async {
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [lunch, bus]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bus'));
      await tester.pumpAndSettle();

      expect(find.text('Wednesday, September 2, 2026'), findsOneWidget);
      expect(find.text('No note'), findsOneWidget);
      expect(find.text('With the team\nPaid by card'), findsNothing);
    });

    testWidgets('closes when swiped down', (tester) async {
      await pumpListScreen(tester, FakeExpenseRepository(expenses: [lunch]));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      expect(find.text('Note'), findsOneWidget);

      await tester.drag(find.text('Note'), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.text('Note'), findsNothing);
    });

    testWidgets('a very long note fits in the sheet without errors', (
      tester,
    ) async {
      final longNote = [
        for (var line = 1; line <= 80; line++) 'Line $line of a long note',
      ].join('\n');
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [lunch.copyWith(note: longNote)]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();

      // A layout overflow would be reported here as an exception.
      expect(tester.takeException(), isNull);
      expect(find.text(longNote), findsOneWidget);
    });
  });

  group('export button', () {
    Finder exportButton() => find.byTooltip('Export month');

    testWidgets("shares the month's expenses as a CSV file", (tester) async {
      final sharer = FakeFileSharer();
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee, bus]),
        sharer: sharer,
      );
      await tester.pumpAndSettle();

      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      final file = sharer.shared.single;
      expect(file.fileName, 'expenses-2026-09.csv');
      expect(file.mimeType, 'text/csv');
      expect(file.contents, contains(',Coffee,'));
      expect(file.contents, contains(',Bus,'));
      // The iPad share sheet gets the whole button's area to point at.
      expect(
        file.origin,
        tester.getRect(find.widgetWithIcon(IconButton, Icons.share)),
      );
    });

    testWidgets('an empty month shows a message and shares nothing', (
      tester,
    ) async {
      final sharer = FakeFileSharer();
      await pumpListScreen(tester, FakeExpenseRepository(), sharer: sharer);
      await tester.pumpAndSettle();

      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      expect(
        find.text('No expenses in September 2026 to export.'),
        findsOneWidget,
      );
      expect(sharer.shared, isEmpty);
    });

    testWidgets('a failed export shows a message', (tester) async {
      final sharer = FakeFileSharer()..error = Exception('disk full');
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee]),
        sharer: sharer,
      );
      await tester.pumpAndSettle();

      await tester.tap(exportButton());
      await tester.pumpAndSettle();

      expect(find.text("Couldn't export the expenses."), findsOneWidget);
    });

    testWidgets('is disabled while an export is running', (tester) async {
      final gate = Completer<void>();
      final sharer = FakeFileSharer()..gate = gate;
      await pumpListScreen(
        tester,
        FakeExpenseRepository(expenses: [coffee]),
        sharer: sharer,
      );
      await tester.pumpAndSettle();

      await tester.tap(exportButton());
      await tester.pump();

      IconButton button() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.share),
      );
      expect(button().onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();

      expect(button().onPressed, isNotNull);
      expect(sharer.shared, hasLength(1));
    });
  });
}
