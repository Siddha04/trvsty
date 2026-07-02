import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../models/enums.dart';
import '../../../models/trust_score.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common_widgets.dart';
import '../../verification/presentation/controllers/verification_controller.dart';

/// Static description of a service row on the home screen. Keeping this as
/// data (rather than one bespoke widget per row) means adding, reordering or
/// localising a service is a one-line change, not a new widget.
class _ServiceItem {
  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? route;
}

const _services = <_ServiceItem>[
  _ServiceItem(
    icon: Icons.qr_code_scanner,
    title: 'Aadhaar Secure QR',
    subtitle: 'Scan & verify a signed Aadhaar QR.',
  ),
  _ServiceItem(
    icon: Icons.face_retouching_natural,
    title: 'Face Match',
    subtitle: 'Match a live selfie to the Aadhaar photo.',
  ),
  _ServiceItem(
    icon: Icons.credit_card_outlined,
    title: 'PAN Verification',
    subtitle: 'Validate PAN and cross-check the name.',
  ),
  _ServiceItem(
    icon: Icons.gavel_outlined,
    title: 'Criminal Record Check',
    subtitle: 'Screen public court & criminal records.',
  ),
  _ServiceItem(
    icon: Icons.folder_shared,
    title: 'DigiLocker',
    subtitle: 'Pull documents with your consent.',
    route: RoutePaths.digilocker,
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _startVerification(BuildContext context, WidgetRef ref, UserType type) {
    HapticFeedback.selectionClick();
    ref.read(verificationControllerProvider.notifier).start(type);
    context.push(RoutePaths.scanAadhaar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(userProfileProvider).valueOrNull;
    final latestVerification = ref.watch(latestVerificationProvider).valueOrNull;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      FadeInContainer(
                        delay: const Duration(milliseconds: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name != null && user!.name!.trim().isNotEmpty
                                  ? 'Welcome back, ${user.name!.split(' ').first}'
                                  : 'Verify with Confidence',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Run a complete background verification in minutes.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // LATEST TRUST SCORE (only if the user has one)
                      if (latestVerification?.trustScore != null) ...[
                        const SizedBox(height: 20),
                        FadeInContainer(
                          delay: const Duration(milliseconds: 150),
                          child: _LatestScoreCard(
                            score: latestVerification!.trustScore!,
                            onTap: () => context.push(RoutePaths.history),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // PRIMARY CARDS (Individual / Business)
                      FadeInContainer(
                        delay: const Duration(milliseconds: 200),
                        child: isMobile
                            ? Column(
                                children: [
                                  _PrimaryCard(
                                    icon: Icons.person,
                                    title: 'Individual',
                                    subtitle: 'Verify a person',
                                    onTap: () => _startVerification(
                                        context, ref, UserType.individual,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _PrimaryCard(
                                    icon: Icons.business,
                                    title: 'Business',
                                    subtitle: 'Verify an organisation',
                                    onTap: () => _startVerification(
                                        context, ref, UserType.business,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _PrimaryCard(
                                      icon: Icons.person,
                                      title: 'Individual',
                                      subtitle: 'Verify a person',
                                      onTap: () => _startVerification(
                                          context, ref, UserType.individual,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _PrimaryCard(
                                      icon: Icons.business,
                                      title: 'Business',
                                      subtitle: 'Verify an organisation',
                                      onTap: () => _startVerification(
                                          context, ref, UserType.business,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 40),

                      // SERVICES HEADER
                      FadeInContainer(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          'Services',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SERVICE LIST (data-driven, full width)
                      FadeInContainer(
                        delay: const Duration(milliseconds: 400),
                        child: Column(
                          children: [
                            for (final service in _services) ...[
                              _ServiceCard(
                                item: service,
                                onTap: service.route == null
                                    ? null
                                    : () => context.push(service.route!),
                              ),
                              if (service != _services.last)
                                const SizedBox(height: 12),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), // Padding for bottom nav
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact shortcut into the user's most recent Trust Score, so a returning
/// user isn't looking at the exact same "start a new verification" screen
/// as someone who has never verified anything.
class _LatestScoreCard extends StatelessWidget {
  const _LatestScoreCard({required this.score, required this.onTap});

  final TrustScore score;
  final VoidCallback onTap;

  Color get _bandColor => switch (score.band) {
        TrustBand.high => AppColors.trustHigh,
        TrustBand.medium => AppColors.trustMedium,
        TrustBand.low => AppColors.trustLow,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Your latest Trust Score: ${score.value} out of 100, ${score.band.label}',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bandColor.withValues(alpha: 0.12),
                border: Border.all(color: _bandColor, width: 2),
              ),
              child: Text(
                '${score.value}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: _bandColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your latest Trust Score',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.band.label,
                    style: const TextStyle(color: AppColors.cardMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.cardMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

/// The top Individual / Business entry cards.
class _PrimaryCard extends StatelessWidget {
  const _PrimaryCard({
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
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.cardMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row in the "Services" list.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, this.onTap});

  final _ServiceItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${item.title}. ${item.subtitle}',
      child: AppCard(
        onTap: onTap ?? () => HapticFeedback.selectionClick(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.accent, size: 26),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(color: AppColors.cardMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (item.route != null) ...[
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_ios, color: AppColors.cardMuted, size: 14),
            ],
          ],
        ),
      ),
    );
  }
}
