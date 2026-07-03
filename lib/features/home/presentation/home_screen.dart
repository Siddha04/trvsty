import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_spacing.dart';
import '../../../core/providers/app_providers.dart';
import '../../../models/enums.dart';
import '../../../models/trust_score.dart';
import '../../../models/user_model.dart';
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
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: AppSpacing.xl,
        title: isDesktop ? null : Row(
          children: [
            // ── Logo mark ──────────────────────────────────────────────
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // ── Wordmark ───────────────────────────────────────────────
            Text(
              'Trvsty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : 600),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── DESKTOP LEFT COLUMN ────────────────────────────────
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(user, textTheme),
                                  if (latestVerification?.trustScore != null) ...[
                                    const SizedBox(height: AppSpacing.xl),
                                    _buildLatestScoreCard(context, latestVerification!.trustScore!),
                                  ],
                                  const SizedBox(height: AppSpacing.xl),
                                  _buildPrimaryCards(context, ref),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxxl),
                            // ── DESKTOP RIGHT COLUMN ───────────────────────────────
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildServicesHeader(textTheme),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildServicesList(context),
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── MOBILE LAYOUT ──────────────────────────────────────
                            _buildHeader(user, textTheme),
                            if (latestVerification?.trustScore != null) ...[
                              const SizedBox(height: AppSpacing.xl),
                              _buildLatestScoreCard(context, latestVerification!.trustScore!),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            _buildPrimaryCards(context, ref),
                            const SizedBox(height: AppSpacing.xxxl),
                            _buildServicesHeader(textTheme),
                            const SizedBox(height: AppSpacing.lg),
                            _buildServicesList(context),
                            const SizedBox(height: AppSpacing.xl),
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

  Widget _buildHeader(UserModel? user, TextTheme textTheme) {
    return FadeInContainer(
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Run a complete background verification in minutes.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestScoreCard(BuildContext context, TrustScore score) {
    return FadeInContainer(
      delay: const Duration(milliseconds: 150),
      child: _LatestScoreCard(
        score: score,
        onTap: () => context.push(RoutePaths.history),
      ),
    );
  }

  Widget _buildPrimaryCards(BuildContext context, WidgetRef ref) {
    return FadeInContainer(
      delay: const Duration(milliseconds: 200),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PrimaryCard(
                icon: Icons.person,
                title: 'Individual',
                subtitle: 'Verify a person',
                onTap: () => _startVerification(
                  context,
                  ref,
                  UserType.individual,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: _PrimaryCard(
                icon: Icons.business,
                title: 'Business',
                subtitle: 'Verify an organisation',
                onTap: () => _startVerification(
                  context,
                  ref,
                  UserType.business,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesHeader(TextTheme textTheme) {
    return FadeInContainer(
      delay: const Duration(milliseconds: 300),
      child: Text(
        'Services',
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context) {
    return FadeInContainer(
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
              const SizedBox(height: AppSpacing.md),
          ],
        ],
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
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label:
          'Your latest Trust Score: ${score.value} out of 100, ${score.band.label}. Tap to view history.',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
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
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _bandColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your latest Trust Score',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.cardForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    score.band.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.cardMuted,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              label: 'View verification history',
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.cardMuted,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top Individual / Business entry cards.
///
/// Height is intrinsic ([mainAxisSize: MainAxisSize.min]) so larger system
/// font sizes and longer localised copy will never clip or overflow.
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
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: AppColors.cardForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.cardMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row in the "Services" list.
///
/// Non-routed services (those without a [_ServiceItem.route]) are displayed as
/// informational rows — tappable but with no destination yet. Routed services
/// show a chevron arrow with an explicit accessibility label.
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, this.onTap});

  final _ServiceItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasRoute = item.route != null;

    return Semantics(
      button: hasRoute,
      label: '${item.title}. ${item.subtitle}',
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.accent, size: 26),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: AppColors.cardForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.cardMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (hasRoute) ...[
              const SizedBox(width: AppSpacing.lg),
              Semantics(
                label: 'Open ${item.title}',
                excludeSemantics: true,
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.cardMuted,
                  size: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
