import 'package:expense_tracker/features/expenses/domain/month_summary.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The totals for the selected month.
///
/// Built on top of [expenseListProvider] instead of querying the database
/// again, so it follows the selected month and every add or delete on its
/// own. whenData keeps the list's loading and error states and only turns
/// the data (the list of expenses) into a summary.
final monthSummaryProvider = Provider<AsyncValue<MonthSummary>>(
  (ref) => ref.watch(expenseListProvider).whenData(summarize),
);
