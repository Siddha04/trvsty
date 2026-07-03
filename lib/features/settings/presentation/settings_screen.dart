import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_widgets.dart';

/// App settings: privacy controls, legal links and the DPDP data-erasure flow.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account & data?'),
        content: const Text(
          'Under the DPDP Act, 2023 you may request erasure of your personal '
          'data. Your account and verification history will be marked deleted '
          'and removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid != null) {
      await ref.read(userRepositoryProvider).softDelete(uid);
    }
    await ref.read(secureStorageProvider).clearAll();
    await ref.read(authRepositoryProvider).signOut();
    if (context.mounted) context.go(RoutePaths.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Privacy & Data'),
            AppCard(
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => _open(AppConstants.privacyPolicyUrl),
                  ),
                  const Divider(),
                  _Tile(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => _open(AppConstants.termsUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const _SectionHeader('Support'),
            AppCard(
              child: _Tile(
                icon: Icons.mail_outline,
                label: 'Contact Support',
                onTap: () => _open('mailto:${AppConstants.supportEmail}'),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionHeader('Account'),
            AppCard(
              child: _Tile(
                icon: Icons.delete_forever,
                label: 'Delete account & data',
                color: AppColors.error,
                onTap: () => _deleteAccount(context, ref),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Trvsty v1.0.0',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Text(title,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: color ?? AppColors.cardForeground)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cardMuted),
          ],
        ),
      ),
    );
  }
}
