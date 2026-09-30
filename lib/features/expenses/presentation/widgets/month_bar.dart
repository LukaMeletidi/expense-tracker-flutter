import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ◀ September 2026 ▶: moves the selected month back or forward.
///
/// Shared by every screen that shows one month at a time. It lives in this
/// feature, not in core/, because it depends on [selectedMonthProvider].
class MonthBar extends ConsumerWidget {
  const MonthBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the month makes this rebuild on every change, so canGoNext
    // is read again each time the month moves.
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: notifier.previous,
            tooltip: 'Show previous month',
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              MaterialLocalizations.of(context).formatMonthYear(month.firstDay),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            // null disables the button: there is no month after the current one.
            onPressed: notifier.canGoNext ? notifier.next : null,
            tooltip: 'Show next month',
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
