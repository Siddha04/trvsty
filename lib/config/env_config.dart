import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application environment flavours.
enum AppEnvironment { development, staging, production }

/// Centralised, type-safe access to environment variables.
///
/// All secrets are loaded from the `.env` file at startup via
/// [flutter_dotenv]. The real `.env` file is excluded from version control;
/// see `.env.example` for the expected keys.
///
/// IMPORTANT: The Razorpay key *secret* and SurePass credentials that can
/// move money or expose PII must live on the backend. Only publishable keys
/// and read-scoped tokens should ever reach the client.
class EnvConfig {
  const EnvConfig._();

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required environment variable "$key". '
        'Did you create a `.env` file from `.env.example`?',
      );
    }
    return value;
  }

  // SurePass -----------------------------------------------------------------
  static String get surepassBaseUrl => _require('SUREPASS_BASE_URL');
  static String get surepassApiToken => _require('SUREPASS_API_TOKEN');

  // Razorpay -----------------------------------------------------------------
  static String get razorpayKeyId => _require('RAZORPAY_KEY_ID');
  static String get paymentVerifyEndpoint => _require('PAYMENT_VERIFY_ENDPOINT');

  // App ----------------------------------------------------------------------
  static AppEnvironment get environment {
    switch (dotenv.maybeGet('APP_ENV')) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isProduction => environment == AppEnvironment.production;
}
