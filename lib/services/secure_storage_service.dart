import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Service for securely storing sensitive data using Flutter Secure Storage
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // Storage keys
  static const String _masterPasswordHashKey = 'master_password_hash';
  static const String _masterPasswordSaltKey = 'master_password_salt';
  static const String _isSetupCompleteKey = 'is_setup_complete';

  /// Stores the master password securely by hashing it with a salt
  Future<bool> storeMasterPassword(String password) async {
    try {
      // Generate a random salt
      final salt = _generateSalt();

      // Hash the password with the salt
      final hashedPassword = _hashPassword(password, salt);

      // Store both hash and salt
      await _storage.write(key: _masterPasswordHashKey, value: hashedPassword);
      await _storage.write(key: _masterPasswordSaltKey, value: salt);
      await _storage.write(key: _isSetupCompleteKey, value: 'true');

      return true;
    } catch (e) {
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
    final bytes = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch.hashCode + i);
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
      await _storage.containsKey(key: 'test');
      return true;
    } catch (e) {
      return false;
    }
  }
}
