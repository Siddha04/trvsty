import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../models/enums.dart';
import '../../../models/subscription_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/common_widgets.dart';
import '../../payment/presentation/controllers/payment_controller.dart';

/// Business subscription catalogue with Razorpay checkout per plan.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  Future<void> _subscribe(
      BuildContext context, WidgetRef ref, SubscriptionPlan plan,) async {
    final auth = ref.read(authRepositoryProvider).currentUser;
    if (auth == null) return;

    final outcome = await ref.read(paymentControllerProvider.notifier).pay(
          userId: auth.uid,
          amountPaise: plan.pricePaise,
          purpose: 'subscription_${plan.tier.name}',
          contactPhone: auth.phoneNumber ?? '',
        );

    if (!context.mounted) return;

    switch (outcome) {
      case PaymentSucceeded(:final payment):
        // Activate the subscription for the business owned by this user.
        // Business id mirrors the owner uid for single-owner accounts.
        final result = await ref.read(subscriptionRepositoryProvider).activate(
              businessId: auth.uid,
              tier: plan.tier,
              razorpayPaymentId: payment.razorpayPaymentId ?? payment.id,
            );
        if (context.mounted) {
          result.fold(
            (f) => showSnack(context, f.message, isError: true),
            (_) => showSnack(context, '${plan.tier.label} plan activated!'),
          );
        }
      case PaymentFailedOutcome(:final message):
        showSnack(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(subscriptionRepositoryProvider).plans;
    final loading = ref.watch(paymentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Verify at scale. Choose a monthly plan for your business.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ...plans.map((plan) => _PlanCard(
                      plan: plan,
                      onSubscribe: () => _subscribe(context, ref, plan),
                    ),),
              ],
            ),
            if (loading)
              const LoadingOverlay(message: 'Processing payment…'),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onSubscribe});

  final SubscriptionPlan plan;
  final VoidCallback onSubscribe;

  bool get _highlighted => plan.tier == SubscriptionTier.professional;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan.tier.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20,),),
              if (_highlighted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('POPULAR',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,),),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.currency(plan.priceRupees),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cardForeground,),),
              const Text(' / month',
                  style: TextStyle(color: AppColors.cardMuted),),
            ],
          ),
          const SizedBox(height: 12),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 18,),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              child: Text('Subscribe to ${plan.tier.label}'),
            ),
          ),
        ],
      ),
    );
  }
}
