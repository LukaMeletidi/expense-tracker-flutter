/// Turns a share from 0.0 to 1.0 into a whole-number percentage, like '52%'.
///
/// A small but real share, such as 0.3%, would round to '0%' and look like
/// nothing was spent, so it is shown as '<1%' instead.
String percentLabel(double share) {
  final percent = (share * 100).round();
  if (percent == 0 && share > 0) return '<1%';
  return '$percent%';
}
