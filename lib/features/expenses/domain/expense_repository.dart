import 'package:expense_tracker/features/expenses/domain/expense.dart';

abstract class ExpenseRepository {
  Stream<List<Expense>> watchAll();

  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  });

  Future<void> delete(int id);
}
