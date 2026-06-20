import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Streams the Firebase auth user (null when signed out).
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
