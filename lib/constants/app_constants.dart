/// Global, compile-time application constants.
///
/// Values here are non-secret and safe to ship in the binary. Secrets belong
/// in [EnvConfig] / the backend.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Trusty';
  static const String tagline = 'Verify with Confidence';
  static const String supportEmail = 'support@trusty.app';
  static const String privacyPolicyUrl = 'https://trusty.app/privacy';
  static const String termsUrl = 'https://trusty.app/terms';

  /// Generic network timeout.
  static const Duration networkTimeout = Duration(seconds: 30);

  /// OTP resend cool-down.
  static const Duration otpResendCooldown = Duration(seconds: 45);

  /// Minimum face-match confidence (percentage) to consider a positive match.
  static const double faceMatchThreshold = 70.0;

  /// Pricing (in INR) for one-time individual verification.
  static const int individualVerificationPrice = 99;

  /// Razorpay amounts are expressed in the smallest currency unit (paise).
  static const int paisePerRupee = 100;
}

/// Firestore collection names — single source of truth to avoid typos.
class FirestoreCollections {
  const FirestoreCollections._();

  static const String users = 'users';
  static const String businesses = 'businesses';
  static const String verificationHistory = 'verification_history';
  static const String payments = 'payments';
  static const String subscriptions = 'subscriptions';
  static const String reports = 'reports';
  static const String analytics = 'analytics';
  static const String logs = 'logs';
}

/// Keys used with [FlutterSecureStorage].
class SecureStorageKeys {
  const SecureStorageKeys._();

  static const String authToken = 'auth_token';
  static const String encryptionKey = 'aes_encryption_key';
  static const String consentAccepted = 'consent_accepted';
  static const String userId = 'user_id';
}
