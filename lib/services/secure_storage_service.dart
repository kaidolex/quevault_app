import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../core/configs/storage_config.dart';

/// Service for securely storing sensitive data using Flutter Secure Storage
class SecureStorageService {
  static const _storage = StorageConfig.secureStorage;

  // Storage keys
  static const String _masterPasswordHashKey = 'master_password_hash';
  static const String _masterPasswordSaltKey = 'master_password_salt';
  static const String _isSetupCompleteKey = 'is_setup_complete';

  /// Stores the master password securely by hashing it with a salt
  Future<bool> storeMasterPassword(String password) async {
    try {
      if (kDebugMode) {
        print('SecureStorageService: Starting to store master password');
      }

      // Generate a random salt
      final salt = _generateSalt();
      if (kDebugMode) {
        print('SecureStorageService: Generated salt');
      }

      // Hash the password with the salt
      final hashedPassword = _hashPassword(password, salt);
      if (kDebugMode) {
        print('SecureStorageService: Hashed password');
      }

      // Store both hash and salt
      await _storage.write(key: _masterPasswordHashKey, value: hashedPassword);
      if (kDebugMode) {
        print('SecureStorageService: Stored password hash');
      }

      await _storage.write(key: _masterPasswordSaltKey, value: salt);
      if (kDebugMode) {
        print('SecureStorageService: Stored salt');
      }

      await _storage.write(key: _isSetupCompleteKey, value: 'true');
      if (kDebugMode) {
        print('SecureStorageService: Stored setup complete flag');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error storing master password: $e');
      }
      return false;
    }
  }

  /// Verifies if the provided password matches the stored master password
  Future<bool> verifyMasterPassword(String password) async {
    try {
      final storedHash = await _storage.read(key: _masterPasswordHashKey);
      final salt = await _storage.read(key: _masterPasswordSaltKey);

      if (storedHash == null || salt == null) {
        return false;
      }

      // Hash the provided password with the stored salt
      final hashedPassword = _hashPassword(password, salt);

      // Compare with stored hash
      return hashedPassword == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// Checks if master password setup is complete
  Future<bool> isMasterPasswordSetup() async {
    try {
      final isSetup = await _storage.read(key: _isSetupCompleteKey);
      return isSetup == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Changes the master password
  Future<bool> changeMasterPassword(String currentPassword, String newPassword) async {
    try {
      // Verify current password first
      final isCurrentValid = await verifyMasterPassword(currentPassword);
      if (!isCurrentValid) {
        return false;
      }

      // Store new password
      return await storeMasterPassword(newPassword);
    } catch (e) {
      return false;
    }
  }

  /// Clears all stored master password data (for reset/logout)
  Future<bool> clearMasterPassword() async {
    try {
      await _storage.delete(key: _masterPasswordHashKey);
      await _storage.delete(key: _masterPasswordSaltKey);
      await _storage.delete(key: _isSetupCompleteKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stores encrypted data with a key
  Future<bool> storeEncryptedData(String key, String data) async {
    try {
      await _storage.write(key: key, value: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves encrypted data by key
  Future<String?> getEncryptedData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Deletes data by key
  Future<bool> deleteData(String key) async {
    try {
      await _storage.delete(key: key);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates a random salt for password hashing
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Hashes a password with a salt using SHA-256
  String _hashPassword(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Checks if secure storage is available
  Future<bool> isStorageAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = 'storage_test';
      const testValue = 'test_value';

      await _storage.write(key: testKey, value: testValue);
      final readValue = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);

      return readValue == testValue;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Storage availability test failed: $e');
      }
      return false;
    }
  }
}
