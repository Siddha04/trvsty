import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../features/authentication/presentation/screens/consent_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/otp_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/payment/presentation/screens/payment_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/reports/presentation/report_preview_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/subscriptions/presentation/subscriptions_screen.dart';
import '../features/verification/presentation/screens/bank_entry_screen.dart';
import '../features/verification/presentation/screens/criminal_check_screen.dart';
import '../features/verification/presentation/screens/digilocker_screen.dart';
import '../features/verification/presentation/screens/face_capture_screen.dart';
import '../features/verification/presentation/screens/pan_entry_screen.dart';
import '../features/verification/presentation/screens/scan_aadhaar_screen.dart';
import '../features/verification/presentation/screens/verification_result_screen.dart';
import '../models/verification_record.dart';
import 'route_paths.dart';

/// Provides the application's [GoRouter].
///
/// A [Listenable] bridged from the auth state stream drives `refreshListenable`
/// so the redirect guard re-evaluates whenever the user signs in or out.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref
    ..onDispose(notifier.dispose)
    ..listen(authStateProvider, (_, __) => notifier.value++)
    ..listen(isDemoModeProvider, (_, __) => notifier.value++);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isDemo = ref.read(isDemoModeProvider);
      final isSignedIn = isDemo || ref.read(authRepositoryProvider).currentUser != null;
      final loc = state.matchedLocation;

      final onSplash = loc == RoutePaths.splash;
      final onAuthFlow = loc == RoutePaths.login || loc == RoutePaths.otp;

      // The splash screen performs its own routing decision.
      if (onSplash) return null;

      // Unauthenticated users may only reach the auth flow.
      if (!isSignedIn) {
        return onAuthFlow ? null : RoutePaths.login;
      }

      // Authenticated users should not sit on the login/otp screens.
      if (isSignedIn && onAuthFlow) return RoutePaths.home;

      return null;
    },
    routes: [
      GoRoute(
          path: RoutePaths.splash,
          builder: (_, __) => const SplashScreen()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: RoutePaths.otp, builder: (_, __) => const OtpScreen()),
      GoRoute(
          path: RoutePaths.consent, builder: (_, __) => const ConsentScreen()),
      GoRoute(path: RoutePaths.home, builder: (_, __) => const HomeScreen()),

      // Verification pipeline
      GoRoute(
          path: RoutePaths.scanAadhaar,
          builder: (_, __) => const ScanAadhaarScreen()),
      GoRoute(
          path: RoutePaths.faceCapture,
          builder: (_, __) => const FaceCaptureScreen()),
      GoRoute(
          path: RoutePaths.panEntry,
          builder: (_, __) => const PanEntryScreen()),
      GoRoute(
          path: RoutePaths.bankEntry,
          builder: (_, __) => const BankEntryScreen()),
      GoRoute(
          path: RoutePaths.criminalCheck,
          builder: (_, __) => const CriminalCheckScreen()),
      GoRoute(
          path: RoutePaths.payment,
          builder: (_, __) => const PaymentScreen()),
      GoRoute(
          path: RoutePaths.result,
          builder: (_, __) => const VerificationResultScreen()),
      GoRoute(
          path: RoutePaths.digilocker,
          builder: (_, __) => const DigiLockerScreen()),

      // Report preview expects a VerificationRecord via `extra`.
      GoRoute(
        path: RoutePaths.report,
        builder: (_, state) =>
            ReportPreviewScreen(record: state.extra! as VerificationRecord),
      ),
      GoRoute(
          path: RoutePaths.history, builder: (_, __) => const HistoryScreen()),
      GoRoute(
          path: RoutePaths.profile, builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: RoutePaths.settings,
          builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: RoutePaths.subscriptions,
          builder: (_, __) => const SubscriptionsScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
