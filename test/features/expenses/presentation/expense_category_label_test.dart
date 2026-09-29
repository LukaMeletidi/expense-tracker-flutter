import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each category has its own label', () {
    final labels = ExpenseCategory.values.map((c) => c.label).toList();

    expect(labels, [
      'Food',
      'Transport',
      'Bills',
      'Shopping',
      'Health',
      'Other',
    ]);
  });
}
