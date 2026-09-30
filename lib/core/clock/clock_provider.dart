import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gives the current time. Code reads "now" through this provider instead of
/// calling `DateTime.now()` directly, so tests can pin it to a fixed date and
/// do not start failing when the real month changes.
///
/// It provides a function rather than a `DateTime`: a provider's value is
/// computed once and kept, so a plain `DateTime` would freeze at app start.
/// Calling the function reads the time again every time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
