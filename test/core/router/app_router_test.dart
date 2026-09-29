import 'package:expense_tracker/core/router/app_router.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the real app with a fresh router, so each test starts at '/'.
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(child: ExpenseTrackerApp(router: createAppRouter())),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the expense list', (tester) async {
    await pumpApp(tester);

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('the + button opens the add screen, and back returns', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Add expense'), findsOneWidget);

    // The back button exists because '/add' is pushed on top of the list.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Expenses'), findsOneWidget);
  });
}
