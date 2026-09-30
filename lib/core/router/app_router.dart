import 'package:expense_tracker/features/expenses/presentation/screens/add_expense_screen.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/expense_list_screen.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/statistics_screen.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's route table.
///
/// go_router is "declarative": instead of calling Navigator.push with a widget,
/// you give every screen a path and navigate by path (`context.push('/add')`).
/// Keeping the table here means no screen needs to know about any other screen.
///
/// This is a function rather than a single global so that each test can build
/// its own router. A shared one would carry navigation state from one test into
/// the next, making tests pass or fail depending on their order.
GoRouter createAppRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'expenses',
      builder: (context, state) => const ExpenseListScreen(),
      routes: [
        // A child route, so its full path is '/add'. Nesting it under '/' says
        // "adding happens on top of the list", which is also why the back
        // button returns to the list.
        GoRoute(
          path: 'add',
          name: 'addExpense',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        // '/stats', also on top of the list, for the same reason.
        GoRoute(
          path: 'stats',
          name: 'statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
      ],
    ),
  ],
);

/// The single router instance the running app uses.
final GoRouter appRouter = createAppRouter();
