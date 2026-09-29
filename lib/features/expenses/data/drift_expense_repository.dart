import 'package:drift/drift.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/features/expenses/data/calendar_day_converter.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';

/// [ExpenseRepository] backed by the Drift [AppDatabase].
class DriftExpenseRepository implements ExpenseRepository {
  /// [now] supplies `createdAt` for new expenses. It defaults to the real
  /// clock; tests pass a fixed time so results are predictable.
  DriftExpenseRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final DateTime Function() _now;

  @override
  Stream<List<Expense>> watchAll() => _watchSorted(_db.select(_db.expenses));

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) {
    // Dates are stored as zero-padded text ('2026-09-01'), so a month is a
    // simple text range: from the 1st of this month (included) up to the
    // 1st of the next month (not included).
    const converter = CalendarDayConverter();
    final from = converter.toSql(month.firstDay);
    final until = converter.toSql(month.next.firstDay);

    final query = _db.select(_db.expenses)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(from) &
            t.date.isSmallerThanValue(until),
      );
    return _watchSorted(query);
  }

  /// Newest day first; within the same day, the most recently saved first.
  ///
  /// Drift re-runs the query and emits a new list whenever the table
  /// changes, so the UI updates on its own after add or delete.
  Stream<List<Expense>> _watchSorted(
    SimpleSelectStatement<$ExpensesTable, ExpenseRow> query,
  ) {
    query.orderBy([
      (t) => OrderingTerm.desc(t.date),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return query.watch().map((rows) => rows.map(_toExpense).toList());
  }

  @override
  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) async {
    await _db
        .into(_db.expenses)
        .insert(
          ExpensesCompanion.insert(
            title: title,
            amountCents: amountCents,
            category: category,
            // CalendarDayConverter runs dateOnly on this when it is saved.
            date: date,
            createdAt: _now(),
            note: Value(note),
          ),
        );
  }

  /// Deleting an id that does not exist does nothing.
  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.expenses)..where((t) => t.id.equals(id))).go();
  }

  /// Turns a database row into the domain entity the rest of the app uses.
  static Expense _toExpense(ExpenseRow row) {
    return Expense(
      id: row.id,
      title: row.title,
      amountCents: row.amountCents,
      category: row.category,
      date: row.date,
      createdAt: row.createdAt,
      note: row.note,
    );
  }
}
