enum ExpenseCategory { food, transport, bills, shopping, health, other }

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.category,
    required this.date,
    required this.createdAt,
    this.note,
  });

  final int id;
  final String title;
  final int amountCents;
  final ExpenseCategory category;
  final DateTime date;
  final DateTime createdAt;
  final String? note;

  Expense copyWith({
    int? id,
    String? title,
    int? amountCents,
    ExpenseCategory? category,
    DateTime? date,
    DateTime? createdAt,
    String? note,
    bool clearNote = false,
  }) {
    assert(
      !(clearNote && note != null),
      'Pass either note or clearNote: true, not both.',
    );
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense &&
        other.id == id &&
        other.title == title &&
        other.amountCents == amountCents &&
        other.category == category &&
        other.date == date &&
        other.createdAt == createdAt &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, amountCents, category, date, createdAt, note);
}

abstract class ExpenseRepository {
  Stream<List<Expense>> watchAll();

  Future<void> add({
    required String title,
    required int amountCents,
    required ExpenseCategory category,
    required DateTime date,
    String? note,
  });

  Future<void> delete(int id);
}