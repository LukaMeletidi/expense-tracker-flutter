import 'package:expense_tracker/features/expenses/presentation/expense_form_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateTitle', () {
    test('accepts a title', () {
      expect(validateTitle('Coffee'), isNull);
    });

    test('rejects an empty title', () {
      expect(validateTitle(''), 'Enter a title');
    });

    test('rejects a title of only spaces', () {
      expect(validateTitle('   '), 'Enter a title');
    });

    test('rejects null', () {
      expect(validateTitle(null), 'Enter a title');
    });
  });

  group('validateAmount', () {
    test('accepts a valid amount', () {
      expect(validateAmount('4.50'), isNull);
    });

    test('asks for an amount when empty', () {
      expect(validateAmount(''), 'Enter an amount');
      expect(validateAmount('  '), 'Enter an amount');
      expect(validateAmount(null), 'Enter an amount');
    });

    test('rejects text that is not an amount', () {
      expect(validateAmount('abc'), 'Enter a valid amount, like 4.50');
    });

    test('rejects zero', () {
      expect(validateAmount('0'), 'The amount must be more than 0');
      expect(validateAmount('0.00'), 'The amount must be more than 0');
    });

    test('accepts the smallest amount, one cent', () {
      expect(validateAmount('0.01'), isNull);
    });
  });

  group('noteOrNull', () {
    test('keeps a note, trimmed', () {
      expect(noteOrNull('  Morning coffee '), 'Morning coffee');
    });

    test('turns an empty note into null', () {
      expect(noteOrNull(''), isNull);
      expect(noteOrNull('   '), isNull);
    });
  });
}
