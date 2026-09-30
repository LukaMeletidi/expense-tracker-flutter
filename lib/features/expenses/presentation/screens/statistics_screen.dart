import 'package:expense_tracker/core/formatting/money.dart';
import 'package:expense_tracker/features/expenses/domain/month_summary.dart';
import 'package:expense_tracker/features/expenses/presentation/expense_category_label.dart';
import 'package:expense_tracker/features/expenses/presentation/percent_label.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/month_summary_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/selected_month_provider.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/month_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The selected month's total, and how it splits across categories.
///
/// It shares the selected month with the list screen, so both always show
/// the same month. All numbers come from [monthSummaryProvider].
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(monthSummaryProvider);
    final monthName = MaterialLocalizations.of(
      context,
    ).formatMonthYear(ref.watch(selectedMonthProvider).firstDay);

    return Scaffold(
      // go_router adds a back button, because this screen is pushed on top
      // of the list.
      appBar: AppBar(title: const Text('Statistics')),
      body: Column(
        children: [
          const MonthBar(),
          Expanded(
            child: summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Couldn't load statistics.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        // The summary is built from the expense list, so
                        // reloading the list reloads the summary too.
                        onPressed: () => ref.invalidate(expenseListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (summary) => summary.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No expenses in $monthName.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _SummaryView(summary: summary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Total spent', style: textTheme.labelLarge),
        Text(formatCents(summary.totalCents), style: textTheme.headlineMedium),
        const SizedBox(height: 24),
        for (final total in summary.categories) _CategoryRow(total: total),
      ],
    );
  }
}

/// One category: its name and share, a bar as wide as the share, and the
/// amount.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.total});

  final CategoryTotal total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(total.category.label)),
              Text(percentLabel(total.share)),
            ],
          ),
          const SizedBox(height: 4),
          // The bar only repeats the percentage next to it, so screen
          // readers skip it instead of announcing an unlabelled box.
          ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                // The empty part of the bar ("track"), in a theme colour so
                // it works in light and dark mode.
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: total.share,
                  child: Container(color: colorScheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(formatCents(total.cents)),
        ],
      ),
    );
  }
}
