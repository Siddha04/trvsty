import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Wrapper around platform secure storage (Keychain / EncryptedSharedPrefs).
///
/// Used for auth tokens, the local AES key, consent state and the cached
/// user id. Never store raw Aadhaar numbers or face images here.
class SecureStorageService {
  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearAll() => _storage.deleteAll();

  // Convenience accessors -----------------------------------------------------

  Future<void> setConsentAccepted(bool accepted) =>
      write(SecureStorageKeys.consentAccepted, accepted.toString());

  Future<bool> get isConsentAccepted async =>
      (await read(SecureStorageKeys.consentAccepted)) == 'true';

  Future<void> setUserId(String uid) => write(SecureStorageKeys.userId, uid);

  Future<String?> get userId => read(SecureStorageKeys.userId);
}
