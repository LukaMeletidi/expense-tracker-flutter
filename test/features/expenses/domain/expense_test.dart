import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

// Builds expenses with the constructor directly, so the equality tests
// do not depend on copyWith being correct.
Expense buildExpense({
  int id = 1,
  String title = 'Coffee',
  int amountCents = 450,
  ExpenseCategory category = ExpenseCategory.food,
  DateTime? date,
  DateTime? createdAt,
  String? note = 'Morning coffee',
}) {
  return Expense(
    id: id,
    title: title,
    amountCents: amountCents,
    category: category,
    date: date ?? DateTime(2026, 9, 1),
    createdAt: createdAt ?? DateTime(2026, 9, 1, 10, 0),
    note: note,
  );
}

void main() {
  final base = buildExpense();

  group('Expense equality', () {
    test('two expenses with the same fields are equal', () {
      final copy = buildExpense();
      expect(base, equals(copy));
      expect(base.hashCode, equals(copy.hashCode));
    });

    test('a different id makes them unequal', () {
      expect(base, isNot(equals(buildExpense(id: 2))));
    });

    test('a different title makes them unequal', () {
      expect(base, isNot(equals(buildExpense(title: 'Tea'))));
    });

    test('a different amountCents makes them unequal', () {
      expect(base, isNot(equals(buildExpense(amountCents: 500))));
    });

    test('a different category makes them unequal', () {
      expect(
        base,
        isNot(equals(buildExpense(category: ExpenseCategory.transport))),
      );
    });

    test('a different date makes them unequal', () {
      expect(base, isNot(equals(buildExpense(date: DateTime(2026, 9, 2)))));
    });

    test('a different createdAt makes them unequal', () {
      expect(
        base,
        isNot(equals(buildExpense(createdAt: DateTime(2026, 9, 1, 11, 0)))),
      );
    });

    test('a null note makes them unequal', () {
      expect(base, isNot(equals(buildExpense(note: null))));
    });
  });

  group('Expense.copyWith', () {
    test('with no arguments returns an equal copy', () {
      expect(base.copyWith(), equals(base));
    });

    test('changes only the given field', () {
      expect(
        base.copyWith(amountCents: 500),
        equals(buildExpense(amountCents: 500)),
      );
    });

    test('clearNote sets note to null and keeps the rest', () {
      expect(base.copyWith(clearNote: true), equals(buildExpense(note: null)));
    });

    test('passing a new note replaces it', () {
      expect(
        base.copyWith(note: 'Updated note'),
        equals(buildExpense(note: 'Updated note')),
      );
    });

    test('passing note: null keeps the old note', () {
      expect(base.copyWith(note: null).note, 'Morning coffee');
    });

    test('passing note together with clearNote is an error', () {
      expect(
        () => base.copyWith(note: 'x', clearNote: true),
        throwsAssertionError,
      );
    });
  });
}
