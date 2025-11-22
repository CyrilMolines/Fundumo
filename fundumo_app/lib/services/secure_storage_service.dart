import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for secure encrypted storage using platform keystore
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
              keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
              storageCipherAlgorithm: StorageCipherAlgorithm.AES256GCM,
            ),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  final FlutterSecureStorage _storage;

  /// Store encrypted data
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read encrypted data
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete encrypted data
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all encrypted data
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Store encrypted JSON data
  Future<void> writeJson(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await write(key, jsonString);
  }

  /// Read encrypted JSON data
  Future<Map<String, dynamic>?> readJson(String key) async {
    final jsonString = await read(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Generate encryption key for local data
  Future<String> generateEncryptionKey() async {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store encryption key securely
  Future<void> storeEncryptionKey(String userId, String key) async {
    await write('encryption_key_$userId', key);
  }

  /// Retrieve encryption key
  Future<String?> getEncryptionKey(String userId) async {
    return await read('encryption_key_$userId');
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);
