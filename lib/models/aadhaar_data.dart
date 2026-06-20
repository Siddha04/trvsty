import 'package:equatable/equatable.dart';

/// Demographic data extracted from an Aadhaar **Secure QR** code.
///
/// The Secure QR encodes a digitally-signed, compressed payload published by
/// UIDAI. Trusty only ever retains the masked reference id and non-sensitive
/// demographic fields; the full Aadhaar number is never reconstructed or
/// stored (UIDAI Secure QR only exposes the last 4 digits by design).
class AadhaarData extends Equatable {
  const AadhaarData({
    required this.referenceId,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.last4Digits,
    this.careOf,
    this.address,
    this.pincode,
    this.state,
    this.district,
    this.hasPhoto = false,
    this.mobileHash,
    this.emailHash,
  });

  /// UIDAI reference id (first 4 digits are the last 4 of the Aadhaar number).
  final String referenceId;
  final String name;
  final String gender;
  final String dateOfBirth;

  /// Last 4 digits of the Aadhaar number — the only portion exposed by the QR.
  final String last4Digits;

  final String? careOf;
  final String? address;
  final String? pincode;
  final String? state;
  final String? district;

  /// Whether the QR embedded a photograph (used for face match).
  final bool hasPhoto;

  /// One-way hashes (if present) UIDAI provides for mobile/email matching.
  final String? mobileHash;
  final String? emailHash;

  String get maskedAadhaar => 'XXXX XXXX $last4Digits';

  Map<String, dynamic> toJson() => {
        'referenceId': referenceId,
        'name': name,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'last4Digits': last4Digits,
        'careOf': careOf,
        'address': address,
        'pincode': pincode,
        'state': state,
        'district': district,
        'hasPhoto': hasPhoto,
      };

  factory AadhaarData.fromJson(Map<String, dynamic> json) => AadhaarData(
        referenceId: json['referenceId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        dateOfBirth: json['dateOfBirth'] as String? ?? '',
        last4Digits: json['last4Digits'] as String? ?? '',
        careOf: json['careOf'] as String?,
        address: json['address'] as String?,
        pincode: json['pincode'] as String?,
        state: json['state'] as String?,
        district: json['district'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [referenceId, name, last4Digits, dateOfBirth];
}
