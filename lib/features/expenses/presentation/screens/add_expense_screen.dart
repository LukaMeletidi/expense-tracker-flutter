import 'package:expense_tracker/core/clock/clock_provider.dart';
import 'package:expense_tracker/core/formatting/money.dart';
import 'package:expense_tracker/features/expenses/domain/date_only.dart';
import 'package:expense_tracker/features/expenses/domain/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_form_rules.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "add an expense" screen.
///
/// What the user is typing (the text fields, the picked category and date,
/// whether a save is running) only matters while this screen is open, so it
/// lives in the widget's State. The rules live in expense_form_rules.dart,
/// and saving goes through [expenseListProvider].
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  late DateTime _date;
  bool _isSaving = false;

  /// Today, from clockProvider so tests can pin it.
  DateTime get _today => dateOnly(ref.read(clockProvider)());

  @override
  void initState() {
    super.initState();
    // A field initializer cannot use ref, so the default date is set here.
    _date = _today;
  }

  @override
  void dispose() {
    // Controllers hold resources, so they must be disposed with the screen.
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: _today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    // validate() runs every field's validator and shows the error messages.
    if (!_formKey.currentState!.validate()) return;

    // Disables the Save button, so a double tap cannot save twice.
    setState(() => _isSaving = true);
    try {
      await ref
          .read(expenseListProvider.notifier)
          .add(
            title: _titleController.text.trim(),
            // Safe: validateAmount already checked that this parses.
            amountCents: parseCents(_amountController.text)!,
            category: _category,
            date: _date,
            note: noteOrNull(_noteController.text),
          );
      // After an await the screen may be gone, so check before using context.
      if (mounted) context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save the expense.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    return Scaffold(
      // go_router gives this screen a back button automatically, because it
      // was pushed onto the stack by the list screen.
      appBar: AppBar(title: const Text('Add expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
              validator: validateTitle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: kSymbolBeforeAmount ? kCurrencySymbol : null,
                suffixText: kSymbolBeforeAmount ? null : kCurrencySymbol,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              validator: validateAmount,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final category in ExpenseCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (category) {
                if (category != null) setState(() => _category = category);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(localizations.formatShortDate(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              // null disables the button while saving.
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
