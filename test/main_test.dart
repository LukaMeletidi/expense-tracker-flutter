import 'package:expense_tracker/core/router/app_router.dart';
import 'package:expense_tracker/features/expenses/data/expense_repository_provider.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_expense_repository.dart';

/// Pumps the real app with the phone set to [brightness].
Future<void> pumpAppWithBrightness(
  WidgetTester tester,
  Brightness brightness,
) async {
  // Pretends the phone's system setting is light or dark.
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
      ],
      child: ExpenseTrackerApp(router: createAppRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

/// The theme a real screen is drawn with, read from the list's app bar.
ThemeData themeOnScreen(WidgetTester tester) {
  return Theme.of(tester.element(find.text('Expenses')));
}

void main() {
  testWidgets('uses the dark theme when the phone is in dark mode', (
    tester,
  ) async {
    await pumpAppWithBrightness(tester, Brightness.dark);

    expect(themeOnScreen(tester).brightness, Brightness.dark);
  });

  testWidgets('uses the light theme when the phone is in light mode', (
    tester,
  ) async {
    await pumpAppWithBrightness(tester, Brightness.light);

    expect(themeOnScreen(tester).brightness, Brightness.light);
  });
}
