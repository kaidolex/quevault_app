import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../services/encryption_service.dart';
import '../services/encryption_key_service.dart';
import '../services/credential_service.dart';
import '../models/credential.dart';

/// Comprehensive encryption test suite
class ComprehensiveEncryptionTest {
  static Future<void> runAllTests() async {
    if (kDebugMode) {
      print('\n🔐 COMPREHENSIVE ENCRYPTION TEST SUITE');
      print('=====================================\n');

      int passedTests = 0;
      int totalTests = 0;

      // Test 1: Basic Encryption Service
      totalTests++;
      if (await _testBasicEncryption()) {
        passedTests++;
        print('✅ Test 1: Basic Encryption Service - PASSED');
      } else {
        print('❌ Test 1: Basic Encryption Service - FAILED');
      }

      // Test 2: Key Derivation
      totalTests++;
      if (await _testKeyDerivation()) {
        passedTests++;
        print('✅ Test 2: Key Derivation - PASSED');
      } else {
        print('❌ Test 2: Key Derivation - FAILED');
      }

      // Test 3: Encryption Key Service
      totalTests++;
      if (await _testEncryptionKeyService()) {
        passedTests++;
        print('✅ Test 3: Encryption Key Service - PASSED');
      } else {
        print('❌ Test 3: Encryption Key Service - FAILED');
      }

      // Test 4: Credential Encryption Integration
      totalTests++;
      if (await _testCredentialEncryption()) {
        passedTests++;
        print('✅ Test 4: Credential Encryption Integration - PASSED');
      } else {
        print('❌ Test 4: Credential Encryption Integration - FAILED');
      }

      // Test 5: Security Edge Cases
      totalTests++;
      if (await _testSecurityEdgeCases()) {
        passedTests++;
        print('✅ Test 5: Security Edge Cases - PASSED');
      } else {
        print('❌ Test 5: Security Edge Cases - FAILED');
      }

      // Test 6: Performance Test
      totalTests++;
      if (await _testPerformance()) {
        passedTests++;
        print('✅ Test 6: Performance Test - PASSED');
      } else {
        print('❌ Test 6: Performance Test - FAILED');
      }

      print('\n📊 TEST RESULTS');
      print('===============');
      print('Passed: $passedTests/$totalTests');
      print('Success Rate: ${((passedTests / totalTests) * 100).toStringAsFixed(1)}%');

      if (passedTests == totalTests) {
        print('\n🎉 ALL TESTS PASSED! Encryption system is working correctly.');
      } else {
        print('\n⚠️  Some tests failed. Please check the implementation.');
      }
    }
  }

  static Future<bool> _testBasicEncryption() async {
    try {
      final encryptionService = EncryptionService.instance;

      // Test data
      final testPasswords = [
        'SimplePassword',
        'ComplexPassword123!@#',
        'VeryLongPasswordWithSpecialCharacters!@#\$%^&*()_+-=[]{}|;:,.<>?',
        'UnicodePassword123',
        '', // Empty password
      ];

      for (final password in testPasswords) {
        final salt = encryptionService.generateSalt();
        final iv = encryptionService.generateIV();
        final key = encryptionService.deriveKey('MasterPassword123!', salt);

        final encrypted = encryptionService.encrypt(password, key, iv);
        final decrypted = encryptionService.decrypt(encrypted, key, iv);

        if (password != decrypted) {
          print('  Basic encryption failed for password: "$password"');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('  Basic encryption test error: $e');
      return false;
    }
  }

  static Future<bool> _testKeyDerivation() async {
    try {
      final encryptionService = EncryptionService.instance;

      // Test 1: Same password + salt should produce same key
      final password = 'TestPassword123!';
      final salt = encryptionService.generateSalt();

      final key1 = encryptionService.deriveKey(password, salt);
      final key2 = encryptionService.deriveKey(password, salt);

      if (!_compareByteArrays(key1, key2)) {
        print('  Key derivation consistency test failed');
        return false;
      }

      // Test 2: Different passwords should produce different keys
      final key3 = encryptionService.deriveKey('DifferentPassword123!', salt);
      if (_compareByteArrays(key1, key3)) {
        print('  Key derivation uniqueness test failed');
        return false;
      }

      // Test 3: Different salts should produce different keys
      final salt2 = encryptionService.generateSalt();
      final key4 = encryptionService.deriveKey(password, salt2);
      if (_compareByteArrays(key1, key4)) {
        print('  Salt uniqueness test failed');
        return false;
      }

      // Test 4: Key length should be 32 bytes (256 bits)
      if (key1.length != 32) {
        print('  Key length test failed: ${key1.length} bytes');
        return false;
      }

      return true;
    } catch (e) {
      print('  Key derivation test error: $e');
      return false;
    }
  }

  static Future<bool> _testEncryptionKeyService() async {
    try {
      final keyService = EncryptionKeyService.instance;

      // Test 1: Initialize and validate
      final testPassword = 'TestMasterPassword123!';
      final initialized = await keyService.initializeEncryptionKey(testPassword);
      if (!initialized) {
        print('  Key initialization failed');
        return false;
      }

      final validated = await keyService.validateEncryptionKey(testPassword);
      if (!validated) {
        print('  Key validation failed');
        return false;
      }

      // Test 2: Encrypt and decrypt
      final testCredentialPassword = 'MyCredentialPassword456!';
      final encryptionResult = keyService.encryptPassword(testCredentialPassword);
      if (encryptionResult == null) {
        print('  Password encryption failed');
        return false;
      }

      final decryptedPassword = keyService.decryptPassword(encryptionResult['encryptedPassword']!, encryptionResult['iv']!);
      if (decryptedPassword != testCredentialPassword) {
        print('  Password decryption failed');
        return false;
      }

      // Test 3: Clear key
      keyService.clearEncryptionKey();
      if (keyService.isEncryptionKeyAvailable) {
        print('  Key clear failed');
        return false;
      }

      return true;
    } catch (e) {
      print('  Encryption key service test error: $e');
      return false;
    }
  }

  static Future<bool> _testCredentialEncryption() async {
    try {
      final keyService = EncryptionKeyService.instance;
      final credentialService = CredentialService.instance;

      // Initialize encryption key
      await keyService.initializeEncryptionKey('TestMasterPassword123!');

      // Create test credential
      final testCredential = Credential(
        id: 'test_credential_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Credential',
        vaultId: 'test_vault',
        username: 'testuser@example.com',
        password: 'MySecretPassword789!',
        website: 'https://example.com',
        notes: 'Test credential for encryption testing',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save credential (should be encrypted)
      await credentialService.createCredential(testCredential);

      // Retrieve credential (should be decrypted)
      final retrievedCredential = await credentialService.getCredentialById(testCredential.id);
      if (retrievedCredential == null) {
        print('  Credential retrieval failed');
        return false;
      }

      // Verify password was decrypted correctly
      if (retrievedCredential.password != testCredential.password) {
        print('  Credential password decryption failed');
        print('  Expected: ${testCredential.password}');
        print('  Got: ${retrievedCredential.password}');
        return false;
      }

      // Clean up
      await credentialService.deleteCredential(testCredential.id);
      keyService.clearEncryptionKey();

      return true;
    } catch (e) {
      print('  Credential encryption test error: $e');
      return false;
    }
  }

  static Future<bool> _testSecurityEdgeCases() async {
    try {
      final encryptionService = EncryptionService.instance;

      // Test 1: Same password should encrypt to different ciphertext with different IVs
      final password = 'TestPassword123!';
      final salt = encryptionService.generateSalt();
      final key = encryptionService.deriveKey('MasterPassword123!', salt);

      final iv1 = encryptionService.generateIV();
      final iv2 = encryptionService.generateIV();

      final encrypted1 = encryptionService.encrypt(password, key, iv1);
      final encrypted2 = encryptionService.encrypt(password, key, iv2);

      if (encrypted1 == encrypted2) {
        print('  IV uniqueness test failed');
        return false;
      }

      // Test 2: Wrong key should fail decryption
      final wrongKey = encryptionService.deriveKey('WrongPassword123!', salt);
      try {
        encryptionService.decrypt(encrypted1, wrongKey, iv1);
        print('  Wrong key decryption should have failed');
        return false;
      } catch (e) {
        // Expected to fail
      }

      // Test 3: Wrong IV should fail decryption
      final wrongIV = encryptionService.generateIV();
      try {
        encryptionService.decrypt(encrypted1, key, wrongIV);
        print('  Wrong IV decryption should have failed');
        return false;
      } catch (e) {
        // Expected to fail
      }

      return true;
    } catch (e) {
      print('  Security edge cases test error: $e');
      return false;
    }
  }

  static Future<bool> _testPerformance() async {
    try {
      final encryptionService = EncryptionService.instance;
      final stopwatch = Stopwatch();

      // Test encryption performance
      final password = 'TestPassword123!';
      final salt = encryptionService.generateSalt();
      final key = encryptionService.deriveKey('MasterPassword123!', salt);
      final iv = encryptionService.generateIV();

      stopwatch.start();
      for (int i = 0; i < 100; i++) {
        encryptionService.encrypt(password, key, iv);
      }
      stopwatch.stop();

      final avgTime = stopwatch.elapsedMilliseconds / 100;
      print('  Average encryption time: ${avgTime.toStringAsFixed(2)}ms');

      // Performance should be reasonable (less than 10ms per operation)
      if (avgTime > 10) {
        print('  Encryption performance test failed: too slow');
        return false;
      }

      return true;
    } catch (e) {
      print('  Performance test error: $e');
      return false;
    }
  }

  static bool _compareByteArrays(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
