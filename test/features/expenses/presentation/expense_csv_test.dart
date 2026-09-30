import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_csv.dart';
import 'package:flutter_test/flutter_test.dart';

const header = 'Date,Title,Category,Amount (GEL),Note';

Expense expense({
  String title = 'Coffee',
  int amountCents = 450,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  String? note,
}) {
  return Expense(
    id: 1,
    title: title,
    amountCents: amountCents,
    category: category,
    date: date ?? DateTime(2026, 9, 1),
    createdAt: DateTime(2026, 9, 1, 10, 0),
    note: note,
  );
}

/// The file's lines, without the byte order mark and the final line end.
List<String> lines(String csv) {
  expect(csv.startsWith('﻿'), isTrue, reason: 'starts with a BOM');
  expect(csv.endsWith('\r\n'), isTrue, reason: 'ends with CRLF');
  return csv.substring(1, csv.length - 2).split('\r\n');
}

/// The single data row for one expense.
String rowFor(Expense e) => lines(expensesToCsv([e]))[1];

void main() {
  group('expensesToCsv', () {
    test('no expenses give only the header', () {
      expect(lines(expensesToCsv([])), [header]);
    });

    test('an expense becomes one row with every column', () {
      final csv = expensesToCsv([
        expense(
          title: 'Doctor appointment',
          amountCents: 7500,
          category: ExpenseCategory.health,
          date: DateTime(2026, 9, 29),
          note: 'Check-up',
        ),
      ]);

      expect(lines(csv), [
        header,
        '2026-09-29,Doctor appointment,Health,75.00,Check-up',
      ]);
    });

    test('a missing note leaves the last column empty', () {
      expect(rowFor(expense()), '2026-09-01,Coffee,Food,4.50,');
    });

    test('amounts are plain numbers with two decimals', () {
      expect(rowFor(expense(amountCents: 5)), contains(',0.05,'));
      expect(rowFor(expense(amountCents: 1234567)), contains(',12345.67,'));
    });

    test('rows keep the order they were given in', () {
      final csv = expensesToCsv([
        expense(title: 'Newer', date: DateTime(2026, 9, 2)),
        expense(title: 'Older', date: DateTime(2026, 9, 1)),
      ]);

      expect(lines(csv).skip(1).map((line) => line.split(',')[1]), [
        'Newer',
        'Older',
      ]);
    });

    test('lines end with CRLF', () {
      final csv = expensesToCsv([expense(), expense()]);

      // Header + 2 rows, each followed by \r\n, and no bare \n anywhere.
      expect('\r\n'.allMatches(csv), hasLength(3));
      expect(csv.replaceAll('\r\n', ''), isNot(contains('\n')));
    });

    test('keeps Georgian text as it is', () {
      expect(rowFor(expense(title: 'ყავა')), contains(',ყავა,'));
    });
  });

  group('expensesToCsv quoting', () {
    test('a comma puts the field in quotes', () {
      expect(
        rowFor(expense(note: 'Blue, size M')),
        endsWith(',"Blue, size M"'),
      );
    });

    test('a quote is doubled, inside quotes', () {
      expect(
        rowFor(expense(title: 'The "good" coffee')),
        contains(',"The ""good"" coffee",'),
      );
    });

    test('a line break puts the field in quotes', () {
      final csv = expensesToCsv([expense(note: 'Line one\nLine two')]);

      expect(csv, contains(',"Line one\nLine two"\r\n'));
    });

    test('plain text is not quoted', () {
      expect(rowFor(expense(title: 'Coffee')), isNot(contains('"')));
    });
  });

  group('expensesToCsv formula guard', () {
    for (final start in ['=', '+', '-', '@']) {
      test('a title starting with $start is shown as text', () {
        expect(
          rowFor(expense(title: '${start}SUM(A1)')),
          contains(",'${start}SUM(A1),"),
        );
      });
    }

    test('the note is guarded too', () {
      expect(rowFor(expense(note: '=1+1')), endsWith(",'=1+1"));
    });

    test('a guarded field with a comma is also quoted', () {
      expect(rowFor(expense(note: '=A1,B1')), endsWith(',"\'=A1,B1"'));
    });

    test('ordinary text is left alone', () {
      expect(
        rowFor(expense(title: 'Taxi - airport')),
        contains(',Taxi - airport,'),
      );
    });
  });

  group('exportFileName', () {
    test('names the file after the month', () {
      expect(
        exportFileName(const CalendarMonth(2026, 9)),
        'expenses-2026-09.csv',
      );
    });

    test('pads single-digit months so files sort in order', () {
      expect(
        exportFileName(const CalendarMonth(2027, 1)),
        'expenses-2027-01.csv',
      );
    });

    test('keeps two-digit months as they are', () {
      expect(
        exportFileName(const CalendarMonth(2026, 12)),
        'expenses-2026-12.csv',
      );
    });
  });
}
