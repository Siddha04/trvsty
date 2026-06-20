import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A payment transaction. Mirrors a document in the `payments` collection.
///
/// Amounts are stored in paise (the Razorpay convention) to avoid
/// floating-point rounding issues.
class PaymentModel extends Equatable {
  const PaymentModel({
    required this.id,
    required this.userId,
    required this.amountPaise,
    required this.status,
    required this.createdAt,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.purpose = 'individual_verification',
    this.verificationId,
    this.isDeleted = false,
  });

  final String id;
  final String userId;
  final int amountPaise;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String purpose;
  final String? verificationId;
  final bool isDeleted;

  double get amountRupees => amountPaise / 100;

  PaymentModel copyWith({
    PaymentStatus? status,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    String? verificationId,
  }) =>
      PaymentModel(
        id: id,
        userId: userId,
        amountPaise: amountPaise,
        status: status ?? this.status,
        createdAt: createdAt,
        razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
        razorpaySignature: razorpaySignature ?? this.razorpaySignature,
        purpose: purpose,
        verificationId: verificationId ?? this.verificationId,
        isDeleted: isDeleted,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'amountPaise': amountPaise,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
        'purpose': purpose,
        'verificationId': verificationId,
        'isDeleted': isDeleted,
      };

  factory PaymentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return PaymentModel(
      id: data['id'] as String? ?? doc.id,
      userId: data['userId'] as String? ?? '',
      amountPaise: data['amountPaise'] as int? ?? 0,
      status: PaymentStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      razorpayOrderId: data['razorpayOrderId'] as String?,
      razorpayPaymentId: data['razorpayPaymentId'] as String?,
      razorpaySignature: data['razorpaySignature'] as String?,
      purpose: data['purpose'] as String? ?? 'individual_verification',
      verificationId: data['verificationId'] as String?,
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, userId, amountPaise, status];
}
