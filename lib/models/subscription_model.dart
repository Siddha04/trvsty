import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Static definition of a subscription plan (catalogue entry).
class SubscriptionPlan extends Equatable {
  const SubscriptionPlan({
    required this.tier,
    required this.pricePaise,
    required this.verificationsPerMonth,
    required this.features,
  });

  final SubscriptionTier tier;
  final int pricePaise;
  final int verificationsPerMonth;
  final List<String> features;

  double get priceRupees => pricePaise / 100;

  /// The canonical Trvsty plan catalogue.
  static const List<SubscriptionPlan> catalogue = [
    SubscriptionPlan(
      tier: SubscriptionTier.starter,
      pricePaise: 99900,
      verificationsPerMonth: 25,
      features: [
        '25 verifications / month',
        'Aadhaar + PAN + Face Match',
        'PDF reports',
        'Email support',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.professional,
      pricePaise: 299900,
      verificationsPerMonth: 100,
      features: [
        '100 verifications / month',
        'All Starter features',
        'Criminal record check',
        'Priority support',
        'Bulk export',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.enterprise,
      pricePaise: 999900,
      verificationsPerMonth: 1000,
      features: [
        '1000 verifications / month',
        'All Professional features',
        'DigiLocker integration',
        'Dedicated account manager',
        'API access',
      ],
    ),
  ];

  @override
  List<Object?> get props => [tier, pricePaise, verificationsPerMonth];
}

/// An active subscription. Mirrors a document in the `subscriptions` collection.
class SubscriptionModel extends Equatable {
  const SubscriptionModel({
    required this.id,
    required this.businessId,
    required this.tier,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
    this.razorpayPaymentId,
    this.isDeleted = false,
  });

  final String id;
  final String businessId;
  final SubscriptionTier tier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;
  final String? razorpayPaymentId;
  final bool isDeleted;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'businessId': businessId,
        'tier': tier.name,
        'startedAt': Timestamp.fromDate(startedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'isActive': isActive,
        'razorpayPaymentId': razorpayPaymentId,
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': isDeleted,
      };

  factory SubscriptionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SubscriptionModel(
      id: data['id'] as String? ?? doc.id,
      businessId: data['businessId'] as String? ?? '',
      tier: SubscriptionTier.fromString(data['tier'] as String?),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? false,
      razorpayPaymentId: data['razorpayPaymentId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, businessId, tier, isActive, expiresAt];
}
