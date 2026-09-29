/// Returns local midnight of the calendar day that [value] falls on.
///
/// An expense's `date` is a day, not a moment, so the time part is thrown
/// away. The value is converted to local time first, because "which day"
/// depends on where the user is: 21:30 UTC on 1 September is already
/// 01:30 on 2 September in Tbilisi (UTC+4).
///
/// ```dart
/// dateOnly(DateTime(2026, 9, 1, 18, 45)); // DateTime(2026, 9, 1)
/// ```
DateTime dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
