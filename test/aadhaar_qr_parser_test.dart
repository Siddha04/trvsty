import 'package:flutter_test/flutter_test.dart';
import 'package:trusty/core/error/exceptions.dart';
import 'package:trusty/services/aadhaar_qr_parser.dart';

void main() {
  const parser = AadhaarQrParser();

  group('AadhaarQrParser (legacy XML)', () {
    test('parses demographic attributes and derives last 4 digits', () {
      const xml = '<?xml version="1.0" encoding="UTF-8"?>'
          '<PrintLetterBarcodeData uid="123456789012" name="Asha Rao" '
          'gender="F" dob="01-01-1990" house="12" street="MG Road" '
          'vtc="Bengaluru" pc="560001" state="Karnataka" dist="Bengaluru"/>';

      final data = parser.parse(xml);

      expect(data.name, 'Asha Rao');
      expect(data.gender, 'F');
      expect(data.dateOfBirth, '01-01-1990');
      expect(data.last4Digits, '9012');
      expect(data.maskedAadhaar, 'XXXX XXXX 9012');
      expect(data.pincode, '560001');
      expect(data.state, 'Karnataka');
    });

    test('throws on empty payload', () {
      expect(() => parser.parse('   '), throwsA(isA<VerificationException>()));
    });

    test('throws on unrecognised payload', () {
      expect(
        () => parser.parse('not-xml-not-a-number'),
        throwsA(isA<VerificationException>()),
      );
    });
  });
}
