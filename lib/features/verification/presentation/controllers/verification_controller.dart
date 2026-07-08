import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../models/aadhaar_data.dart';
import '../../../../models/enums.dart';
import '../../../../models/trust_score.dart';
import '../../../../models/verification_record.dart';
import '../../../../models/verification_results.dart';

/// Ordered steps of the verification pipeline.
enum VerificationStep {
  selectType,
  scanAadhaar,
  faceCapture,
  panEntry,
  bankEntry,
  criminalCheck,
  payment,
  result,
}

/// Immutable state of an in-progress verification.
class VerificationFlowState {
  const VerificationFlowState({
    this.step = VerificationStep.selectType,
    this.subjectType = UserType.individual,
    this.aadhaar,
    this.faceMatch,
    this.pan,
    this.bank,
    this.criminal,
    this.trustScore,
    this.savedRecord,
    this.isLoading = false,
    this.errorMessage,
  });

  final VerificationStep step;
  final UserType subjectType;
  final AadhaarData? aadhaar;
  final FaceMatchResult? faceMatch;
  final PanVerificationResult? pan;
  final BankVerificationResult? bank;
  final CriminalRecordResult? criminal;
  final TrustScore? trustScore;
  final VerificationRecord? savedRecord;
  final bool isLoading;
  final String? errorMessage;

  bool get aadhaarVerified => aadhaar != null;

  VerificationFlowState copyWith({
    VerificationStep? step,
    UserType? subjectType,
    AadhaarData? aadhaar,
    FaceMatchResult? faceMatch,
    PanVerificationResult? pan,
    BankVerificationResult? bank,
    CriminalRecordResult? criminal,
    TrustScore? trustScore,
    VerificationRecord? savedRecord,
    bool? isLoading,
    String? errorMessage,
  }) =>
      VerificationFlowState(
        step: step ?? this.step,
        subjectType: subjectType ?? this.subjectType,
        aadhaar: aadhaar ?? this.aadhaar,
        faceMatch: faceMatch ?? this.faceMatch,
        pan: pan ?? this.pan,
        bank: bank ?? this.bank,
        criminal: criminal ?? this.criminal,
        trustScore: trustScore ?? this.trustScore,
        savedRecord: savedRecord ?? this.savedRecord,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

/// Drives the multi-step verification pipeline, delegating each check to the
/// [VerificationRepository] and aggregating the results into a [TrustScore].
class VerificationController extends StateNotifier<VerificationFlowState> {
  VerificationController(this._ref) : super(const VerificationFlowState());

  final Ref _ref;

  void start(UserType type) {
    state = VerificationFlowState(
      subjectType: type,
      step: VerificationStep.scanAadhaar,
    );
  }

  /// Parses a scanned Aadhaar QR payload.
  void onAadhaarScanned(String rawScan) {
    final result = _ref.read(verificationRepositoryProvider).parseAadhaarQr(rawScan);
    result.fold(
      (failure) => state = state.copyWith(errorMessage: failure.message),
      (data) => state = state.copyWith(
        aadhaar: data,
        step: VerificationStep.faceCapture,
        errorMessage: null,
      ),
    );
  }

  /// Runs face match between the Aadhaar photo and a captured selfie.
  Future<void> runFaceMatch({
    required String referenceImageBase64,
    required String selfieImageBase64,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(verificationRepositoryProvider).faceMatch(
          referenceImageBase64: referenceImageBase64,
          selfieImageBase64: selfieImageBase64,
        );
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (match) => state = state.copyWith(
        isLoading: false,
        faceMatch: match,
        step: VerificationStep.panEntry,
      ),
    );
  }

  /// Verifies the entered PAN, cross-checking against the Aadhaar name.
  Future<void> runPanVerification(String panNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(verificationRepositoryProvider).verifyPan(
          panNumber: panNumber,
          expectedName: state.aadhaar?.name,
        );
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (pan) => state = state.copyWith(
        isLoading: false,
        pan: pan,
        step: VerificationStep.bankEntry,
      ),
    );
  }

  /// Verifies the entered Bank Account, cross-checking against the Aadhaar name.
  Future<void> runBankVerification(String account, String ifsc) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(verificationRepositoryProvider).verifyBankAccount(
          accountNumber: account,
          ifsc: ifsc,
          expectedName: state.aadhaar?.name ?? '',
        );
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (bank) => state = state.copyWith(
        isLoading: false,
        bank: bank,
        step: VerificationStep.criminalCheck,
      ),
    );
  }

  /// Runs the criminal-record screening using Aadhaar demographics.
  Future<void> runCriminalCheck() async {
    final aadhaar = state.aadhaar;
    if (aadhaar == null) {
      state = state.copyWith(errorMessage: 'Aadhaar data missing.');
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(verificationRepositoryProvider).criminalCheck(
          name: aadhaar.name,
          dateOfBirth: aadhaar.dateOfBirth,
        );
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (criminal) => state = state.copyWith(
        isLoading: false,
        criminal: criminal,
        step: VerificationStep.payment,
      ),
    );
  }

  /// Computes the trust score and persists the verification record.
  ///
  /// Called after a successful, server-verified payment ([paymentId]).
  Future<void> finalize({required String userId, String? paymentId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final score = _ref.read(verificationRepositoryProvider).computeTrustScore(
          aadhaarVerified: state.aadhaarVerified,
          faceMatch: state.faceMatch,
          pan: state.pan,
          bank: state.bank,
          criminal: state.criminal,
        );

    final repo = _ref.read(verificationRepositoryProvider);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final record = VerificationRecord(
      id: id,
      userId: userId,
      subjectType: state.subjectType,
      status: VerificationStatus.completed,
      createdAt: DateTime.now(),
      aadhaar: state.aadhaar,
      faceMatch: state.faceMatch,
      pan: state.pan,
      bank: state.bank,
      criminal: state.criminal,
      trustScore: score,
      paymentId: paymentId,
    );

    final saved = await repo.saveRecord(record);
    saved.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (rec) => state = state.copyWith(
        isLoading: false,
        trustScore: score,
        savedRecord: rec,
        step: VerificationStep.result,
      ),
    );
  }

  void reset() => state = const VerificationFlowState();
}

final verificationControllerProvider =
    StateNotifierProvider<VerificationController, VerificationFlowState>(
        (ref) => VerificationController(ref),);
