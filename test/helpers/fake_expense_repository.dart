import 'dart:async';

import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';

/// An in-memory [ExpenseRepository] for widget tests.
///
/// Widget tests run on a fake clock, where Drift's stream timers can leave
/// "Timer still pending" failures behind. This fake has no timers, and each
/// test can choose which state the list is in.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense> expenses = const []})
    : _expenses = [...expenses];

  final List<Expense> _expenses;
  final _changes = StreamController<List<Expense>>.broadcast();

  /// When true, watchAll never emits, so the list stays loading.
  bool neverEmits = false;

  /// When set, watchAll fails with this error.
  Object? watchError;

  /// When set, delete fails with this error.
  Object? deleteError;

  /// The ids passed to delete, in order.
  final List<int> deletedIds = [];

  @override
  Stream<List<Expense>> watchAll() {
    if (neverEmits) return StreamController<List<Expense>>().stream;
    if (watchError != null) return Stream.error(watchError!);
    return _currentThenChanges();
  }

  Stream<List<Expense>> _currentThenChanges() async* {
    yield List.unmodifiable(_expenses);
    yield* _changes.stream;
  }

  @override
  Future<void> delete(int id) async {
    if (deleteError != null) throw deleteError!;
    deletedIds.add(id);
    _expenses.removeWhere((e) => e.id == id);
    _changes.add(List.unmodifiable(_expenses));
  }

  @override
  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError('Not needed until the add form (step 5c).');
}
