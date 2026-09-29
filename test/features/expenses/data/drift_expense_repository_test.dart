import 'dart:async';

import 'package:drift/native.dart';
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/features/expenses/data/drift_expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DriftExpenseRepository repo;
  // Whole seconds, because Drift stores createdAt as seconds.
  late DateTime now;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 9, 1, 10, 0);
    repo = DriftExpenseRepository(db, now: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  Future<List<String>> titles() async {
    final expenses = await repo.watchAll().first;
    return expenses.map((e) => e.title).toList();
  }

  test('starts with no expenses', () async {
    expect(await repo.watchAll().first, isEmpty);
  });

  test('an added expense comes back with every field', () async {
    await repo.add(
      title: 'Coffee',
      amountCents: 450,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 1),
      note: 'Morning coffee',
    );

    expect(await repo.watchAll().first, [
      Expense(
        id: 1,
        title: 'Coffee',
        amountCents: 450,
        category: ExpenseCategory.food,
        date: DateTime(2026, 9, 1),
        createdAt: DateTime(2026, 9, 1, 10, 0),
        note: 'Morning coffee',
      ),
    ]);
  });

  test('the time of day is dropped from date', () async {
    await repo.add(
      title: 'Dinner',
      amountCents: 2500,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 1, 18, 45),
    );

    final saved = (await repo.watchAll().first).single;
    expect(saved.date, DateTime(2026, 9, 1));
  });

  test('a missing note is stored as null', () async {
    await repo.add(
      title: 'Bus',
      amountCents: 100,
      category: ExpenseCategory.transport,
      date: DateTime(2026, 9, 1),
    );

    final saved = (await repo.watchAll().first).single;
    expect(saved.note, isNull);
  });

  test('orders by date, then by createdAt, newest first', () async {
    await repo.add(
      title: 'Older day',
      amountCents: 100,
      category: ExpenseCategory.other,
      date: DateTime(2026, 9, 1),
    );
    await repo.add(
      title: 'Newer day',
      amountCents: 100,
      category: ExpenseCategory.other,
      date: DateTime(2026, 9, 2),
    );
    now = DateTime(2026, 9, 1, 11, 0);
    await repo.add(
      title: 'Older day, saved later',
      amountCents: 100,
      category: ExpenseCategory.other,
      date: DateTime(2026, 9, 1),
    );

    expect(await titles(), ['Newer day', 'Older day, saved later', 'Older day']);
  });

  test('delete removes only the given expense', () async {
    await repo.add(
      title: 'Keep',
      amountCents: 100,
      category: ExpenseCategory.other,
      date: DateTime(2026, 9, 1),
    );
    await repo.add(
      title: 'Remove',
      amountCents: 100,
      category: ExpenseCategory.other,
      date: DateTime(2026, 9, 2),
    );
    final toRemove = (await repo.watchAll().first).firstWhere(
      (e) => e.title == 'Remove',
    );

    await repo.delete(toRemove.id);

    expect(await titles(), ['Keep']);
  });

  test('deleting an unknown id does nothing', () async {
    await expectLater(repo.delete(999), completes);
  });

  test('watchAll emits again after an add', () async {
    // StreamIterator reads the stream one list at a time, so the test can
    // wait for the first (empty) list before adding anything.
    final lists = StreamIterator(repo.watchAll());

    expect(await lists.moveNext(), isTrue);
    expect(lists.current, isEmpty);

    await repo.add(
      title: 'Coffee',
      amountCents: 450,
      category: ExpenseCategory.food,
      date: DateTime(2026, 9, 1),
    );

    expect(await lists.moveNext(), isTrue);
    expect(lists.current.single.title, 'Coffee');

    await lists.cancel();
  });
}
