import 'package:flutter/foundation.dart';
import '../services/encryption_service.dart';
import '../services/encryption_key_service.dart';

/// Debug test for encryption functionality
class EncryptionTest {
  static Future<void> runEncryptionTest() async {
    if (kDebugMode) {
      print('=== ENCRYPTION TEST START ===');

      try {
        // Test 1: Basic encryption service
        print('Test 1: Basic encryption service...');
        final encryptionService = EncryptionService.instance;

        final testPassword = 'MySecretPassword123!';
        final salt = encryptionService.generateSalt();
        final iv = encryptionService.generateIV();
        final key = encryptionService.deriveKey(testPassword, salt);

        print('Salt: ${salt.substring(0, 10)}...');
        print('IV: ${iv.substring(0, 10)}...');
        print('Key length: ${key.length} bytes');

        // Test encryption/decryption
        final encrypted = encryptionService.encrypt(testPassword, key, iv);
        final decrypted = encryptionService.decrypt(encrypted, key, iv);

        print('Original: $testPassword');
        print('Encrypted: ${encrypted.substring(0, 20)}...');
        print('Decrypted: $decrypted');
        print('Encryption/Decryption Test: ${testPassword == decrypted ? 'PASSED' : 'FAILED'}');

        // Test 2: Password encryption helper
        print('\nTest 2: Password encryption helper...');
        final passwordEncryption = encryptionService.encryptPassword(testPassword, key);
        final encryptedPassword = passwordEncryption['encryptedPassword']!;
        final passwordIV = passwordEncryption['iv']!;

        final decryptedPassword = encryptionService.decryptPassword(encryptedPassword, key, passwordIV);
        print('Password Encryption Test: ${testPassword == decryptedPassword ? 'PASSED' : 'FAILED'}');

        // Test 3: Key validation
        print('\nTest 3: Key validation...');
        final testEncryption = encryptionService.generateTestEncryption(key);
        final isValid = encryptionService.validateKey(key, testEncryption['encryptedPassword']!, testEncryption['iv']!);
        print('Key Validation Test: ${isValid ? 'PASSED' : 'FAILED'}');

        // Test 4: Wrong key should fail
        print('\nTest 4: Wrong key test...');
        final wrongPassword = 'WrongPassword123!';
        final wrongKey = encryptionService.deriveKey(wrongPassword, salt);
        final isWrongKeyValid = encryptionService.validateKey(wrongKey, testEncryption['encryptedPassword']!, testEncryption['iv']!);
        print('Wrong Key Test: ${!isWrongKeyValid ? 'PASSED' : 'FAILED'}');

        print('\n=== ENCRYPTION TEST COMPLETE ===');
      } catch (e) {
        print('Encryption test failed: $e');
      }
    }
  }

  static Future<void> runEncryptionKeyServiceTest() async {
    if (kDebugMode) {
      print('=== ENCRYPTION KEY SERVICE TEST START ===');

      try {
        final keyService = EncryptionKeyService.instance;

        // Test 1: Initialize encryption key
        print('Test 1: Initialize encryption key...');
        final testPassword = 'TestMasterPassword123!';
        final initialized = await keyService.initializeEncryptionKey(testPassword);
        print('Key Initialization: ${initialized ? 'PASSED' : 'FAILED'}');

        if (initialized) {
          // Test 2: Validate encryption key
          print('\nTest 2: Validate encryption key...');
          final validated = await keyService.validateEncryptionKey(testPassword);
          print('Key Validation: ${validated ? 'PASSED' : 'FAILED'}');

          // Test 3: Encrypt/decrypt password
          print('\nTest 3: Encrypt/decrypt password...');
          final testCredentialPassword = 'MyCredentialPassword456!';
          final encryptionResult = keyService.encryptPassword(testCredentialPassword);

          if (encryptionResult != null) {
            final decryptedPassword = keyService.decryptPassword(encryptionResult['encryptedPassword']!, encryptionResult['iv']!);
            print('Credential Password Test: ${testCredentialPassword == decryptedPassword ? 'PASSED' : 'FAILED'}');
          } else {
            print('Credential Password Test: FAILED - Encryption returned null');
          }

          // Test 4: Clear key
          print('\nTest 4: Clear encryption key...');
          keyService.clearEncryptionKey();
          final isAvailable = keyService.isEncryptionKeyAvailable;
          print('Key Clear Test: ${!isAvailable ? 'PASSED' : 'FAILED'}');
        }

        print('\n=== ENCRYPTION KEY SERVICE TEST COMPLETE ===');
      } catch (e) {
        print('Encryption key service test failed: $e');
      }
    }
  }
}
