import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/configs/storage_config.dart';
import 'encryption_service.dart';

/// Service for managing encryption keys derived from master password
class EncryptionKeyService {
  static final EncryptionKeyService instance = EncryptionKeyService._internal();
  EncryptionKeyService._internal();

  static const String _encryptionSaltKey = 'encryption_salt';
  static const String _testEncryptedDataKey = 'test_encrypted_data';
  static const String _testIVKey = 'test_iv';

  Uint8List? _currentEncryptionKey;
  String? _currentSalt;

  /// Gets the current encryption key (derived from master password)
  Uint8List? get currentEncryptionKey => _currentEncryptionKey;

  /// Gets the current salt used for key derivation
  String? get currentSalt => _currentSalt;

  /// Initializes encryption key from master password
  Future<bool> initializeEncryptionKey(String masterPassword) async {
    try {
      if (kDebugMode) {
        print('EncryptionKeyService: Initializing encryption key');
      }

      // Get or generate salt
      String? salt = await _getEncryptedData(_encryptionSaltKey);
      if (salt == null) {
        salt = EncryptionService.instance.generateSalt();
        await _storeEncryptedData(_encryptionSaltKey, salt);
        if (kDebugMode) {
          print('EncryptionKeyService: Generated new salt');
        }
      }

      // Derive encryption key
      final encryptionKey = EncryptionService.instance.deriveKey(masterPassword, salt);

      // Validate key by testing encryption/decryption
      final testEncryption = EncryptionService.instance.generateTestEncryption(encryptionKey);

      // Store test data for future validation
      await _storeEncryptedData(_testEncryptedDataKey, testEncryption['encryptedPassword']!);
      await _storeEncryptedData(_testIVKey, testEncryption['iv']!);

      // Set current key and salt
      _currentEncryptionKey = encryptionKey;
      _currentSalt = salt;

      if (kDebugMode) {
        print('EncryptionKeyService: Encryption key initialized successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionKeyService: Failed to initialize encryption key: $e');
      }
      return false;
    }
  }

  /// Validates encryption key by testing decryption
  Future<bool> validateEncryptionKey(String masterPassword) async {
    try {
      final salt = await _getEncryptedData(_encryptionSaltKey);
      if (salt == null) {
        return false;
      }

      final testEncryptedData = await _getEncryptedData(_testEncryptedDataKey);
      final testIV = await _getEncryptedData(_testIVKey);

      if (testEncryptedData == null || testIV == null) {
        return false;
      }

      final encryptionKey = EncryptionService.instance.deriveKey(masterPassword, salt);
      final isValid = EncryptionService.instance.validateKey(encryptionKey, testEncryptedData, testIV);

      if (isValid) {
        _currentEncryptionKey = encryptionKey;
        _currentSalt = salt;
      }

      return isValid;
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionKeyService: Failed to validate encryption key: $e');
      }
      return false;
    }
  }

  /// Clears the current encryption key (for logout)
  void clearEncryptionKey() {
    _currentEncryptionKey = null;
    _currentSalt = null;
    if (kDebugMode) {
      print('EncryptionKeyService: Encryption key cleared');
    }
  }

  /// Checks if encryption key is available
  bool get isEncryptionKeyAvailable => _currentEncryptionKey != null;

  /// Encrypts a password using the current encryption key
  Map<String, String>? encryptPassword(String password) {
    if (_currentEncryptionKey == null) {
      if (kDebugMode) {
        print('EncryptionKeyService: No encryption key available');
      }
      return null;
    }

    try {
      return EncryptionService.instance.encryptPassword(password, _currentEncryptionKey!);
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionKeyService: Failed to encrypt password: $e');
      }
      return null;
    }
  }

  /// Decrypts a password using the current encryption key
  String? decryptPassword(String encryptedPassword, String iv) {
    if (_currentEncryptionKey == null) {
      if (kDebugMode) {
        print('EncryptionKeyService: No encryption key available');
      }
      return null;
    }

    try {
      return EncryptionService.instance.decryptPassword(encryptedPassword, _currentEncryptionKey!, iv);
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionKeyService: Failed to decrypt password: $e');
      }
      return null;
    }
  }

  /// Stores encrypted data with a key
  Future<bool> _storeEncryptedData(String key, String data) async {
    try {
      await StorageConfig.secureStorage.write(key: key, value: data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Retrieves encrypted data by key
  Future<String?> _getEncryptedData(String key) async {
    try {
      return await StorageConfig.secureStorage.read(key: key);
    } catch (e) {
      return null;
    }
  }
}
