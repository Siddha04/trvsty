import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../repositories/auth_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/subscription_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/verification_repository.dart';
import '../../services/aadhaar_qr_parser.dart';
import '../../services/auth_service.dart';
import '../../services/encryption_service.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_report_service.dart';
import '../../services/razorpay_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/surepass_service.dart';
import '../domain/trust_score_calculator.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';

/// Global service locator.
final GetIt sl = GetIt.instance;

/// Registers all singletons. Call once from `main()` after Firebase init.
Future<void> setupServiceLocator() async {
  // --- External singletons ---------------------------------------------------
  sl
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<Connectivity>(() => Connectivity());

  // --- Core ------------------------------------------------------------------
  sl
    ..registerLazySingleton<DioClient>(() => DioClient())
    ..registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()))
    ..registerLazySingleton<TrustScoreCalculator>(
        () => const TrustScoreCalculator());

  // --- Services --------------------------------------------------------------
  sl
    ..registerLazySingleton<SecureStorageService>(() => SecureStorageService())
    ..registerLazySingleton<EncryptionService>(() => EncryptionService(sl()))
    ..registerLazySingleton<AuthService>(() => AuthService(sl()))
    ..registerLazySingleton<FirestoreService>(() => FirestoreService(sl()))
    ..registerLazySingleton<SurepassService>(() => SurepassService(sl()))
    ..registerLazySingleton<AadhaarQrParser>(() => const AadhaarQrParser())
    ..registerLazySingleton<PdfReportService>(() => const PdfReportService())
    // Razorpay holds native resources; one shared instance for the app session.
    ..registerLazySingleton<RazorpayService>(() => RazorpayService());

  // --- Repositories ----------------------------------------------------------
  sl
    ..registerLazySingleton<UserRepository>(() => UserRepositoryImpl(sl()))
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
          authService: sl(),
          userRepository: sl(),
          secureStorage: sl(),
        ))
    ..registerLazySingleton<VerificationRepository>(
        () => VerificationRepositoryImpl(
              surepass: sl(),
              parser: sl(),
              firestore: sl(),
              calculator: sl(),
            ))
    ..registerLazySingleton<PaymentRepository>(() => PaymentRepositoryImpl(
          firestore: sl(),
          dio: sl<DioClient>().raw,
        ))
    ..registerLazySingleton<HistoryRepository>(() => HistoryRepositoryImpl(sl()))
    ..registerLazySingleton<SubscriptionRepository>(
        () => SubscriptionRepositoryImpl(sl()));
}
