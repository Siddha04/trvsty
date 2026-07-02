import 'package:flutter_test/flutter_test.dart';
import 'package:trvsty/core/domain/trust_score_calculator.dart';
import 'package:trvsty/models/trust_score.dart';
import 'package:trvsty/models/verification_results.dart';

void main() {
  const calculator = TrustScoreCalculator();

  group('TrustScoreCalculator', () {
    test('returns 0 when no checks are present', () {
      final score = calculator.calculate(aadhaarVerified: false);
      expect(score.value, 0);
      expect(score.breakdown, isEmpty);
      expect(score.band, TrustBand.low);
    });

    test('awards full weight for a perfect verification', () {
      final score = calculator.calculate(
        aadhaarVerified: true,
        faceMatch: const FaceMatchResult(confidence: 100, isMatch: true),
        pan: const PanVerificationResult(
          panNumber: 'ABCDE1234F',
          nameOnPan: 'John Doe',
          isValid: true,
          nameMatch: true,
        ),
        criminal: const CriminalRecordResult(hasRecords: false, recordCount: 0),
      );
      expect(score.value, 100);
      expect(score.band, TrustBand.high);
    });

    test('penalises adverse criminal records', () {
      final score = calculator.calculate(
        aadhaarVerified: true,
        criminal: const CriminalRecordResult(hasRecords: true, recordCount: 2),
      );
      // Only Aadhaar (25) counts; criminal contributes 0.
      expect(score.value, 25);
      expect(score.breakdown['Criminal Record'], 0);
    });

    test('scales face-match contribution by confidence', () {
      final score = calculator.calculate(
        aadhaarVerified: false,
        faceMatch: const FaceMatchResult(confidence: 80, isMatch: true),
      );
      // 80% of the 30-point face weight = 24.
      expect(score.breakdown['Face Match'], 24);
    });

    test('valid PAN without a name match earns partial credit', () {
      final score = calculator.calculate(
        aadhaarVerified: false,
        pan: const PanVerificationResult(
          panNumber: 'ABCDE1234F',
          nameOnPan: 'Someone Else',
          isValid: true,
          nameMatch: false,
        ),
      );
      // 70% of the 25-point PAN weight = 18 (rounded).
      expect(score.breakdown['PAN'], 18);
    });

    test('band thresholds are correct', () {
      expect(const TrustScore(value: 85, breakdown: {}).band, TrustBand.high);
      expect(const TrustScore(value: 60, breakdown: {}).band, TrustBand.medium);
      expect(const TrustScore(value: 30, breakdown: {}).band, TrustBand.low);
    });
  });
}
