import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
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

  /// After saving, shows the month of the new expense, so an expense dated
  /// in another month does not seem to vanish from the list.
  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) async {
    await ref
        .read(expenseRepositoryProvider)
        .add(
          title: title,
          amountCents: amountCents,
          category: category,
          date: date,
          note: note,
        );
    // After an await this provider may have been disposed; ref must not be
    // used then.
    if (!ref.mounted) return;
    ref.read(selectedMonthProvider.notifier).select(CalendarMonth.of(date));
  }

  Future<void> delete(int id) {
    return ref.read(expenseRepositoryProvider).delete(id);
  }
}

final expenseListProvider =
    StreamNotifierProvider<ExpenseListNotifier, List<Expense>>(
      ExpenseListNotifier.new,
    );
