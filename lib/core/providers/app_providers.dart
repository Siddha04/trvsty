import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../models/verification_record.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/subscription_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/verification_repository.dart';
import '../../services/pdf_report_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/secure_storage_service.dart';
import '../di/service_locator.dart';

/// Riverpod bridge over the GetIt service locator.
///
/// Keeping a single source of truth (GetIt) for construction while exposing
/// dependencies as Riverpod providers gives us testable, overridable wiring in
/// widgets without leaking `sl()` calls throughout the UI.

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => sl<AuthRepository>());

final userRepositoryProvider =
    Provider<UserRepository>((ref) => sl<UserRepository>());

final verificationRepositoryProvider =
    Provider<VerificationRepository>((ref) => sl<VerificationRepository>());

final paymentRepositoryProvider =
    Provider<PaymentRepository>((ref) => sl<PaymentRepository>());

final historyRepositoryProvider =
    Provider<HistoryRepository>((ref) => sl<HistoryRepository>());

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) => sl<SubscriptionRepository>());

final pdfReportServiceProvider =
    Provider<PdfReportService>((ref) => sl<PdfReportService>());

final razorpayServiceProvider =
    Provider<RazorpayService>((ref) => sl<RazorpayService>());

final secureStorageProvider =
    Provider<SecureStorageService>((ref) => sl<SecureStorageService>());

/// State provider for demo bypass
final isDemoModeProvider = StateProvider<bool>((ref) => false);

/// Streams the Firebase auth user (null when signed out).
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Streams the signed-in user's profile document.
///
/// Shared across screens (home greeting, profile details, settings, …) so
/// there is a single source of truth instead of each screen re-declaring it.
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

/// The most recent verification record for the signed-in user, if any.
/// Used to surface a "your last Trust Score" shortcut on the home screen.
final latestVerificationProvider =
    StreamProvider.autoDispose<VerificationRecord?>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref
      .watch(historyRepositoryProvider)
      .watchHistory(uid)
      .map((records) => records.isEmpty ? null : records.first);
});
