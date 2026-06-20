import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin, typed convenience wrapper over [FirebaseFirestore].
///
/// Repositories use this to obtain typed collection references and to write
/// audit log entries. Keeping the SDK access in one place makes it easy to
/// swap the backend or add cross-cutting behaviour (e.g. tracing).
class FirestoreService {
  FirestoreService(this._db);

  final FirebaseFirestore _db;

  FirebaseFirestore get db => _db;

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _db.collection(name);

  DocumentReference<Map<String, dynamic>> doc(String collection, String id) =>
      _db.collection(collection).doc(id);

  /// Generates a new document id without writing.
  String newId(String collection) => _db.collection(collection).doc().id;

  /// Appends an immutable audit log entry to the `logs` collection.
  Future<void> log({
    required String action,
    required String userId,
    Map<String, dynamic> metadata = const {},
  }) =>
      _db.collection('logs').add({
        'action': action,
        'userId': userId,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
}
