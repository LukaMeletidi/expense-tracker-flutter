import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's home screen: the list of expenses.
///
/// Step 1 placeholder — it currently shows only the empty state. In step 5 it
/// becomes a ConsumerWidget that watches `expenseListProvider` and renders all
/// four states: loading, error, empty and data.
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No expenses yet.\nTap + to add your first one.',
            textAlign: TextAlign.center,
          ),
        ),
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
