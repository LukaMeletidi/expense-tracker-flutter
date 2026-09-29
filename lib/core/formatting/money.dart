/// Money formatting for the whole app.
///
/// Amounts are stored as whole cents (an `int`) everywhere: `450` means 4.50.
/// Integers are used because `double` cannot represent money exactly
/// (`0.1 + 0.2 != 0.3`), so totals slowly drift as they add up.
///
/// This file is the ONLY place that turns cents into a display string, and
/// typed text back into cents. Nothing else in the app should build or parse
/// a money string by hand — that way changing the currency is a two-line
/// edit here instead of a hunt through every widget.
library;

/// The currency symbol shown to the user.
///
/// Change this one line to switch currency, e.g. '€' or '\$'.
const String kCurrencySymbol = '₾'; // GEL (Georgian lari)

/// Whether the symbol goes before the number (`₾4.50`) or after it (`4.50₾`).
const bool kSymbolBeforeAmount = true;

/// How many minor units make one major unit (100 cents = 1 lari).
const int kCentsPerUnit = 100;

/// Formats an amount held in cents as a display string.
///
/// ```dart
/// formatCents(450);     // '₾4.50'
/// formatCents(0);       // '₾0.00'
/// formatCents(-250);    // '-₾2.50'
/// ```
///
/// The optional parameters exist so tests (and any future per-account
/// currency) can override the defaults without editing this file.
String formatCents(
  int cents, {
  String symbol = kCurrencySymbol,
  bool symbolBefore = kSymbolBeforeAmount,
}) {
  // Handle the sign separately so we render '-₾2.50' rather than '₾-2.50'.
  final isNegative = cents < 0;
  final absoluteCents = cents.abs();

  final units = absoluteCents ~/ kCentsPerUnit;
  final remainder = absoluteCents % kCentsPerUnit;
  // padLeft keeps 5 cents as '05' instead of '5'.
  final amount = '$units.${remainder.toString().padLeft(2, '0')}';

  final withSymbol = symbolBefore ? '$symbol$amount' : '$amount$symbol';
  return isNegative ? '-$withSymbol' : withSymbol;
}

/// Whole units (1 to 12 digits), then optionally a dot and 1 or 2 decimals.
///
/// The 12-digit limit keeps `units * 100` far away from the largest `int`,
/// so a very long input cannot overflow into a wrong number.
final RegExp _amountPattern = RegExp(r'^(\d{1,12})(?:\.(\d{1,2}))?$');

/// Turns text the user typed into cents, or returns `null` if it is not a
/// valid amount. It is the opposite of [formatCents].
///
/// ```dart
/// parseCents('4.50');  // 450
/// parseCents('4,5');   // 450  (a comma works as the decimal separator)
/// parseCents(' 4 ');   // 400  (spaces around the number are ignored)
/// parseCents('4.505'); // null (more than 2 decimals)
/// parseCents('-4');    // null (expenses are never negative)
/// ```
///
/// Zero is a valid amount here (`'0'` gives `0`). Whether an expense may be
/// zero is a rule for the form, not for parsing.
int? parseCents(String input) {
  // Allow '4,50' as well as '4.50': many keyboards type a comma. A text
  // with both, like '1,234.50', becomes '1.234.50' and is rejected.
  final normalized = input.trim().replaceAll(',', '.');
  final match = _amountPattern.firstMatch(normalized);
  if (match == null) return null;

  final units = int.parse(match.group(1)!);
  // '5' after the dot means 50 cents, not 5, so pad it on the right.
  final cents = int.parse((match.group(2) ?? '').padRight(2, '0'));
  return units * kCentsPerUnit + cents;
}
