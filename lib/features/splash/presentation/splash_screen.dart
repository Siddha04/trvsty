import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../routes/route_paths.dart';
import '../../../theme/app_colors.dart';

/// Animated splash screen. Decides the initial route based on auth + consent.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    // Brief, deterministic splash dwell for branding.
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      context.go(RoutePaths.login);
      return;
    }
    final consented = await ref.read(secureStorageProvider).isConsentAccepted;
    if (!mounted) return;
    context.go(consented ? RoutePaths.home : RoutePaths.consent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: AppColors.accent, size: 96)
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 1200.ms, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
            const SizedBox(height: 8),
            const Text(
              AppConstants.tagline,
              style: TextStyle(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
