import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/utils/result.dart';
import '../models/verification_record.dart';

/// Read access and soft-deletion for verification history.
abstract interface class HistoryRepository {
  Stream<List<VerificationRecord>> watchHistory(String userId);
  Future<Result<VerificationRecord>> getRecord(String id);
  Future<Result<void>> softDelete(String id);
}

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<VerificationRecord>> watchHistory(String userId) => _firestore
      .collection(FirestoreCollections.verificationHistory)
      .where('userId', isEqualTo: userId)
      .where('isDeleted', isEqualTo: false)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map(VerificationRecord.fromFirestore)
          .toList(growable: false),);

  @override
  Future<Result<VerificationRecord>> getRecord(String id) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.verificationHistory)
          .doc(id)
          .get();
      if (!doc.exists) {
        return const ResultFailure(CacheFailure('Record not found.'));
      }
      return Success(VerificationRecord.fromFirestore(doc));
    } catch (e) {
      return ResultFailure(ServerFailure('Failed to load record: $e'));
    }
  }

  @override
  Future<Result<void>> softDelete(String id) async {
    try {
      await _firestore
          .collection(FirestoreCollections.verificationHistory)
          .doc(id)
          .set(
        {'isDeleted': true, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure('Failed to delete record: $e'));
    }
  }
}
