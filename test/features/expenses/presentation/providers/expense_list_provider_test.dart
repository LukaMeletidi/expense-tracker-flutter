import 'dart:async';

import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/features/expenses/domain/calendar_month.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/in_memory_container.dart';
import '../../../../helpers/wait_for.dart';

/// A repository whose stream always fails, to test the error state.
class FailingExpenseRepository implements ExpenseRepository {
  @override
  Stream<List<Expense>> watchAll() => Stream.error(Exception('disk full'));

  @override
  Stream<List<Expense>> watchMonth(CalendarMonth month) =>
      Stream.error(Exception('disk full'));

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
    final container = createInMemoryContainer();

    expect(container.read(expenseListProvider).isLoading, isTrue);
    expect(await waitFor(container, expenseListProvider, (_) => true), isEmpty);
  });

  test('add makes the expense appear with every field', () async {
    final container = createInMemoryContainer();

    await container
        .read(expenseListProvider.notifier)
        .add(
          title: 'Coffee',
          amountCents: 450,
          category: ExpenseCategory.food,
          date: DateTime(2026, 9, 1),
          note: 'Morning coffee',
        );

    final expenses = await waitFor(
      container,
      expenseListProvider,
      (e) => e.length == 1,
    );
    final saved = expenses.single;
    // createdAt comes from the real clock, so it is not checked here.
    expect(saved.title, 'Coffee');
    expect(saved.amountCents, 450);
    expect(saved.category, ExpenseCategory.food);
    expect(saved.date, DateTime(2026, 9, 1));
    expect(saved.note, 'Morning coffee');
  });

  test('delete makes the expense disappear', () async {
    final container = createInMemoryContainer();
    final notifier = container.read(expenseListProvider.notifier);

    await notifier.add(
      title: 'Coffee',
      amountCents: 450,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 1),
    );
    final added = await waitFor(
      container,
      expenseListProvider,
      (e) => e.length == 1,
    );

    await notifier.delete(added.single.id);

    expect(
      await waitFor(container, expenseListProvider, (e) => e.isEmpty),
      isEmpty,
    );
  });

  test('shows only the selected month, and follows a month change', () async {
    final container = createInMemoryContainer();
    final notifier = container.read(expenseListProvider.notifier);
    // August first: adding switches to the new expense's month, so the
    // September expense, added last, leaves September selected.
    for (final (title, date) in [
      ('August', DateTime(2026, 8, 31)),
      ('September', DateTime(2026, 9, 1)),
    ]) {
      await notifier.add(
        title: title,
        amountCents: 100,
        category: ExpenseCategory.other,
        date: date,
      );
    }

    // On the clock's month: only the September expense.
    final september = await waitFor(
      container,
      expenseListProvider,
      (e) => e.isNotEmpty && e.every((x) => x.title == 'September'),
    );
    expect(september.map((e) => e.title), ['September']);

    container.read(selectedMonthProvider.notifier).previous();

    final august = await waitFor(
      container,
      expenseListProvider,
      (e) => e.isNotEmpty && e.every((x) => x.title == 'August'),
    );
    expect(august.map((e) => e.title), ['August']);
  });

  test('adding an expense in another month switches to that month', () async {
    final container = createInMemoryContainer();
    // Listen, so the list provider stays active the way it does on screen.
    container.listen(expenseListProvider, (_, _) {});
    expect(container.read(selectedMonthProvider), const CalendarMonth(2026, 9));

    await container
        .read(expenseListProvider.notifier)
        .add(
          title: 'Rent',
          amountCents: 50000,
          category: ExpenseCategory.bills,
          date: DateTime(2026, 8, 1),
        );

    expect(container.read(selectedMonthProvider), const CalendarMonth(2026, 8));
    final expenses = await waitFor(
      container,
      expenseListProvider,
      (e) => e.isNotEmpty,
    );
    expect(expenses.single.title, 'Rent');
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
