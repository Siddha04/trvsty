import '../../constants/app_constants.dart';
import '../../models/trust_score.dart';
import '../../models/verification_results.dart';

/// Computes a [TrustScore] (0–100) from the individual verification checks.
///
/// Weighting (sums to 100):
///   * Aadhaar QR authenticity .... 25  (valid signed QR scanned)
///   * Face match ................. 30  (scaled by confidence)
///   * PAN verification ........... 25  (valid + name match)
///   * Criminal record (clean) .... 20
///
/// Each check contributes its full weight only when it passes; partial credit
/// is awarded for face-match confidence. Missing/optional checks contribute 0
/// and are excluded from the breakdown so the badge stays honest.
class TrustScoreCalculator {
  const TrustScoreCalculator();

  static const int _aadhaarWeight = 25;
  static const int _faceWeight = 30;
  static const int _panWeight = 25;
  static const int _criminalWeight = 20;

  TrustScore calculate({
    required bool aadhaarVerified,
    FaceMatchResult? faceMatch,
    PanVerificationResult? pan,
    CriminalRecordResult? criminal,
  }) {
    final breakdown = <String, int>{};

    if (aadhaarVerified) {
      breakdown['Aadhaar'] = _aadhaarWeight;
    }

    if (faceMatch != null) {
      // Award proportional credit above the match threshold; below it, 0.
      if (faceMatch.isMatch) {
        final scaled = (faceMatch.confidence / 100 * _faceWeight).round();
        breakdown['Face Match'] = scaled.clamp(0, _faceWeight);
      } else {
        breakdown['Face Match'] = 0;
      }
    }

    if (pan != null) {
      var panScore = 0;
      if (pan.isValid) {
        // 70% of the weight for a valid PAN, the remaining 30% for a name match.
        panScore = (_panWeight * 0.7).round();
        if (pan.nameMatch == true) {
          panScore = _panWeight;
        }
      }
      breakdown['PAN'] = panScore;
    }

    if (criminal != null) {
      breakdown['Criminal Record'] =
          criminal.hasRecords ? 0 : _criminalWeight;
    }

    final total = breakdown.values.fold<int>(0, (sum, v) => sum + v);
    return TrustScore(value: total.clamp(0, 100), breakdown: breakdown);
  }

  /// Convenience: does the face-match confidence clear the configured bar?
  static bool isFacePass(double confidence) =>
      confidence >= AppConstants.faceMatchThreshold;
}
