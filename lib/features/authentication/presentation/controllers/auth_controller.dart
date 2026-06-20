import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../models/user_model.dart';

/// Phases of the OTP authentication flow.
enum AuthPhase { idle, sendingOtp, otpSent, verifying, authenticated, error }

/// Immutable auth UI state.
class AuthState {
  const AuthState({
    this.phase = AuthPhase.idle,
    this.phoneNumber = '',
    this.verificationId,
    this.user,
    this.errorMessage,
  });

  final AuthPhase phase;
  final String phoneNumber;
  final String? verificationId;
  final UserModel? user;
  final String? errorMessage;

  bool get isBusy =>
      phase == AuthPhase.sendingOtp || phase == AuthPhase.verifying;

  AuthState copyWith({
    AuthPhase? phase,
    String? phoneNumber,
    String? verificationId,
    UserModel? user,
    String? errorMessage,
  }) =>
      AuthState(
        phase: phase ?? this.phase,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        verificationId: verificationId ?? this.verificationId,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );
}

/// Drives the OTP login flow.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState());

  final Ref _ref;

  /// Sends an OTP to the supplied [phoneNumber] (10-digit Indian number).
  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      phase: AuthPhase.sendingOtp,
      phoneNumber: phoneNumber,
      errorMessage: null,
    );

    await _ref.read(authRepositoryProvider).sendOtp(
          phoneNumber: '+91$phoneNumber',
          onCodeSent: (verificationId) {
            state = state.copyWith(
              phase: AuthPhase.otpSent,
              verificationId: verificationId,
            );
          },
          onError: (Failure failure) {
            state = state.copyWith(
              phase: AuthPhase.error,
              errorMessage: failure.message,
            );
          },
          onAutoVerified: (user) {
            state = state.copyWith(phase: AuthPhase.authenticated, user: user);
          },
        );
  }

  /// Confirms the entered [smsCode].
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(
        phase: AuthPhase.error,
        errorMessage: 'Please request an OTP first.',
      );
      return;
    }

    state = state.copyWith(phase: AuthPhase.verifying, errorMessage: null);
    final result = await _ref.read(authRepositoryProvider).verifyOtp(
          verificationId: verificationId,
          smsCode: smsCode,
          phoneNumber: '+91${state.phoneNumber}',
        );

    result.fold(
      (failure) => state = state.copyWith(
        phase: AuthPhase.error,
        errorMessage: failure.message,
      ),
      (user) =>
          state = state.copyWith(phase: AuthPhase.authenticated, user: user),
    );
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
    state = const AuthState();
  }

  void reset() => state = const AuthState();
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
