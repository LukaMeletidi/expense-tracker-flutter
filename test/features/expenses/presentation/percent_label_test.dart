import 'package:expense_tracker/features/expenses/presentation/percent_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds to a whole percentage', () {
    expect(percentLabel(0.5203), '52%');
    expect(percentLabel(0.069), '7%');
  });

  test('shows the whole total as 100%', () {
    expect(percentLabel(1.0), '100%');
  });

  test('shows a small but real share as <1%', () {
    expect(percentLabel(0.004), '<1%');
  });

  test('rounds a share of just under 1% up to 1%', () {
    expect(percentLabel(0.006), '1%');
  });

  test('shows nothing at all as 0%', () {
    expect(percentLabel(0.0), '0%');
  });
}
