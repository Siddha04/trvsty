import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Application user. Mirrors a document in the `users` collection.
class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name,
    this.email,
    this.userType = UserType.individual,
    this.photoUrl,
    this.consentAccepted = false,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  final String uid;
  final String phoneNumber;
  final String? name;
  final String? email;
  final UserType userType;
  final String? photoUrl;
  final bool consentAccepted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Soft-delete flag (DPDP: users may request erasure).
  final bool isDeleted;

  UserModel copyWith({
    String? name,
    String? email,
    UserType? userType,
    String? photoUrl,
    bool? consentAccepted,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      UserModel(
        uid: uid,
        phoneNumber: phoneNumber,
        name: name ?? this.name,
        email: email ?? this.email,
        userType: userType ?? this.userType,
        photoUrl: photoUrl ?? this.photoUrl,
        consentAccepted: consentAccepted ?? this.consentAccepted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'phoneNumber': phoneNumber,
        'name': name,
        'email': email,
        'userType': userType.name,
        'photoUrl': photoUrl,
        'consentAccepted': consentAccepted,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': isDeleted,
      };

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      phoneNumber: data['phoneNumber'] as String? ?? '',
      name: data['name'] as String?,
      email: data['email'] as String?,
      userType: UserType.fromString(data['userType'] as String?),
      photoUrl: data['photoUrl'] as String?,
      consentAccepted: data['consentAccepted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [uid, phoneNumber, userType, consentAccepted, isDeleted];
}
