import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/route_paths.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common_widgets.dart';
import '../controllers/verification_controller.dart';

/// Runs the criminal-record screening using the scanned Aadhaar demographics.
class CriminalCheckScreen extends ConsumerWidget {
  const CriminalCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(verificationControllerProvider, (prev, next) {
      if (next.step == VerificationStep.payment && next.criminal != null) {
        context.pushReplacement(RoutePaths.payment);
      } else if (next.errorMessage != null) {
        showSnack(context, next.errorMessage!, isError: true);
      }
    });

    final state = ref.watch(verificationControllerProvider);
    final aadhaar = state.aadhaar;

    return Scaffold(
      appBar: AppBar(title: const Text('Criminal Record Check')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Subject',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(aadhaar?.name ?? '—',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    if (aadhaar?.dateOfBirth != null)
                      Text('DOB: ${aadhaar!.dateOfBirth}',
                          style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We will screen public court and criminal records for the '
                'subject above. This may take a few moments.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(verificationControllerProvider.notifier)
                        .runCriminalCheck(),
                icon: state.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.gavel),
                label: Text(state.isLoading ? 'Screening…' : 'Run Check'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
