import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart';

import '../constants/app_constants.dart';
import 'secure_storage_service.dart';

/// AES-256 (CBC) encryption for sensitive fields persisted locally or in
/// Firestore (e.g. masked Aadhaar payloads, verification metadata).
///
/// The symmetric key is generated once per install and stored in the
/// platform secure enclave via [SecureStorageService]. A fresh random IV is
/// generated per message and prepended to the ciphertext.
class EncryptionService {
  EncryptionService(this._secureStorage);

  final SecureStorageService _secureStorage;
  Encrypter? _encrypter;

  Future<Encrypter> _ensureEncrypter() async {
    if (_encrypter != null) return _encrypter!;

    var keyString = await _secureStorage.read(SecureStorageKeys.encryptionKey);
    if (keyString == null) {
      keyString = _generateKey();
      await _secureStorage.write(SecureStorageKeys.encryptionKey, keyString);
    }
    final key = Key.fromBase64(keyString);
    _encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return _encrypter!;
  }

  String _generateKey() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Encode(bytes);
  }

  /// Encrypts [plainText] and returns `base64(iv):base64(cipher)`.
  Future<String> encrypt(String plainText) async {
    final encrypter = await _ensureEncrypter();
    final iv = IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Reverses [encrypt]. Throws [FormatException] for malformed input.
  Future<String> decrypt(String payload) async {
    final encrypter = await _ensureEncrypter();
    final parts = payload.split(':');
    if (parts.length != 2) {
      throw const FormatException('Malformed encrypted payload.');
    }
    final iv = IV.fromBase64(parts[0]);
    return encrypter.decrypt64(parts[1], iv: iv);
  }
}
