import 'dart:async';

import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/database_provider.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A container whose database lives in memory. Only the database is
/// replaced, so the real repository and list providers are under test.
/// ProviderContainer.test disposes the container (and so closes the
/// database) when the test ends.
ProviderContainer createContainer() {
  return ProviderContainer.test(
    overrides: [
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase(NativeDatabase.memory());
        ref.onDispose(db.close);
        return db;
      }),
    ],
  );
}

/// Waits until expenseListProvider holds a list that passes [condition].
///
/// Drift sends the new list a moment after a change, so reading the
/// provider straight after add or delete could still see the old list.
Future<List<Expense>> waitForList(
  ProviderContainer container,
  bool Function(List<Expense> expenses) condition,
) {
  final completer = Completer<List<Expense>>();
  final subscription = container.listen(expenseListProvider, (_, next) {
    final expenses = next.value;
    if (expenses != null && condition(expenses) && !completer.isCompleted) {
      completer.complete(expenses);
    }
  }, fireImmediately: true);
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(subscription.close);
}

/// A repository whose stream always fails, to test the error state.
class FailingExpenseRepository implements ExpenseRepository {
  @override
  Stream<List<Expense>> watchAll() => Stream.error(Exception('disk full'));

  @override
  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(int id) => throw UnimplementedError();
}

void main() {
  test('starts loading, then holds an empty list', () async {
    final container = createContainer();

    expect(container.read(expenseListProvider).isLoading, isTrue);
    expect(await waitForList(container, (_) => true), isEmpty);
  });

  test('add makes the expense appear with every field', () async {
    final container = createContainer();

    await container
        .read(expenseListProvider.notifier)
        .add(
          title: 'Coffee',
          amountCents: 450,
          category: ExpenseCategory.food,
          date: DateTime(2026, 9, 1),
          note: 'Morning coffee',
        );

    final expenses = await waitForList(container, (e) => e.length == 1);
    final saved = expenses.single;
    // createdAt comes from the real clock, so it is not checked here.
    expect(saved.title, 'Coffee');
    expect(saved.amountCents, 450);
    expect(saved.category, ExpenseCategory.food);
    expect(saved.date, DateTime(2026, 9, 1));
    expect(saved.note, 'Morning coffee');
  });

  test('delete makes the expense disappear', () async {
    final container = createContainer();
    final notifier = container.read(expenseListProvider.notifier);

    await notifier.add(
      title: 'Coffee',
      amountCents: 450,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 1),
    );
    final added = await waitForList(container, (e) => e.length == 1);

    await notifier.delete(added.single.id);

    expect(await waitForList(container, (e) => e.isEmpty), isEmpty);
  });

  test('a failing repository puts the list into the error state', () async {
    final container = ProviderContainer.test(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(FailingExpenseRepository()),
      ],
      // Riverpod 3 retries failed providers by default; turn that off so
      // no retry timer is left running after the test.
      retry: (_, _) => null,
    );
    // Riverpod 3 pauses a provider nobody listens to, so its stream would
    // never run. Listening here plays the part of a screen watching it.
    container.listen(expenseListProvider, (_, _) {});

    await expectLater(
      container.read(expenseListProvider.future),
      throwsA(isA<Exception>()),
    );
    expect(container.read(expenseListProvider).hasError, isTrue);
  });
}
