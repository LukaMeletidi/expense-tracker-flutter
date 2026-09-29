import 'package:expense_tracker/core/formatting/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatCents', () {
    test('formats a normal amount', () {
      expect(formatCents(450), '₾4.50');
    });

    test('formats zero with two decimals', () {
      expect(formatCents(0), '₾0.00');
    });

    test('pads single-digit cents', () {
      // 5 cents must render as '0.05', not '0.5'.
      expect(formatCents(5), '₾0.05');
    });

    test('formats a large amount', () {
      expect(formatCents(1234567), '₾12345.67');
    });

    test('puts the minus sign before the symbol', () {
      expect(formatCents(-250), '-₾2.50');
    });

    test('can place the symbol after the amount', () {
      expect(formatCents(450, symbolBefore: false), '4.50₾');
    });

    test('can use a different symbol', () {
      expect(formatCents(450, symbol: '€'), '€4.50');
    });
  });
}
