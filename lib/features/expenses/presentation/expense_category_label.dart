import 'package:expense_tracker/features/expenses/domain/expense.dart';

/// The text shown to the user for each category.
///
/// This lives in presentation, not in the enum itself, because wording is
/// a UI concern: the domain only needs to know the categories exist.
extension ExpenseCategoryLabel on ExpenseCategory {
  String get label => switch (this) {
    ExpenseCategory.food => 'Food',
    ExpenseCategory.transport => 'Transport',
    ExpenseCategory.bills => 'Bills',
    ExpenseCategory.shopping => 'Shopping',
    ExpenseCategory.health => 'Health',
    ExpenseCategory.other => 'Other',
  };
}
