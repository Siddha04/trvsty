import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../core/domain/trust_score_calculator.dart';
import '../core/error/exceptions.dart';
import '../core/error/failures.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import '../models/aadhaar_data.dart';
import '../models/enums.dart';
import '../models/trust_score.dart';
import '../models/verification_record.dart';
import '../models/verification_results.dart';
import '../services/aadhaar_qr_parser.dart';
import '../services/firestore_service.dart';
import '../services/surepass_service.dart';

/// Orchestrates the end-to-end verification pipeline and persists results.
abstract interface class VerificationRepository {
  Result<AadhaarData> parseAadhaarQr(String rawScan);

  Future<Result<FaceMatchResult>> faceMatch({
    required String referenceImageBase64,
    required String selfieImageBase64,
  });

  Future<Result<PanVerificationResult>> verifyPan({
    required String panNumber,
    String? expectedName,
  });

  Future<Result<CriminalRecordResult>> criminalCheck({
    required String name,
    required String dateOfBirth,
  });

  Future<Result<BankVerificationResult>> verifyBankAccount({
    required String accountNumber,
    required String ifsc,
    required String expectedName,
  });

  TrustScore computeTrustScore({
    required bool aadhaarVerified,
    FaceMatchResult? faceMatch,
    PanVerificationResult? pan,
    BankVerificationResult? bank,
    CriminalRecordResult? criminal,
  });

  Future<Result<VerificationRecord>> saveRecord(VerificationRecord record);
}

class VerificationRepositoryImpl implements VerificationRepository {
  VerificationRepositoryImpl({
    required SurepassService surepass,
    required AadhaarQrParser parser,
    required FirestoreService firestore,
    TrustScoreCalculator calculator = const TrustScoreCalculator(),
  })  : _surepass = surepass,
        _parser = parser,
        _firestore = firestore,
        _calculator = calculator;

  final SurepassService _surepass;
  final AadhaarQrParser _parser;
  final FirestoreService _firestore;
  final TrustScoreCalculator _calculator;

  @override
  Result<AadhaarData> parseAadhaarQr(String rawScan) {
    try {
      return Success(_parser.parse(rawScan));
    } on VerificationException catch (e) {
      return ResultFailure(VerificationFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(VerificationFailure('Could not read QR: $e'));
    }
  }

  @override
  Future<Result<FaceMatchResult>> faceMatch({
    required String referenceImageBase64,
    required String selfieImageBase64,
  }) =>
      _guard(() => _surepass.faceMatch(
            referenceImageBase64: referenceImageBase64,
            selfieImageBase64: selfieImageBase64,
            threshold: AppConstants.faceMatchThreshold,
          ));

  @override
  Future<Result<PanVerificationResult>> verifyPan({
    required String panNumber,
    String? expectedName,
  }) =>
      _guard(() => _surepass.verifyPan(
            panNumber: panNumber,
            expectedName: expectedName,
          ));

  @override
  Future<Result<CriminalRecordResult>> criminalCheck({
    required String name,
    required String dateOfBirth,
  }) =>
      _guard(() => _surepass.criminalRecordCheck(
            name: name,
            dateOfBirth: dateOfBirth,
          ));

  @override
  Future<Result<BankVerificationResult>> verifyBankAccount({
    required String accountNumber,
    required String ifsc,
    required String expectedName,
  }) async {
    // Simulated Penny Drop (IMPS) Verification
    await Future.delayed(const Duration(seconds: 1)); // Simulate network latency
    
    // Fail if IFSC doesn't have 11 characters
    if (ifsc.length != 11) {
      return ResultFailure(const VerificationFailure('Invalid IFSC Code.'));
    }

    // In a real scenario, this would hit SurePass or a banking API.
    // Here we simulate a successful name match.
    return Success(BankVerificationResult(
      accountNumber: accountNumber,
      ifsc: ifsc,
      registeredName: expectedName,
      isNameMatch: true,
    ));
  }

  @override
  TrustScore computeTrustScore({
    required bool aadhaarVerified,
    FaceMatchResult? faceMatch,
    PanVerificationResult? pan,
    BankVerificationResult? bank,
    CriminalRecordResult? criminal,
  }) =>
      _calculator.calculate(
        aadhaarVerified: aadhaarVerified,
        faceMatch: faceMatch,
        pan: pan,
        bank: bank,
        criminal: criminal,
      );

  @override
  Future<Result<VerificationRecord>> saveRecord(VerificationRecord record) async {
    try {
      await _firestore
          .doc(FirestoreCollections.verificationHistory, record.id)
          .set(record.toFirestore(), SetOptions(merge: true));
      await _firestore.log(
        action: 'verification_completed',
        userId: record.userId,
        metadata: {
          'verificationId': record.id,
          'trustScore': record.trustScore?.value,
          'status': record.status.name,
        },
      );
      return Success(record);
    } catch (e, st) {
      AppLogger.e('saveRecord failed', error: e, stackTrace: st);
      return ResultFailure(ServerFailure('Failed to save verification: $e'));
    }
  }

  /// Wraps a SurePass call, mapping exceptions to verification failures.
  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Success(await body());
    } on VerificationException catch (e) {
      return ResultFailure(VerificationFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      return ResultFailure(ServerFailure(e.message, code: e.statusCode?.toString()));
    } on NetworkException catch (e) {
      return ResultFailure(NetworkFailure(e.message));
    } catch (e, st) {
      AppLogger.e('verification call failed', error: e, stackTrace: st);
      return ResultFailure(VerificationFailure('Verification failed: $e'));
    }
  }
}
