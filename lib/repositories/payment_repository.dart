import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../config/env_config.dart';
import '../constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import '../models/enums.dart';
import '../models/payment_model.dart';
import '../services/firestore_service.dart';

/// Handles payment record persistence and server-side signature verification.
///
/// Order creation and signature verification MUST happen on the backend
/// (Cloud Function) because they require the Razorpay key secret. This
/// repository talks to that backend endpoint and records the outcome in
/// Firestore.
abstract interface class PaymentRepository {
  Future<Result<PaymentModel>> createOrder({
    required String userId,
    required int amountPaise,
    required String purpose,
  });

  Future<Result<PaymentModel>> verifyAndCapture({
    required PaymentModel payment,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  });

  Future<Result<PaymentModel>> markFailed(PaymentModel payment, String reason);

  Stream<List<PaymentModel>> watchPayments(String userId);
}

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({
    required FirestoreService firestore,
    required Dio dio,
  })  : _firestore = firestore,
        _dio = dio;

  final FirestoreService _firestore;
  final Dio _dio;

  @override
  Future<Result<PaymentModel>> createOrder({
    required String userId,
    required int amountPaise,
    required String purpose,
  }) async {
    try {
      // Ask the backend to create a Razorpay order (key secret stays server-side).
      final response = await _dio.post<Map<String, dynamic>>(
        '${EnvConfig.paymentVerifyEndpoint}/createOrder',
        data: {'amount': amountPaise, 'currency': 'INR', 'userId': userId},
      );
      final orderId = response.data?['orderId'] as String?;
      if (orderId == null) {
        return const ResultFailure(PaymentFailure('Could not create order.'));
      }

      final payment = PaymentModel(
        id: _firestore.newId(FirestoreCollections.payments),
        userId: userId,
        amountPaise: amountPaise,
        status: PaymentStatus.created,
        createdAt: DateTime.now(),
        razorpayOrderId: orderId,
        purpose: purpose,
      );
      await _firestore
          .doc(FirestoreCollections.payments, payment.id)
          .set(payment.toFirestore());
      return Success(payment);
    } catch (e, st) {
      AppLogger.e('createOrder failed', error: e, stackTrace: st);
      return ResultFailure(PaymentFailure('Could not start payment: $e'));
    }
  }

  @override
  Future<Result<PaymentModel>> verifyAndCapture({
    required PaymentModel payment,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      // Server verifies HMAC signature with the key secret.
      final response = await _dio.post<Map<String, dynamic>>(
        EnvConfig.paymentVerifyEndpoint,
        data: {
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
        },
      );
      final verified = response.data?['verified'] as bool? ?? false;
      if (!verified) {
        await markFailed(payment, 'Signature verification failed.');
        return const ResultFailure(
            PaymentFailure('Payment could not be verified.'),);
      }

      final captured = payment.copyWith(
        status: PaymentStatus.captured,
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );
      await _firestore
          .doc(FirestoreCollections.payments, payment.id)
          .set(captured.toFirestore(), SetOptions(merge: true));
      await _firestore.log(
        action: 'payment_captured',
        userId: payment.userId,
        metadata: {'paymentId': payment.id, 'amountPaise': payment.amountPaise},
      );
      return Success(captured);
    } catch (e, st) {
      AppLogger.e('verifyAndCapture failed', error: e, stackTrace: st);
      return ResultFailure(PaymentFailure('Payment verification error: $e'));
    }
  }

  @override
  Future<Result<PaymentModel>> markFailed(
      PaymentModel payment, String reason,) async {
    try {
      final failed = payment.copyWith(status: PaymentStatus.failed);
      await _firestore.doc(FirestoreCollections.payments, payment.id).set(
        {...failed.toFirestore(), 'failureReason': reason},
        SetOptions(merge: true),
      );
      return Success(failed);
    } catch (e) {
      return ResultFailure(PaymentFailure('Failed to record payment status: $e'));
    }
  }

  @override
  Stream<List<PaymentModel>> watchPayments(String userId) => _firestore
      .collection(FirestoreCollections.payments)
      .where('userId', isEqualTo: userId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(PaymentModel.fromFirestore).toList(growable: false),);
}
