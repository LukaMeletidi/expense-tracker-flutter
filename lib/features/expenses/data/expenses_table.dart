import 'package:drift/drift.dart';
import 'package:expense_tracker/features/expenses/data/calendar_day_converter.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';

/// The `expenses` table. One row per [Expense].
///
/// Drift would name the generated row class `Expense`, which clashes with
/// the domain entity, so rows are called `ExpenseRow` instead: `ExpenseRow`
/// is what the database stores, `Expense` is what the app works with.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  IntColumn get amountCents => integer()();

  /// Stored by name ('food'), not position, so reordering the enum
  /// cannot silently change existing rows.
  TextColumn get category => textEnum<ExpenseCategory>()();

  /// The calendar day as text, e.g. '2026-09-01'.
  TextColumn get date => text().map(const CalendarDayConverter())();

  /// Drift's default: stored as whole seconds, read back as local time.
  DateTimeColumn get createdAt => dateTime()();

  TextColumn get note => text().nullable()();
}
