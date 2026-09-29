import 'package:drift/drift.dart';
import 'package:expense_tracker/features/expenses/data/calendar_day_converter.dart';
import 'package:expense_tracker/features/expenses/data/expenses_table.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';

part 'app_database.g.dart';

/// The app's single SQLite database.
///
/// It takes a [QueryExecutor] so the caller decides where the data lives:
/// the app passes a real database file, tests pass `NativeDatabase.memory()`.
@DriftDatabase(tables: [Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
