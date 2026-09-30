import 'dart:ui';

import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/export_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_expense_repository.dart';
import '../../../../helpers/fake_file_sharer.dart';

Expense expense(int id, String title, DateTime date) {
  return Expense(
    id: id,
    title: title,
    amountCents: 450,
    category: ExpenseCategory.food,
    date: date,
    createdAt: date,
  );
}

void main() {
  const september = CalendarMonth(2026, 9);
  late FakeExpenseRepository repository;
  late FakeFileSharer sharer;
  late ExpenseExporter exporter;

  setUp(() {
    repository = FakeExpenseRepository(
      expenses: [
        expense(1, 'Coffee', DateTime(2026, 9, 1)),
        expense(2, 'Rent', DateTime(2026, 8, 1)),
      ],
    );
    sharer = FakeFileSharer();
    exporter = ExpenseExporter(repository: repository, sharer: sharer);
  });

  test("shares the month's expenses as a CSV file", () async {
    final result = await exporter.exportMonth(september);

    expect(result, ExportResult.shared);
    final file = sharer.shared.single;
    expect(file.fileName, 'expenses-2026-09.csv');
    expect(file.mimeType, 'text/csv');
    expect(file.contents, contains('2026-09-01,Coffee,Food,4.50,'));
  });

  test('leaves out expenses from other months', () async {
    await exporter.exportMonth(september);

    expect(sharer.shared.single.contents, isNot(contains('Rent')));
  });

  test('an empty month shares nothing', () async {
    final result = await exporter.exportMonth(const CalendarMonth(2026, 7));

    expect(result, ExportResult.nothingToExport);
    expect(sharer.shared, isEmpty);
  });

  test('passes the share sheet origin on (for iPad)', () async {
    const origin = Rect.fromLTWH(10, 20, 48, 48);

    await exporter.exportMonth(september, origin: origin);

    expect(sharer.shared.single.origin, origin);
  });

  test('a sharing failure reaches the caller', () async {
    sharer.error = Exception('disk full');

    await expectLater(exporter.exportMonth(september), throwsException);
  });
}
