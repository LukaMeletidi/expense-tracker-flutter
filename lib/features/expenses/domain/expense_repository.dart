import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchAll();

  /// Like [watchAll], but only the expenses whose date is in [month].
  Stream<List<Expense>> watchMonth(CalendarMonth month);

  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  });

  Future<void> delete(int id);
}
