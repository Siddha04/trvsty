import 'package:flutter_test/flutter_test.dart';
import 'package:trvsty/utils/formatters.dart';
import 'package:trvsty/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts a valid 10-digit Indian number', () {
      expect(Validators.phone('9876543210'), isNull);
    });
    test('rejects numbers starting below 6', () {
      expect(Validators.phone('1234567890'), isNotNull);
    });
    test('rejects wrong length', () {
      expect(Validators.phone('98765'), isNotNull);
    });
  });

  group('Validators.pan', () {
    test('accepts a valid PAN', () {
      expect(Validators.pan('ABCDE1234F'), isNull);
    });
    test('is case-insensitive', () {
      expect(Validators.pan('abcde1234f'), isNull);
    });
    test('rejects malformed PAN', () {
      expect(Validators.pan('AB1234CDEF'), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('accepts 6 digits', () => expect(Validators.otp('123456'), isNull));
    test('rejects 5 digits', () => expect(Validators.otp('12345'), isNotNull));
  });

  group('Formatters masking', () {
    test('masks Aadhaar to last 4 digits', () {
      expect(Formatters.maskAadhaar('123456789012'), 'XXXX XXXX 9012');
    });
    test('masks PAN keeping first 2 and last 1', () {
      expect(Formatters.maskPan('ABCDE1234F'), 'ABXXXXXF');
    });
  });
}
