import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../verification/presentation/controllers/verification_controller.dart';
import '../controllers/payment_controller.dart';

/// Payment summary + Razorpay checkout for a one-time verification.
class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({super.key});

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authRepositoryProvider).currentUser;
    if (auth == null) {
      context.go(RoutePaths.login);
      return;
    }

    const amountPaise =
        AppConstants.individualVerificationPrice * AppConstants.paisePerRupee;

    final outcome = await ref.read(paymentControllerProvider.notifier).pay(
          userId: auth.uid,
          amountPaise: amountPaise,
          purpose: 'individual_verification',
          contactPhone: auth.phoneNumber ?? '',
        );

    if (!context.mounted) return;

    switch (outcome) {
      case PaymentSucceeded(:final payment):
        await ref.read(verificationControllerProvider.notifier).finalize(
              userId: auth.uid,
              paymentId: payment.id,
            );
        if (context.mounted) context.pushReplacement(RoutePaths.result);
      case PaymentFailedOutcome(:final message):
        showSnack(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(paymentControllerProvider);
    const price = AppConstants.individualVerificationPrice;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    const Text('Verification Report',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18,),),
                    const SizedBox(height: 16),
                    _row('Aadhaar Secure QR', 'Included'),
                    _row('Face Match', 'Included'),
                    _row('PAN Verification', 'Included'),
                    _row('Criminal Record Check', 'Included'),
                    const Divider(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16,),),
                        Text(Formatters.currency(price),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.cardForeground,),),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Icon(Icons.lock, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments are processed securely by Razorpay. Trvsty never '
                      'stores your card details.',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : () => _pay(context, ref),
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,),)
                    : Text('Pay ${Formatters.currency(price)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.cardForeground)),
            Text(value, style: const TextStyle(color: AppColors.success)),
          ],
        ),
      );
}
