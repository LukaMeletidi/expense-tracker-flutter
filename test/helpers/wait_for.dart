import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Waits until [provider] holds a value that passes [condition], and
/// returns that value.
///
/// Drift answers a moment after each change, so reading a provider straight
/// after an add or delete could still see the old value. Listening until the
/// condition is met avoids that race. Fails after 5 seconds instead of
/// hanging if the value never arrives.
///
/// [T] is worked out from [provider]: waitFor(container, expenseListProvider,
/// ...) returns a `List<Expense>`, waitFor(container, monthSummaryProvider,
/// ...) a `MonthSummary`.
Future<T> waitFor<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
  bool Function(T value) condition,
) {
  final completer = Completer<T>();
  final subscription = container.listen(provider, (_, next) {
    final value = next.value;
    if (value != null && condition(value) && !completer.isCompleted) {
      completer.complete(value);
    }
  }, fireImmediately: true);
  return completer.future
      .timeout(const Duration(seconds: 5))
      .whenComplete(subscription.close);
}
