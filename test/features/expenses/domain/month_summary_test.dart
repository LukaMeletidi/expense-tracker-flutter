import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

var _nextId = 1;

/// An expense where only the category and amount matter.
Expense expense(ExpenseCategory category, int amountCents) {
  return Expense(
    id: _nextId++,
    title: 'Test',
    amountCents: amountCents,
    category: category,
    date: DateTime(2026, 9, 1),
    createdAt: DateTime(2026, 9, 1, 10, 0),
  );
}

void main() {
  test('no expenses give an empty summary', () {
    final summary = summarize([]);

    expect(summary.totalCents, 0);
    expect(summary.categories, isEmpty);
    expect(summary.isEmpty, isTrue);
  });

  test('one expense is the whole total', () {
    final summary = summarize([expense(ExpenseCategory.food, 450)]);

    expect(summary.totalCents, 450);
    expect(summary.categories, [
      const CategoryTotal(
        category: ExpenseCategory.food,
        cents: 450,
        share: 1.0,
      ),
    ]);
    expect(summary.isEmpty, isFalse);
  });

  test('expenses in the same category are added together', () {
    final summary = summarize([
      expense(ExpenseCategory.food, 450),
      expense(ExpenseCategory.food, 1050),
    ]);

    expect(summary.totalCents, 1500);
    expect(summary.categories.single.cents, 1500);
  });

  test('categories are sorted largest first, with their shares', () {
    final summary = summarize([
      expense(ExpenseCategory.transport, 1260),
      expense(ExpenseCategory.health, 7500),
      expense(ExpenseCategory.shopping, 9500),
    ]);

    expect(summary.totalCents, 18260);
    expect(summary.categories, [
      const CategoryTotal(
        category: ExpenseCategory.shopping,
        cents: 9500,
        share: 9500 / 18260,
      ),
      const CategoryTotal(
        category: ExpenseCategory.health,
        cents: 7500,
        share: 7500 / 18260,
      ),
      const CategoryTotal(
        category: ExpenseCategory.transport,
        cents: 1260,
        share: 1260 / 18260,
      ),
    ]);
  });

  test('a tie keeps the order of the categories in the enum', () {
    // Bills is added first, but food comes before bills in the enum.
    final summary = summarize([
      expense(ExpenseCategory.bills, 500),
      expense(ExpenseCategory.food, 500),
    ]);

    expect(summary.categories.map((c) => c.category), [
      ExpenseCategory.food,
      ExpenseCategory.bills,
    ]);
  });

  test('categories without expenses are left out', () {
    final summary = summarize([expense(ExpenseCategory.health, 7500)]);

    expect(summary.categories.map((c) => c.category), [ExpenseCategory.health]);
  });

  test('the shares add up to 1', () {
    final summary = summarize([
      expense(ExpenseCategory.food, 333),
      expense(ExpenseCategory.transport, 333),
      expense(ExpenseCategory.other, 334),
    ]);

    final totalShare = summary.categories.fold(0.0, (sum, c) => sum + c.share);
    // closeTo: fractions like 1/3 cannot be stored exactly as a double.
    expect(totalShare, closeTo(1.0, 1e-9));
  });
}
