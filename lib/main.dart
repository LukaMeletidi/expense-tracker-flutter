import 'package:expense_tracker/core/router/app_router.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() {
  // ProviderScope is the storage every Riverpod provider lives in. It has to
  // wrap the whole app: without it, reading any provider throws.
  runApp(const ProviderScope(child: ExpenseTrackerApp()));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, this.router});

  /// Lets a test pass in its own router. The running app leaves this null and
  /// gets [appRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    // .router (instead of the plain MaterialApp) hands navigation over to
    // go_router, so screens are chosen by path rather than by Navigator calls.
    return MaterialApp.router(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      // Follow the phone's light/dark setting, and switch live when it changes.
      themeMode: ThemeMode.system,
      routerConfig: router ?? appRouter,
    );
  }
}
