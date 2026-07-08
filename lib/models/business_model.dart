import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Business account. Mirrors a document in the `businesses` collection.
class BusinessModel extends Equatable {
  const BusinessModel({
    required this.id,
    required this.ownerUid,
    required this.companyName,
    this.gstin,
    this.contactEmail,
    this.contactPhone,
    this.tier = SubscriptionTier.free,
    this.verificationsRemaining = 0,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String id;
  final String ownerUid;
  final String companyName;
  final String? gstin;
  final String? contactEmail;
  final String? contactPhone;
  final SubscriptionTier tier;

  /// Remaining verification credits in the current billing cycle.
  final int verificationsRemaining;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  BusinessModel copyWith({
    String? companyName,
    String? gstin,
    String? contactEmail,
    String? contactPhone,
    SubscriptionTier? tier,
    int? verificationsRemaining,
    bool? isDeleted,
  }) =>
      BusinessModel(
        id: id,
        ownerUid: ownerUid,
        companyName: companyName ?? this.companyName,
        gstin: gstin ?? this.gstin,
        contactEmail: contactEmail ?? this.contactEmail,
        contactPhone: contactPhone ?? this.contactPhone,
        tier: tier ?? this.tier,
        verificationsRemaining:
            verificationsRemaining ?? this.verificationsRemaining,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'ownerUid': ownerUid,
        'companyName': companyName,
        'gstin': gstin,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'tier': tier.name,
        'verificationsRemaining': verificationsRemaining,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': isDeleted,
      };

  factory BusinessModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,) {
    final data = doc.data() ?? <String, dynamic>{};
    return BusinessModel(
      id: data['id'] as String? ?? doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      gstin: data['gstin'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      tier: SubscriptionTier.fromString(data['tier'] as String?),
      verificationsRemaining: data['verificationsRemaining'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, ownerUid, companyName, tier];
}
