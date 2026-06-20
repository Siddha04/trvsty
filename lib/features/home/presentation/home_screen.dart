import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_constants.dart';
import '../../../models/enums.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_widgets.dart';
import '../../verification/presentation/controllers/verification_controller.dart';

/// Home dashboard. Entry point for new verifications and quick navigation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _startVerification(BuildContext context, WidgetRef ref, UserType type) {
    ref.read(verificationControllerProvider.notifier).start(type);
    context.push(RoutePaths.scanAadhaar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => context.push(RoutePaths.history),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => context.push(RoutePaths.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Verify with Confidence',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Run a complete background verification in minutes.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _VerificationTypeCard(
                    icon: Icons.person,
                    title: 'Individual',
                    subtitle: 'Verify a person',
                    onTap: () =>
                        _startVerification(context, ref, UserType.individual),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VerificationTypeCard(
                    icon: Icons.business,
                    title: 'Business',
                    subtitle: 'Verify an organisation',
                    onTap: () =>
                        _startVerification(context, ref, UserType.business),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Services',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _ServiceTile(
              icon: Icons.qr_code_scanner,
              title: 'Aadhaar Secure QR',
              description: 'Scan & verify a signed Aadhaar QR.',
            ),
            _ServiceTile(
              icon: Icons.face,
              title: 'Face Match',
              description: 'Match a live selfie to the Aadhaar photo.',
            ),
            _ServiceTile(
              icon: Icons.credit_card,
              title: 'PAN Verification',
              description: 'Validate PAN and cross-check the name.',
            ),
            _ServiceTile(
              icon: Icons.gavel,
              title: 'Criminal Record Check',
              description: 'Screen public court & criminal records.',
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.push(RoutePaths.digilocker),
              child: Row(
                children: [
                  const Icon(Icons.folder_shared, color: AppColors.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Connect DigiLocker — pull documents with your consent.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              onTap: () => context.push(RoutePaths.subscriptions),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.accent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Business plans — verify at scale with monthly credits.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTypeCard extends StatelessWidget {
  const _VerificationTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accent.withOpacity(0.12),
            child: Icon(icon, color: AppColors.accent, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
