/// Money formatting for the whole app.
///
/// Amounts are stored as whole cents (an `int`) everywhere: `450` means 4.50.
/// Integers are used because `double` cannot represent money exactly
/// (`0.1 + 0.2 != 0.3`), so totals slowly drift as they add up.
///
/// This file is the ONLY place that turns cents into a display string.
/// Nothing else in the app should build a money string by hand — that way
/// changing the currency is a two-line edit here instead of a hunt through
/// every widget.
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
