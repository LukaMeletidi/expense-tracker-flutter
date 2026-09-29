import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';

/// add and delete don't touch state directly — Drift's stream sends
/// the new list automatically after the database changes.
class ExpenseListNotifier extends StreamNotifier<List<Expense>> {
  @override
  Stream<List<Expense>> build() {
    return ref.watch(expenseRepositoryProvider).watchAll();
  }

  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) {
    return ref
        .read(expenseRepositoryProvider)
        .add(
          title: title,
          amountCents: amountCents,
          category: category,
          date: date,
          note: note,
        );
  }

  Future<void> delete(int id) {
    return ref.read(expenseRepositoryProvider).delete(id);
  }
}

final expenseListProvider =
    StreamNotifierProvider<ExpenseListNotifier, List<Expense>>(
      ExpenseListNotifier.new,
    );
