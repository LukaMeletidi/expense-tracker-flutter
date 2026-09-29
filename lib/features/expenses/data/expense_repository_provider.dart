import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expense_tracker/core/database/database_provider.dart';
import 'package:expense_tracker/features/expenses/data/drift_expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/expense_repository.dart';

/// Typed as the interface, not the Drift class, so nothing that reads
/// this provider knows Drift is behind it.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftExpenseRepository(db);
});
