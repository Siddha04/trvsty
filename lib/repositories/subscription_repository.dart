import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/utils/result.dart';
import '../models/enums.dart';
import '../models/subscription_model.dart';

/// Manages business subscription lifecycle in the `subscriptions` collection.
abstract interface class SubscriptionRepository {
  Future<Result<SubscriptionModel>> activate({
    required String businessId,
    required SubscriptionTier tier,
    required String razorpayPaymentId,
  });

  Stream<SubscriptionModel?> watchActive(String businessId);
  List<SubscriptionPlan> get plans;
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  List<SubscriptionPlan> get plans => SubscriptionPlan.catalogue;

  @override
  Future<Result<SubscriptionModel>> activate({
    required String businessId,
    required SubscriptionTier tier,
    required String razorpayPaymentId,
  }) async {
    try {
      final now = DateTime.now();
      final docRef =
          _firestore.collection(FirestoreCollections.subscriptions).doc();
      final subscription = SubscriptionModel(
        id: docRef.id,
        businessId: businessId,
        tier: tier,
        startedAt: now,
        // 30-day billing cycle.
        expiresAt: now.add(const Duration(days: 30)),
        isActive: true,
        razorpayPaymentId: razorpayPaymentId,
      );

      final batch = _firestore.batch();
      batch.set(docRef, subscription.toFirestore());
      // Update the business tier + reset credits.
      final plan = SubscriptionPlan.catalogue.firstWhere(
        (p) => p.tier == tier,
        orElse: () => SubscriptionPlan.catalogue.first,
      );
      batch.set(
        _firestore.collection(FirestoreCollections.businesses).doc(businessId),
        {
          'tier': tier.name,
          'verificationsRemaining': plan.verificationsPerMonth,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      return Success(subscription);
    } catch (e) {
      return ResultFailure(PaymentFailure('Failed to activate subscription: $e'));
    }
  }

  @override
  Stream<SubscriptionModel?> watchActive(String businessId) => _firestore
      .collection(FirestoreCollections.subscriptions)
      .where('businessId', isEqualTo: businessId)
      .where('isActive', isEqualTo: true)
      .orderBy('expiresAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : SubscriptionModel.fromFirestore(snap.docs.first),);
}
