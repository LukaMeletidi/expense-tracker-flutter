import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the light theme is light', () {
    expect(buildAppTheme(Brightness.light).brightness, Brightness.light);
  });

  test('the dark theme is dark', () {
    expect(buildAppTheme(Brightness.dark).brightness, Brightness.dark);
  });

  test('both themes are generated from the same seed colour', () {
    for (final brightness in Brightness.values) {
      expect(
        buildAppTheme(brightness).colorScheme,
        ColorScheme.fromSeed(seedColor: kSeedColor, brightness: brightness),
      );
    }
  });
}
