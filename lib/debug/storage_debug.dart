import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';

/// Debug utilities for testing secure storage
class StorageDebug {
  static final _storage = SecureStorageService();

  /// Tests if secure storage is working properly
  static Future<void> testStorageSetup() async {
    if (kDebugMode) {
      print('=== STORAGE DEBUG TEST ===');

      // Test 1: Check if storage is available
      print('Testing storage availability...');
      final isAvailable = await _storage.isStorageAvailable();
      print('Storage available: $isAvailable');

      if (!isAvailable) {
        print('❌ Storage is not available. This is the root cause of the issue.');
        return;
      }

      // Test 2: Clear any existing data
      print('Clearing existing master password data...');
      await _storage.clearMasterPassword();

      // Test 3: Check if master password is setup (should be false now)
      print('Checking if master password is setup...');
      final isSetup = await _storage.isMasterPasswordSetup();
      print('Master password setup: $isSetup');

      // Test 4: Try to store a test password
      print('Testing password storage...');
      const testPassword = 'TestPassword123!';
      final storeResult = await _storage.storeMasterPassword(testPassword);
      print('Store result: $storeResult');

      if (storeResult) {
        // Test 5: Verify the password
        print('Testing password verification...');
        final verifyResult = await _storage.verifyMasterPassword(testPassword);
        print('Verify result: $verifyResult');

        // Test 6: Clean up
        print('Cleaning up test data...');
        await _storage.clearMasterPassword();
        print('✅ All tests passed!');
      } else {
        print('❌ Failed to store test password');
      }

      print('=== END STORAGE DEBUG TEST ===');
    }
  }

  /// Clears all master password data for debugging
  static Future<void> clearAllData() async {
    if (kDebugMode) {
      print('Clearing all master password data...');
      await _storage.clearMasterPassword();
      print('Data cleared.');
    }
  }
}
