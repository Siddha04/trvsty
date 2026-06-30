import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Result of a SurePass PAN verification call.
class PanVerificationResult extends Equatable {
  const PanVerificationResult({
    required this.panNumber,
    required this.nameOnPan,
    required this.isValid,
    this.category,
    this.nameMatch,
  });

  final String panNumber;
  final String nameOnPan;
  final bool isValid;
  final String? category;

  /// Whether the PAN holder name matched the Aadhaar name (when cross-checked).
  final bool? nameMatch;

  CheckResult get result => isValid ? CheckResult.pass : CheckResult.fail;

  Map<String, dynamic> toJson() => {
        'panNumber': panNumber,
        'nameOnPan': nameOnPan,
        'isValid': isValid,
        'category': category,
        'nameMatch': nameMatch,
      };

  factory PanVerificationResult.fromJson(Map<String, dynamic> json) =>
      PanVerificationResult(
        panNumber: json['panNumber'] as String? ?? '',
        nameOnPan: json['nameOnPan'] as String? ?? '',
        isValid: json['isValid'] as bool? ?? false,
        category: json['category'] as String?,
        nameMatch: json['nameMatch'] as bool?,
      );

  @override
  List<Object?> get props => [panNumber, isValid, nameMatch];
}

/// Result of a face-match comparison between the QR photo and a live selfie.
class FaceMatchResult extends Equatable {
  const FaceMatchResult({
    required this.confidence,
    required this.isMatch,
  });

  /// Match confidence as a percentage (0–100).
  final double confidence;
  final bool isMatch;

  CheckResult get result => isMatch ? CheckResult.pass : CheckResult.fail;

  Map<String, dynamic> toJson() => {
        'confidence': confidence,
        'isMatch': isMatch,
      };

  factory FaceMatchResult.fromJson(Map<String, dynamic> json) => FaceMatchResult(
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        isMatch: json['isMatch'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [confidence, isMatch];
}

/// Result of a criminal-record / court-record screening.
class CriminalRecordResult extends Equatable {
  const CriminalRecordResult({
    required this.hasRecords,
    required this.recordCount,
    this.records = const [],
  });

  /// `true` when one or more adverse records were found.
  final bool hasRecords;
  final int recordCount;
  final List<String> records;

  /// A clean record is a "pass".
  CheckResult get result => hasRecords ? CheckResult.fail : CheckResult.pass;

  Map<String, dynamic> toJson() => {
        'hasRecords': hasRecords,
        'recordCount': recordCount,
        'records': records,
      };

  factory CriminalRecordResult.fromJson(Map<String, dynamic> json) =>
      CriminalRecordResult(
        hasRecords: json['hasRecords'] as bool? ?? false,
        recordCount: json['recordCount'] as int? ?? 0,
        records: (json['records'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  @override
  List<Object?> get props => [hasRecords, recordCount];
}

/// Result of a bank account / UPI penny drop verification.
class BankVerificationResult extends Equatable {
  const BankVerificationResult({
    required this.accountNumber,
    required this.ifsc,
    required this.registeredName,
    required this.isNameMatch,
  });

  final String accountNumber;
  final String ifsc;
  final String registeredName;
  final bool isNameMatch;

  CheckResult get result => isNameMatch ? CheckResult.pass : CheckResult.fail;

  Map<String, dynamic> toJson() => {
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        'registeredName': registeredName,
        'isNameMatch': isNameMatch,
      };

  factory BankVerificationResult.fromJson(Map<String, dynamic> json) =>
      BankVerificationResult(
        accountNumber: json['accountNumber'] as String? ?? '',
        ifsc: json['ifsc'] as String? ?? '',
        registeredName: json['registeredName'] as String? ?? '',
        isNameMatch: json['isNameMatch'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [accountNumber, ifsc, registeredName, isNameMatch];
}
