/// The rules for the add-expense form, kept out of the widget so they can be
/// unit tested without building any UI.
///
/// The validators follow Flutter's form convention: return `null` when the
/// value is fine, or the error message to show under the field.
library;

import 'package:expense_tracker/core/formatting/money.dart';

String? validateTitle(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter a title';
  return null;
}

String? validateAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 'Enter an amount';
  final cents = parseCents(value);
  if (cents == null) return 'Enter a valid amount, like 4.50';
  if (cents == 0) return 'The amount must be more than 0';
  return null;
}

/// The note to save: trimmed, or `null` when nothing was typed, so an empty
/// note is stored the same way as no note at all.
String? noteOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
