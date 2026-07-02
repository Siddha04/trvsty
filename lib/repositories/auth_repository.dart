import 'package:firebase_auth/firebase_auth.dart';

import '../core/error/exceptions.dart';
import '../core/error/failures.dart';
import '../core/utils/result.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import 'user_repository.dart';

/// Coordinates phone-OTP authentication with user-profile provisioning.
///
/// On first successful sign-in a [UserModel] document is created. The OTP
/// callbacks are forwarded from [AuthService]; OTP confirmation and profile
/// loading return a [Result].
abstract interface class AuthRepository {
  User? get currentUser;
  Stream<User?> get authStateChanges;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(Failure failure) onError,
    required void Function(UserModel user) onAutoVerified,
  });

  Future<Result<UserModel>> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  });

  Future<void> signInAnonymously();

  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthService authService,
    required UserRepository userRepository,
    required SecureStorageService secureStorage,
  })  : _authService = authService,
        _userRepository = userRepository,
        _secureStorage = secureStorage;

  final AuthService _authService;
  final UserRepository _userRepository;
  final SecureStorageService _secureStorage;

  @override
  User? get currentUser => _authService.currentUser;

  @override
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(Failure failure) onError,
    required void Function(UserModel user) onAutoVerified,
  }) async {
    await _authService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (result) {
        if (result.verificationId != null) onCodeSent(result.verificationId!);
      },
      onError: (e) => onError(AuthFailure(e.message, code: e.code)),
      onAutoVerified: (credential) async {
        try {
          final user = await _authService.signInWithCredential(credential);
          final model = await _provision(user, phoneNumber);
          onAutoVerified(model);
        } on AuthException catch (e) {
          onError(AuthFailure(e.message, code: e.code));
        }
      },
    );
  }

  @override
  Future<Result<UserModel>> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    try {
      final user = await _authService.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final model = await _provision(user, phoneNumber);
      return Success(model);
    } on AuthException catch (e) {
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(AuthFailure('Sign-in failed: $e'));
    }
  }

  /// Ensures a user document exists and caches the uid in secure storage.
  Future<UserModel> _provision(User user, String phoneNumber) async {
    await _secureStorage.setUserId(user.uid);

    final existing = await _userRepository.getUser(user.uid);
    final found = existing.valueOrNull;
    if (found != null) return found;

    // First sign-in: create the profile document.
    final fresh = UserModel(
      uid: user.uid,
      phoneNumber: user.phoneNumber ?? phoneNumber,
      createdAt: DateTime.now(),
    );
    final saved = await _userRepository.upsertUser(fresh);
    return saved.valueOrNull ?? fresh;
  }

  @override
  Future<void> signInAnonymously() async {
    try {
      final user = await _authService.signInAnonymously();
      await _provision(user, '+910000000000');
    } catch (e) {
      // Allow it to fail silently or handle error upstream
    }
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
    await _secureStorage.delete('user_id');
  }
}
