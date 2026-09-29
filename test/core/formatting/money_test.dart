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

  group('parseCents', () {
    test('parses an amount with two decimals', () {
      expect(parseCents('4.50'), 450);
    });

    test('parses a whole amount', () {
      expect(parseCents('4'), 400);
    });

    test('reads one decimal as tens of cents', () {
      // '4.5' is 4.50, not 4.05.
      expect(parseCents('4.5'), 450);
    });

    test('keeps a leading zero in the cents', () {
      expect(parseCents('0.05'), 5);
    });

    test('accepts a comma as the decimal separator', () {
      expect(parseCents('4,50'), 450);
    });

    test('ignores spaces around the number', () {
      expect(parseCents('  4.50 '), 450);
    });

    test('parses zero', () {
      expect(parseCents('0'), 0);
    });

    test('parses a large amount', () {
      expect(parseCents('12345.67'), 1234567);
    });

    test('accepts 12 whole digits', () {
      expect(parseCents('999999999999.99'), 99999999999999);
    });

    test('is the opposite of formatCents', () {
      expect(parseCents(formatCents(1234567, symbol: '')), 1234567);
    });

    for (final invalid in [
      '',
      '   ',
      'abc',
      '4.50abc',
      '-4',
      '+4',
      '4.505',
      '4.',
      '.5',
      '1,234.50',
      '1 000',
      '₾4.50',
      '1234567890123',
    ]) {
      test('rejects "$invalid"', () {
        expect(parseCents(invalid), isNull);
      });
    }
  });
}
