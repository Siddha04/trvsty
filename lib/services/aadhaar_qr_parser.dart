import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../core/error/exceptions.dart';
import '../models/aadhaar_data.dart';
import '../utils/gzip_compat.dart';

/// Parses the payload of an Aadhaar **Secure QR** code into [AadhaarData].
///
/// UIDAI has shipped two QR formats:
///
///  * **Legacy XML QR** – the scanned text is a plain XML string
///    (`<PrintLetterBarcodeData .../>`) with demographic attributes.
///  * **Secure QR (2018+)** – the scanned value is a very large integer.
///    Converting it to bytes yields a Gzip-compressed, byte-delimited record
///    that also embeds a JPEG photo and an RSA signature.
///
/// This parser detects the format and extracts the non-sensitive demographic
/// fields. The full Aadhaar number is never present in either format — only
/// the last 4 digits / reference id are exposed, by UIDAI design.
class AadhaarQrParser {
  const AadhaarQrParser();

  AadhaarData parse(String rawScan) {
    final trimmed = rawScan.trim();
    if (trimmed.isEmpty) {
      throw VerificationException('Empty QR payload.');
    }
    // Legacy XML format starts with '<'.
    if (trimmed.startsWith('<')) {
      return _parseXml(trimmed);
    }
    // Secure QR: a big integer.
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return _parseSecureQr(trimmed);
    }
    throw VerificationException('Unrecognised Aadhaar QR format.');
  }

  // --- Legacy XML ------------------------------------------------------------

  AadhaarData _parseXml(String xmlString) {
    try {
      final doc = XmlDocument.parse(xmlString);
      final element = doc.rootElement;
      String? attr(String name) => element.getAttribute(name);

      final uid = attr('uid') ?? '';
      final last4 = uid.length >= 4 ? uid.substring(uid.length - 4) : '';

      return AadhaarData(
        referenceId: attr('uid') ?? '',
        name: attr('name') ?? '',
        gender: attr('gender') ?? '',
        dateOfBirth: attr('dob') ?? attr('yob') ?? '',
        last4Digits: last4,
        careOf: attr('co'),
        address: _composeAddress({
          'house': attr('house'),
          'street': attr('street'),
          'lm': attr('lm'),
          'loc': attr('loc'),
          'vtc': attr('vtc'),
        }),
        pincode: attr('pc'),
        state: attr('state'),
        district: attr('dist'),
      );
    } on XmlException catch (e) {
      throw VerificationException('Malformed Aadhaar XML: ${e.message}');
    }
  }

  // --- Secure QR (big integer) ----------------------------------------------

  AadhaarData _parseSecureQr(String bigIntString) {
    try {
      final bytes = _bigIntToBytes(BigInt.parse(bigIntString));
      final decompressed = _maybeGunzip(bytes);
      // The Secure QR is a sequence of fields delimited by byte 0xFF (255).
      final delimiterIndices = <int>[];
      for (var i = 0; i < decompressed.length; i++) {
        if (decompressed[i] == 255) delimiterIndices.add(i);
      }
      if (delimiterIndices.length < 14) {
        throw VerificationException('Unexpected Secure QR structure.');
      }

      String field(int index) {
        final start = index == 0 ? 0 : delimiterIndices[index - 1] + 1;
        final end = delimiterIndices[index];
        return utf8.decode(decompressed.sublist(start, end), allowMalformed: true);
      }

      // Field 0 = email/mobile presence indicator, 1 = reference id, 2 = name,
      // 3 = dob, 4 = gender, then address components.
      final referenceId = field(1);
      final last4 = referenceId.length >= 4
          ? referenceId.substring(0, 4)
          : referenceId;

      return AadhaarData(
        referenceId: referenceId,
        name: field(2),
        dateOfBirth: field(3),
        gender: field(4),
        last4Digits: last4,
        careOf: field(5),
        district: field(6),
        address: _composeAddress({
          'house': field(8),
          'loc': field(9),
          'street': field(13),
        }),
        pincode: field(11),
        state: field(12),
        hasPhoto: true,
      );
    } on VerificationException {
      rethrow;
    } catch (e) {
      throw VerificationException('Failed to decode Secure QR: $e');
    }
  }

  Uint8List _bigIntToBytes(BigInt number) {
    var value = number;
    final bytes = <int>[];
    final big256 = BigInt.from(256);
    while (value > BigInt.zero) {
      bytes.insert(0, (value % big256).toInt());
      value = value ~/ big256;
    }
    return Uint8List.fromList(bytes);
  }

  /// Gunzips the payload when a Gzip magic header is present, otherwise
  /// returns the bytes unchanged.
  Uint8List _maybeGunzip(Uint8List bytes) {
    if (bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return decompressGzip(bytes);
    }
    return bytes;
  }

  String? _composeAddress(Map<String, String?> parts) {
    final composed = parts.values
        .where((v) => v != null && v.trim().isNotEmpty)
        .join(', ');
    return composed.isEmpty ? null : composed;
  }
}
