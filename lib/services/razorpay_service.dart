import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config/env_config.dart';
import '../constants/app_constants.dart';
import '../core/utils/app_logger.dart';

/// Outcome of a Razorpay checkout.
sealed class RazorpayResult {
  const RazorpayResult();
}

class RazorpaySuccess extends RazorpayResult {
  const RazorpaySuccess({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
  final String paymentId;
  final String? orderId;
  final String? signature;
}

class RazorpayError extends RazorpayResult {
  const RazorpayError({required this.code, required this.message});
  final int code;
  final String message;
}

class RazorpayExternalWallet extends RazorpayResult {
  const RazorpayExternalWallet(this.walletName);
  final String walletName;
}

/// Wraps the Razorpay checkout SDK behind a single `Future`-based call.
///
/// The SDK is callback-based and a single [Razorpay] instance can only run one
/// checkout at a time, so this service serialises checkouts via a [Completer].
///
/// SECURITY: The amount and order must be created on the backend; the
/// signature returned here MUST be verified server-side before the
/// verification is unlocked. Never trust client-side success alone.
class RazorpayService {
  RazorpayService() {
    _razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final Razorpay _razorpay = Razorpay();
  Completer<RazorpayResult>? _completer;

  /// Opens checkout for [amountPaise] and resolves with the [RazorpayResult].
  Future<RazorpayResult> openCheckout({
    required int amountPaise,
    required String orderId,
    required String name,
    required String description,
    required String contactPhone,
    String? email,
  }) {
    if (_completer != null && !_completer!.isCompleted) {
      return Future.value(
        const RazorpayError(code: -1, message: 'A payment is already in progress.'),
      );
    }
    _completer = Completer<RazorpayResult>();

    final options = {
      'key': EnvConfig.razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': AppConstants.appName,
      'order_id': orderId,
      'description': description,
      'prefill': {
        'contact': contactPhone,
        if (email != null) 'email': email,
      },
      'theme': {'color': '#00B4D8'},
      'timeout': 300,
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      AppLogger.e('Razorpay open failed', error: e);
      _completer!.complete(
        RazorpayError(code: -1, message: 'Could not start payment: $e'),
      );
    }
    return _completer!.future;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _completer?.complete(RazorpaySuccess(
      paymentId: response.paymentId ?? '',
      orderId: response.orderId,
      signature: response.signature,
    ),);
  }

  void _onError(PaymentFailureResponse response) {
    _completer?.complete(RazorpayError(
      code: response.code ?? -1,
      message: response.message ?? 'Payment failed.',
    ),);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _completer?.complete(RazorpayExternalWallet(response.walletName ?? 'wallet'));
  }

  /// Releases native resources. Call from the owning provider's dispose.
  void dispose() => _razorpay.clear();
}
