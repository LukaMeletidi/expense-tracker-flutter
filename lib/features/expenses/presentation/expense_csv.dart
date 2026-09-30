/// Turns expenses into a CSV file that spreadsheet apps can open.
///
/// ```
/// Date,Title,Category,Amount (GEL),Note
/// 2026-09-29,Doctor appointment,Health,75.00,
/// 2026-09-27,Hoodie,Shopping,95.00,"Blue, size M"
/// ```
library;

import 'package:expense_tracker/core/formatting/money.dart';
import 'package:expense_tracker/features/expenses/data/calendar_day_converter.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';

/// Makes Excel read the file as UTF-8, so Georgian text and ₾ show
/// correctly. Other apps ignore it.
const _byteOrderMark = '﻿';

/// CSV's standard line ending (RFC 4180); every spreadsheet app accepts it.
const _lineEnd = '\r\n';

const _header = ['Date', 'Title', 'Category', 'Amount (GEL)', 'Note'];

/// One header row, then one row per expense, in the order given (the list
/// shows newest first, so the file does too).
String expensesToCsv(List<Expense> expenses) {
  // The same 'yyyy-mm-dd' format as the database, which spreadsheets read
  // as a date.
  const dayFormat = CalendarDayConverter();
  final rows = [
    _header,
    for (final expense in expenses)
      [
        dayFormat.toSql(expense.date),
        _userText(expense.title),
        expense.category.label,
        // A plain number (no ₾), so a spreadsheet can add the column up.
        formatCents(expense.amountCents, symbol: ''),
        _userText(expense.note ?? ''),
      ],
  ];
  final lines = rows.map((row) => row.map(_field).join(','));
  return '$_byteOrderMark${lines.join(_lineEnd)}$_lineEnd';
}

/// `expenses-2026-09.csv`: the month, zero-padded so files sort in order.
String exportFileName(CalendarMonth month) =>
    'expenses-${month.year}-${month.month.toString().padLeft(2, '0')}.csv';

/// Characters that make a spreadsheet treat a cell as a formula.
final _formulaStart = RegExp('^[=+\\-@\t\r]');

/// Text the user typed. If it starts like a formula (`=SUM(...)`), a leading
/// `'` makes spreadsheets show it as plain text instead of running it; this
/// is a known way to attack people through CSV files ("CSV injection").
String _userText(String value) =>
    _formulaStart.hasMatch(value) ? "'$value" : value;

/// Wraps a field in quotes when it contains a comma, quote or line break,
/// and doubles any quotes inside it, as RFC 4180 describes. Otherwise a
/// comma in a note would split it into two columns.
String _field(String value) {
  if (!value.contains(RegExp('[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
