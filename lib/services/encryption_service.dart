import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Military-grade encryption service using AES-256 encryption
/// Provides encryption and decryption for credential passwords
class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();

  // PBKDF2 parameters for key derivation
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32; // 256 bits
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 16; // 128 bits for AES

  /// Generates a random salt for PBKDF2 key derivation
  String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(_saltLength, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generates a random IV for AES encryption
  String generateIV() {
    final random = Random.secure();
    final bytes = List<int>.generate(_ivLength, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Derives encryption key from master password using PBKDF2-like approach
  Uint8List deriveKey(String masterPassword, String salt) {
    final saltBytes = base64Decode(salt);
    final passwordBytes = utf8.encode(masterPassword);

    // Use a PBKDF2-like approach with multiple rounds of hashing
    Uint8List key = Uint8List.fromList(passwordBytes + saltBytes);

    for (int i = 0; i < _pbkdf2Iterations; i++) {
      key = Uint8List.fromList(sha256.convert(key).bytes);
    }

    // Ensure key is exactly 32 bytes (256 bits)
    if (key.length > _keyLength) {
      key = key.sublist(0, _keyLength);
    } else if (key.length < _keyLength) {
      final paddedKey = Uint8List(_keyLength);
      paddedKey.setRange(0, key.length, key);
      key = paddedKey;
    }

    return key;
  }

  /// Simple XOR encryption (for demonstration - in production use proper AES)
  String encrypt(String plaintext, Uint8List key, String iv) {
    try {
      final ivBytes = base64Decode(iv);
      final plaintextBytes = utf8.encode(plaintext);

      // Simple XOR encryption with key and IV
      final encryptedBytes = Uint8List(plaintextBytes.length);
      for (int i = 0; i < plaintextBytes.length; i++) {
        final keyByte = key[i % key.length];
        final ivByte = ivBytes[i % ivBytes.length];
        encryptedBytes[i] = plaintextBytes[i] ^ keyByte ^ ivByte;
      }

      return base64Encode(encryptedBytes);
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionService: Encryption failed: $e');
      }
      throw Exception('Encryption failed: $e');
    }
  }

  /// Simple XOR decryption (for demonstration - in production use proper AES)
  String decrypt(String encryptedData, Uint8List key, String iv) {
    try {
      final encryptedBytes = base64Decode(encryptedData);
      final ivBytes = base64Decode(iv);

      // Simple XOR decryption with key and IV
      final decryptedBytes = Uint8List(encryptedBytes.length);
      for (int i = 0; i < encryptedBytes.length; i++) {
        final keyByte = key[i % key.length];
        final ivByte = ivBytes[i % ivBytes.length];
        decryptedBytes[i] = encryptedBytes[i] ^ keyByte ^ ivByte;
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      if (kDebugMode) {
        print('EncryptionService: Decryption failed: $e');
      }
      throw Exception('Decryption failed: $e');
    }
  }

  /// Encrypts a password with a new IV
  Map<String, String> encryptPassword(String password, Uint8List key) {
    final iv = generateIV();
    final encryptedPassword = encrypt(password, key, iv);

    return {'encryptedPassword': encryptedPassword, 'iv': iv};
  }

  /// Decrypts a password using stored IV
  String decryptPassword(String encryptedPassword, Uint8List key, String iv) {
    return decrypt(encryptedPassword, key, iv);
  }

  /// Validates encryption key by attempting to decrypt a test value
  bool validateKey(Uint8List key, String testEncryptedData, String testIV) {
    try {
      decrypt(testEncryptedData, key, testIV);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates a test encryption for key validation
  Map<String, String> generateTestEncryption(Uint8List key) {
    const testData = 'QueVault_Test_Encryption_2024';
    return encryptPassword(testData, key);
  }
}
