import 'package:expense_tracker/core/formatting/money.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';
import 'package:flutter/material.dart';

/// Opens a read-only bottom sheet with every detail of [expense].
///
/// It is given the expense the list row already has, so there is nothing to
/// load and nothing that can fail: no loading or error state is needed.
/// Swipe down, tap outside or press Back to close it.
Future<void> showExpenseDetails(BuildContext context, Expense expense) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Lets a long note make the sheet taller than the default half screen,
    // up to the limit below; beyond that its content scrolls.
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (context) => ExpenseDetails(expense: expense),
  );
}

/// The sheet's content: title, amount, category, date and the full note.
///
/// Read-only on purpose: there are no text fields and no buttons. The note
/// is selectable so it can be copied, but it cannot be changed.
class ExpenseDetails extends StatelessWidget {
  const ExpenseDetails({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final note = expense.note;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.title, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(formatCents(expense.amountCents), style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(expense.category.label, style: textTheme.bodyLarge),
            Text(
              // e.g. "Tuesday, September 1, 2026": more detail than the
              // list row's short date.
              MaterialLocalizations.of(context).formatFullDate(expense.date),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Text('Note', style: textTheme.labelLarge),
            const SizedBox(height: 4),
            if (note == null)
              Text(
                'No note',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              // The whole note, with its line breaks: no maxLines and no
              // "…". Selectable so it can be copied; SelectableText is
              // always read-only.
              SelectableText(note, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
