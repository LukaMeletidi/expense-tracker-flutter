import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Expense expense({String? note}) {
  return Expense(
    id: 1,
    title: 'Doctor appointment',
    amountCents: 7500,
    category: ExpenseCategory.health,
    date: DateTime(2026, 9, 29),
    createdAt: DateTime(2026, 9, 29, 10, 0),
    note: note,
  );
}

Future<void> pumpDetails(WidgetTester tester, Expense expense) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ExpenseDetails(expense: expense)),
    ),
  );
}

void main() {
  testWidgets('shows the title, amount, category and full date', (
    tester,
  ) async {
    await pumpDetails(tester, expense(note: 'Check-up'));

    expect(find.text('Doctor appointment'), findsOneWidget);
    expect(find.text('₾75.00'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Tuesday, September 29, 2026'), findsOneWidget);
  });

  testWidgets('shows the whole note, line breaks included', (tester) async {
    final longNote = [
      for (var line = 1; line <= 40; line++) 'Line $line of a long note',
    ].join('\n');
    await pumpDetails(tester, expense(note: longNote));

    final noteText = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(noteText.data, longNote);
    // No line limit, so nothing is cut off with "…".
    expect(noteText.maxLines, isNull);
    // Inside a scroll view, so a note taller than the sheet can be scrolled
    // to its end.
    expect(
      find.ancestor(
        of: find.byType(SelectableText),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a missing note says "No note"', (tester) async {
    await pumpDetails(tester, expense());

    expect(find.text('No note'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('is read-only: nothing to type into and no buttons', (
    tester,
  ) async {
    await pumpDetails(tester, expense(note: 'Check-up'));

    expect(find.byType(TextField), findsNothing);
    // SelectableText is built on an EditableText, so check that every one
    // of them is read-only rather than that there are none.
    final editables = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    expect(editables, isNotEmpty);
    expect(editables.every((editable) => editable.readOnly), isTrue);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ButtonStyleButton || widget is IconButton,
      ),
      findsNothing,
    );
  });
}
