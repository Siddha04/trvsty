import 'package:equatable/equatable.dart';

/// Computed trust score for a completed verification.
///
/// The score is a weighted aggregate (0–100) of the individual checks. The
/// weighting and computation live in `TrustScoreCalculator` (domain layer);
/// this model is the immutable result.
class TrustScore extends Equatable {
  const TrustScore({
    required this.value,
    required this.breakdown,
  });

  /// Final score, clamped to 0–100.
  final int value;

  /// Per-check contribution, e.g. {'Face Match': 30, 'PAN': 25}.
  final Map<String, int> breakdown;

  /// Qualitative band used for the verification badge.
  TrustBand get band {
    if (value >= 80) return TrustBand.high;
    if (value >= 50) return TrustBand.medium;
    return TrustBand.low;
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'breakdown': breakdown,
      };

  factory TrustScore.fromJson(Map<String, dynamic> json) => TrustScore(
        value: json['value'] as int? ?? 0,
        breakdown: (json['breakdown'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as int)),
      );

  @override
  List<Object?> get props => [value, breakdown];
}

enum TrustBand {
  low,
  medium,
  high;

  String get label => switch (this) {
        TrustBand.low => 'Low Trust',
        TrustBand.medium => 'Moderate Trust',
        TrustBand.high => 'Highly Trusted',
      };
}
