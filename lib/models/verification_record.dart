import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'aadhaar_data.dart';
import 'enums.dart';
import 'trust_score.dart';
import 'verification_results.dart';

/// A complete verification record persisted in `verification_history`.
///
/// This is the aggregate produced by the verification pipeline and the source
/// document for the generated PDF report.
class VerificationRecord extends Equatable {
  const VerificationRecord({
    required this.id,
    required this.userId,
    required this.subjectType,
    required this.status,
    required this.createdAt,
    this.aadhaar,
    this.faceMatch,
    this.pan,
    this.bank,
    this.criminal,
    this.trustScore,
    this.paymentId,
    this.isDeleted = false,
  });

  final String id;
  final String userId;
  final UserType subjectType;
  final VerificationStatus status;
  final DateTime createdAt;

  final AadhaarData? aadhaar;
  final FaceMatchResult? faceMatch;
  final PanVerificationResult? pan;
  final BankVerificationResult? bank;
  final CriminalRecordResult? criminal;
  final TrustScore? trustScore;
  final String? paymentId;
  final bool isDeleted;

  /// Short, human-shareable verification id (used on the badge & PDF).
  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  VerificationRecord copyWith({
    VerificationStatus? status,
    AadhaarData? aadhaar,
    FaceMatchResult? faceMatch,
    PanVerificationResult? pan,
    BankVerificationResult? bank,
    CriminalRecordResult? criminal,
    TrustScore? trustScore,
    String? paymentId,
    bool? isDeleted,
  }) =>
      VerificationRecord(
        id: id,
        userId: userId,
        subjectType: subjectType,
        status: status ?? this.status,
        createdAt: createdAt,
        aadhaar: aadhaar ?? this.aadhaar,
        faceMatch: faceMatch ?? this.faceMatch,
        pan: pan ?? this.pan,
        bank: bank ?? this.bank,
        criminal: criminal ?? this.criminal,
        trustScore: trustScore ?? this.trustScore,
        paymentId: paymentId ?? this.paymentId,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'subjectType': subjectType.name,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'aadhaar': aadhaar?.toJson(),
        'faceMatch': faceMatch?.toJson(),
        'pan': pan?.toJson(),
        'bank': bank?.toJson(),
        'criminal': criminal?.toJson(),
        'trustScore': trustScore?.toJson(),
        'paymentId': paymentId,
        'isDeleted': isDeleted,
      };

  factory VerificationRecord.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    Map<String, dynamic>? sub(String key) =>
        data[key] != null ? Map<String, dynamic>.from(data[key] as Map) : null;

    return VerificationRecord(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      subjectType: UserType.fromString(data['subjectType'] as String?),
      status: VerificationStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aadhaar: sub('aadhaar') != null ? AadhaarData.fromJson(sub('aadhaar')!) : null,
      faceMatch:
          sub('faceMatch') != null ? FaceMatchResult.fromJson(sub('faceMatch')!) : null,
      pan: sub('pan') != null ? PanVerificationResult.fromJson(sub('pan')!) : null,
      bank: sub('bank') != null ? BankVerificationResult.fromJson(sub('bank')!) : null,
      criminal: sub('criminal') != null
          ? CriminalRecordResult.fromJson(sub('criminal')!)
          : null,
      trustScore:
          sub('trustScore') != null ? TrustScore.fromJson(sub('trustScore')!) : null,
      paymentId: data['paymentId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, userId, status, trustScore];
}
