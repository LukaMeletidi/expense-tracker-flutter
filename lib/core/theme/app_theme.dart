import 'package:flutter/material.dart';

/// The one colour every other colour in the app is generated from.
///
/// Light and dark themes share it, so both look like the same app.
const Color kSeedColor = Colors.teal;

/// Builds the app's theme for [brightness].
///
/// Screens never hard-code colours; they read them from the theme's
/// `colorScheme` (for example `colorScheme.error`). That is why a dark theme
/// works on every screen without changing any of them.
ThemeData buildAppTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: brightness,
    ),
  );
}
