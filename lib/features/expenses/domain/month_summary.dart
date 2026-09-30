import 'package:expense_tracker/features/expenses/domain/expense.dart';

/// How much was spent in one category.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.cents,
    required this.share,
  });

  final ExpenseCategory category;

  /// The category's total, in whole cents like every amount in the app.
  final int cents;

  /// This category's part of the month's total, from 0.0 to 1.0. Only used
  /// to draw bars and percentages; money itself always stays in cents.
  final double share;

  @override
  bool operator ==(Object other) =>
      other is CategoryTotal &&
      other.category == category &&
      other.cents == cents &&
      other.share == share;

  @override
  int get hashCode => Object.hash(category, cents, share);

  /// Makes test failures readable.
  @override
  String toString() => 'CategoryTotal(${category.name}, $cents, $share)';
}

/// The totals for a list of expenses, usually one month's.
class MonthSummary {
  const MonthSummary({required this.totalCents, required this.categories});

  final int totalCents;

  /// Largest first. Categories with nothing spent are left out.
  final List<CategoryTotal> categories;

  bool get isEmpty => categories.isEmpty;
}

/// Adds up [expenses] in total and per category.
MonthSummary summarize(List<Expense> expenses) {
  final centsByCategory = <ExpenseCategory, int>{};
  var totalCents = 0;
  for (final expense in expenses) {
    centsByCategory.update(
      expense.category,
      (cents) => cents + expense.amountCents,
      ifAbsent: () => expense.amountCents,
    );
    totalCents += expense.amountCents;
  }

  final categories = [
    for (final MapEntry(key: category, value: cents) in centsByCategory.entries)
      CategoryTotal(
        category: category,
        cents: cents,
        share: cents / totalCents,
      ),
  ];
  // Largest first. Dart's sort does not promise to keep equal items in
  // their original order, so ties are broken explicitly by the enum's order;
  // that way the result is always the same.
  categories.sort((a, b) {
    final byCents = b.cents.compareTo(a.cents);
    return byCents != 0
        ? byCents
        : a.category.index.compareTo(b.category.index);
  });

  return MonthSummary(totalCents: totalCents, categories: categories);
}
