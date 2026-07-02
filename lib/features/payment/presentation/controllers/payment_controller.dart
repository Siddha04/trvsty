import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../models/payment_model.dart';
import '../../../../services/razorpay_service.dart';

/// Result emitted to the UI after a checkout attempt.
sealed class PaymentOutcome {
  const PaymentOutcome();
}

class PaymentSucceeded extends PaymentOutcome {
  const PaymentSucceeded(this.payment);
  final PaymentModel payment;
}

class PaymentFailedOutcome extends PaymentOutcome {
  const PaymentFailedOutcome(this.message);
  final String message;
}

/// Coordinates order creation, the Razorpay checkout and server-side
/// verification for a one-time verification payment.
class PaymentController extends StateNotifier<bool> {
  PaymentController(this._ref) : super(false);

  final Ref _ref;

  /// Runs the full pay → verify cycle for [amountPaise]. The boolean state is
  /// the loading flag.
  Future<PaymentOutcome> pay({
    required String userId,
    required int amountPaise,
    required String purpose,
    required String contactPhone,
    String? email,
  }) async {
    state = true;
    try {
      final repo = _ref.read(paymentRepositoryProvider);

      // 1. Create an order on the backend.
      final orderResult = await repo.createOrder(
        userId: userId,
        amountPaise: amountPaise,
        purpose: purpose,
      );
      final payment = orderResult.valueOrNull;
      if (payment == null || payment.razorpayOrderId == null) {
        return PaymentFailedOutcome(
            orderResult.fold((f) => f.message, (_) => 'Could not start payment.'));
      }

      // 2. Open Razorpay checkout.
      final checkout = await _ref.read(razorpayServiceProvider).openCheckout(
            amountPaise: amountPaise,
            orderId: payment.razorpayOrderId!,
            name: 'Trvsty Verification',
            description: purpose,
            contactPhone: contactPhone,
            email: email,
          );

      switch (checkout) {
        case RazorpaySuccess(:final paymentId, :final orderId, :final signature):
          // 3. Verify the signature server-side before unlocking.
          final verified = await repo.verifyAndCapture(
            payment: payment,
            razorpayPaymentId: paymentId,
            razorpayOrderId: orderId ?? payment.razorpayOrderId!,
            razorpaySignature: signature ?? '',
          );
          return verified.fold(
            (f) => PaymentFailedOutcome(f.message),
            (captured) => PaymentSucceeded(captured),
          );
        case RazorpayError(:final message):
          await repo.markFailed(payment, message);
          return PaymentFailedOutcome(message);
        case RazorpayExternalWallet(:final walletName):
          return PaymentFailedOutcome(
              'Complete the payment in $walletName and try again.');
      }
    } finally {
      state = false;
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, bool>((ref) => PaymentController(ref));
