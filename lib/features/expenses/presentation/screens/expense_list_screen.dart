import 'package:expense_tracker/core/formatting/money.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/month_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The app's home screen: the expenses of one month at a time.
///
/// It only reads [expenseListProvider] and [selectedMonthProvider] and calls
/// their notifiers; all data logic lives in the providers and the repository.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch (not read) so the screen rebuilds whenever a new list arrives.
    final expenses = ref.watch(expenseListProvider);
    final monthName = MaterialLocalizations.of(
      context,
    ).formatMonthYear(ref.watch(selectedMonthProvider).firstDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: () => context.push('/stats'),
            tooltip: 'Statistics',
            icon: const Icon(Icons.bar_chart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Outside the states below, so the month can be changed even while
          // loading or after an error.
          const MonthBar(),
          Expanded(
            // when() makes us handle every state; forgetting one will not
            // compile.
            child: expenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _ErrorView(
                // invalidate throws the current state away and runs build()
                // again.
                onRetry: () => ref.invalidate(expenseListProvider),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyView(monthName: monthName)
                  : _ExpenseList(expenses: items),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // go() swaps the current screen; push() stacks a new one on top so the
        // back button returns here. Adding is a sub-task of the list, so push.
        onPressed: () => context.push('/add'),
        tooltip: 'Add expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.monthName});

  final String monthName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No expenses in $monthName.\nTap + to add one.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Couldn't load expenses.", textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = MaterialLocalizations.of(context);

    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return Dismissible(
          // The key tells Flutter which row was swiped, even after the list
          // changes, so it must be unique and stable: the database id.
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          // The delete happens here, before the row is removed, so a failed
          // delete can return false and the row slides back into place.
          confirmDismiss: (_) => _delete(context, ref, expense),
          child: ListTile(
            title: Text(expense.title),
            subtitle: Text(
              '${expense.category.label} · '
              '${localizations.formatShortDate(expense.date)}',
            ),
            trailing: Text(formatCents(expense.amountCents)),
          ),
        );
      },
    );
  }

  Future<bool> _delete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    try {
      await ref.read(expenseListProvider.notifier).delete(expense.id);
      return true;
    } catch (_) {
      // After an await the screen may be gone, so check before using context.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete the expense.")),
        );
      }
      return false;
    }
  }
}
