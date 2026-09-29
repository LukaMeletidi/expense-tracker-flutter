import 'dart:async';

import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';

/// An in-memory [ExpenseRepository] for widget tests.
///
/// Widget tests run on a fake clock, where Drift's stream timers can leave
/// "Timer still pending" failures behind. This fake has no timers, and each
/// test can choose which state the list is in.
class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense> expenses = const []})
    : _expenses = [...expenses],
      _nextId =
          expenses.fold(0, (highest, e) => e.id > highest ? e.id : highest) + 1;

  final List<Expense> _expenses;
  final _changes = StreamController<List<Expense>>.broadcast();
  int _nextId;

  /// The expenses currently stored, for tests to inspect.
  List<Expense> get expenses => List.unmodifiable(_expenses);

  /// When true, watchAll and watchMonth never emit, so the list stays loading.
  bool neverEmits = false;

  /// When set, watchAll and watchMonth fail with this error.
  Object? watchError;

  /// When set, delete fails with this error.
  Object? deleteError;

  /// The ids passed to delete, in order.
  final List<int> deletedIds = [];

  /// When set, add fails with this error.
  Object? addError;

  /// When set, add waits for this to complete, so a test can look at the
  /// screen while a save is still in progress.
  Completer<void>? addGate;

  /// How many times add was called, including failed calls.
  int addCalls = 0;

  @override
  Stream<List<Expense>> watchAll() => _watch((_) => true);

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      _watch((expense) => CalendarMonth.of(expense.date) == month);

  /// The stored expenses that pass [include], then again after every change.
  Stream<List<Expense>> _watch(bool Function(Expense expense) include) {
    if (neverEmits) return StreamController<List<Expense>>().stream;
    if (watchError != null) return Stream.error(watchError!);
    return _currentThenChanges().map(
      (all) => List.unmodifiable(all.where(include)),
    );
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
  }) async {
    addCalls++;
    await addGate?.future;
    if (addError != null) throw addError!;
    _expenses.add(
      Expense(
        id: _nextId++,
        title: title,
        amountCents: amountCents,
        category: category,
        date: date,
        // The fake has no clock; tests do not check createdAt.
        createdAt: DateTime(2026, 1, 1),
        note: note,
      ),
    );
    _changes.add(List.unmodifiable(_expenses));
  }
}
