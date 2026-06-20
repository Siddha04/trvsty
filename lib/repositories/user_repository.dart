import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Persistence for [UserModel] documents in the `users` collection.
abstract interface class UserRepository {
  Future<Result<UserModel>> getUser(String uid);
  Future<Result<UserModel>> upsertUser(UserModel user);
  Future<Result<void>> setConsent(String uid, bool accepted);
  Future<Result<void>> softDelete(String uid);
  Stream<UserModel?> watchUser(String uid);
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirestoreService _firestore;

  @override
  Future<Result<UserModel>> getUser(String uid) async {
    try {
      final doc =
          await _firestore.doc(FirestoreCollections.users, uid).get();
      if (!doc.exists) {
        return const ResultFailure(AuthFailure('User profile not found.'));
      }
      return Success(UserModel.fromFirestore(doc));
    } catch (e, st) {
      AppLogger.e('getUser failed', error: e, stackTrace: st);
      return ResultFailure(CacheFailure('Failed to load profile: $e'));
    }
  }

  @override
  Future<Result<UserModel>> upsertUser(UserModel user) async {
    try {
      await _firestore
          .doc(FirestoreCollections.users, user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
      return Success(user);
    } catch (e, st) {
      AppLogger.e('upsertUser failed', error: e, stackTrace: st);
      return ResultFailure(ServerFailure('Failed to save profile: $e'));
    }
  }

  @override
  Future<Result<void>> setConsent(String uid, bool accepted) async {
    try {
      await _firestore.doc(FirestoreCollections.users, uid).set(
        {'consentAccepted': accepted, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure('Failed to record consent: $e'));
    }
  }

  @override
  Future<Result<void>> softDelete(String uid) async {
    try {
      await _firestore.doc(FirestoreCollections.users, uid).set(
        {'isDeleted': true, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      await _firestore.log(action: 'user_soft_deleted', userId: uid);
      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure('Failed to delete account: $e'));
    }
  }

  @override
  Stream<UserModel?> watchUser(String uid) => _firestore
      .doc(FirestoreCollections.users, uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
}
