import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';

/// add and delete don't touch state directly — Drift's stream sends
/// the new list automatically after the database changes.
class ExpenseListNotifier extends StreamNotifier<List<Expense>> {
  /// Only the expenses of the selected month. Because the month is watched,
  /// choosing another month runs build() again with the new month.
  @override
  Stream<List<Expense>> build() {
    final month = ref.watch(selectedMonthProvider);
    return ref.watch(expenseRepositoryProvider).watchMonth(month);
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
