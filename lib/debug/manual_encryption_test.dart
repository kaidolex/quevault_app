import 'package:flutter/foundation.dart';
import '../services/encryption_service.dart';
import '../services/encryption_key_service.dart';

/// Simple manual encryption test for quick verification
class ManualEncryptionTest {
  static Future<void> runQuickTest() async {
    if (kDebugMode) {
      print('\n🔐 QUICK ENCRYPTION TEST');
      print('========================\n');

      try {
        // Test 1: Basic encryption/decryption
        print('1. Testing basic encryption/decryption...');
        final encryptionService = EncryptionService.instance;

        final testPassword = 'MySecretPassword123!';
        final salt = encryptionService.generateSalt();
        final iv = encryptionService.generateIV();
        final key = encryptionService.deriveKey('MasterPassword123!', salt);

        final encrypted = encryptionService.encrypt(testPassword, key, iv);
        final decrypted = encryptionService.decrypt(encrypted, key, iv);

        print('   Original: $testPassword');
        print('   Encrypted: ${encrypted.substring(0, 20)}...');
        print('   Decrypted: $decrypted');
        print('   ✅ Basic encryption/decryption: ${testPassword == decrypted ? 'PASSED' : 'FAILED'}');

        // Test 2: Key service
        print('\n2. Testing encryption key service...');
        final keyService = EncryptionKeyService.instance;

        final initialized = await keyService.initializeEncryptionKey('TestMasterPassword123!');
        print('   ✅ Key initialization: ${initialized ? 'PASSED' : 'FAILED'}');

        if (initialized) {
          final validated = await keyService.validateEncryptionKey('TestMasterPassword123!');
          print('   ✅ Key validation: ${validated ? 'PASSED' : 'FAILED'}');

          final encryptionResult = keyService.encryptPassword('TestCredentialPassword456!');
          if (encryptionResult != null) {
            final decryptedPassword = keyService.decryptPassword(encryptionResult['encryptedPassword']!, encryptionResult['iv']!);
            print('   ✅ Credential encryption: ${decryptedPassword == 'TestCredentialPassword456!' ? 'PASSED' : 'FAILED'}');
          } else {
            print('   ❌ Credential encryption: FAILED');
          }

          keyService.clearEncryptionKey();
          print('   ✅ Key clear: ${!keyService.isEncryptionKeyAvailable ? 'PASSED' : 'FAILED'}');
        }

        // Test 3: Security test
        print('\n3. Testing security features...');
        final iv1 = encryptionService.generateIV();
        final iv2 = encryptionService.generateIV();

        final encrypted1 = encryptionService.encrypt(testPassword, key, iv1);
        final encrypted2 = encryptionService.encrypt(testPassword, key, iv2);

        print('   ✅ IV uniqueness: ${encrypted1 != encrypted2 ? 'PASSED' : 'FAILED'}');

        // Test wrong key
        final wrongKey = encryptionService.deriveKey('WrongPassword123!', salt);
        bool wrongKeyFailed = false;
        try {
          encryptionService.decrypt(encrypted1, wrongKey, iv1);
        } catch (e) {
          wrongKeyFailed = true;
        }
        print('   ✅ Wrong key protection: ${wrongKeyFailed ? 'PASSED' : 'FAILED'}');

        print('\n🎉 QUICK TEST COMPLETE!');
        print('If all tests show ✅ PASSED, your encryption system is working correctly.');
      } catch (e) {
        print('❌ Test failed with error: $e');
      }
    }
  }

  static void runSimpleTest() {
    if (kDebugMode) {
      print('\n🔐 SIMPLE ENCRYPTION TEST');
      print('=========================\n');

      try {
        final encryptionService = EncryptionService.instance;

        // Simple test
        final password = 'TestPassword123!';
        final salt = encryptionService.generateSalt();
        final iv = encryptionService.generateIV();
        final key = encryptionService.deriveKey('MasterPassword123!', salt);

        final encrypted = encryptionService.encrypt(password, key, iv);
        final decrypted = encryptionService.decrypt(encrypted, key, iv);

        print('Original: $password');
        print('Encrypted: ${encrypted.substring(0, 20)}...');
        print('Decrypted: $decrypted');
        print('Result: ${password == decrypted ? '✅ PASSED' : '❌ FAILED'}');
      } catch (e) {
        print('❌ Error: $e');
      }
    }
  }
}
