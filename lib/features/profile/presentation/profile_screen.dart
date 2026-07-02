import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_widgets.dart';

/// User profile: shows account details and primary account actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to verify with OTP again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => ErrorView(message: '$e'),
          data: (user) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.accent.withOpacity(0.15),
                  child: const Icon(Icons.person,
                      size: 48, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?.name ?? 'Trvsty User',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text('+91 ${user?.phoneNumber.replaceFirst('+91', '') ?? ''}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.badge,
                        label: 'Account type',
                        value: user?.userType.label ?? '—'),
                    const Divider(),
                    _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user?.email ?? 'Not set'),
                    const Divider(),
                    _InfoRow(
                        icon: Icons.verified_user,
                        label: 'Consent',
                        value: (user?.consentAccepted ?? false)
                            ? 'Granted'
                            : 'Pending'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                onTap: () => context.push(RoutePaths.history),
                child: const _MenuRow(
                    icon: Icons.history, label: 'Verification History'),
              ),
              AppCard(
                onTap: () => context.push(RoutePaths.subscriptions),
                child: const _MenuRow(
                    icon: Icons.workspace_premium, label: 'Subscription Plans'),
              ),
              AppCard(
                onTap: () => context.push(RoutePaths.settings),
                child: const _MenuRow(icon: Icons.settings, label: 'Settings'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text.rich(
                  TextSpan(
                    text: 'Powered by ',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'welldropp',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.cardMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(width: 16),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        const Icon(Icons.chevron_right, color: AppColors.cardMuted),
      ],
    );
  }
}
