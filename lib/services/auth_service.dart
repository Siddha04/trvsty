import 'package:firebase_auth/firebase_auth.dart';

import '../core/error/exceptions.dart';
import '../core/utils/app_logger.dart';

/// Result of starting phone verification.
class OtpStartResult {
  const OtpStartResult({this.verificationId, this.autoCredential});

  /// Present on most devices — used to confirm the OTP.
  final String? verificationId;

  /// On some Android devices the SMS is auto-retrieved and a credential is
  /// produced without user input.
  final PhoneAuthCredential? autoCredential;
}

/// Wraps [FirebaseAuth] phone (OTP) authentication.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  bool get isSignedIn => _auth.currentUser != null;

  /// Sends an OTP to [phoneNumber] (E.164, e.g. `+919876543210`).
  ///
  /// Because verification is asynchronous and callback-driven, the result is
  /// surfaced through the provided callbacks rather than the returned future.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(OtpStartResult result) onCodeSent,
    required void Function(AuthException error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: onAutoVerified,
      verificationFailed: (FirebaseAuthException e) {
        AppLogger.w('OTP verificationFailed: ${e.code}');
        onError(AuthException(_mapError(e), code: e.code));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(OtpStartResult(verificationId: verificationId));
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Confirms the OTP and signs the user in.
  Future<User> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw AuthException('Sign-in failed. Please try again.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e), code: e.code);
    }
  }

  /// Completes sign-in from an auto-retrieved credential.
  Future<User> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) throw AuthException('Sign-in failed.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number entered is invalid.';
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect.';
      case 'session-expired':
        return 'The OTP has expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
