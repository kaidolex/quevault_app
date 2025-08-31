import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../core/configs/storage_config.dart';

/// Service for handling biometric authentication
class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const _storage = StorageConfig.secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      return isAvailable && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }

  /// Authenticate using biometrics
  Future<bool> authenticateWithBiometrics({String localizedReason = 'Please authenticate to access your vault'}) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available');
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      // Handle different types of platform exceptions
      switch (e.code) {
        case 'UserCancel':
          throw Exception('Authentication cancelled by user');
        case 'NotAvailable':
          throw Exception('Biometric authentication not available');
        case 'NotEnrolled':
          throw Exception('No biometrics enrolled on this device');
        case 'LockedOut':
          throw Exception('Too many failed attempts. Try again later.');
        case 'PermanentlyLockedOut':
          throw Exception('Biometric authentication permanently locked. Use device settings to unlock.');
        default:
          throw Exception('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Check if biometric authentication is enabled for the app
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _biometricEnabledKey);
      final isEnabled = value == 'true';

      if (kDebugMode) {
        print('BiometricService: isBiometricEnabled - stored value: "$value", result: $isEnabled');
      }

      return isEnabled;
    } catch (e) {
      if (kDebugMode) {
        print('BiometricService: Error checking biometric enabled state: $e');
      }
      return false;
    }
  }

  /// Enable biometric authentication for the app
  Future<bool> enableBiometric() async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: 'true');
      if (kDebugMode) {
        print('BiometricService: Biometric authentication enabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('BiometricService: Error enabling biometric: $e');
      }
      return false;
    }
  }

  /// Disable biometric authentication for the app
  Future<bool> disableBiometric() async {
    try {
      await _storage.delete(key: _biometricEnabledKey);
      if (kDebugMode) {
        print('BiometricService: Biometric authentication disabled');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('BiometricService: Error disabling biometric: $e');
      }
      return false;
    }
  }

  /// Get user-friendly biometric type name
  String getBiometricTypeName(List<BiometricType> types) {
    if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (types.isNotEmpty) {
      return 'Biometric';
    }
    return 'None';
  }

  /// Get the primary biometric type available
  Future<String> getPrimaryBiometricType() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return getBiometricTypeName(availableBiometrics);
    } catch (e) {
      return 'None';
    }
  }

  /// Test storage read/write functionality for biometric settings
  Future<bool> testBiometricStorage() async {
    try {
      const testKey = 'biometric_test';
      const testValue = 'test_biometric_value';

      // Write test value
      await _storage.write(key: testKey, value: testValue);
      if (kDebugMode) {
        print('BiometricService: Test value written to storage');
      }

      // Read test value
      final readValue = await _storage.read(key: testKey);
      if (kDebugMode) {
        print('BiometricService: Test value read from storage: "$readValue"');
      }

      // Clean up
      await _storage.delete(key: testKey);

      final success = readValue == testValue;
      if (kDebugMode) {
        print('BiometricService: Storage test ${success ? 'PASSED' : 'FAILED'}');
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('BiometricService: Storage test failed with error: $e');
      }
      return false;
    }
  }

  /// Setup biometric authentication (requires master password verification first)
  Future<bool> setupBiometric({required String masterPassword, required Future<bool> Function(String) verifyMasterPassword}) async {
    try {
      // First verify the master password
      final isPasswordValid = await verifyMasterPassword(masterPassword);
      if (!isPasswordValid) {
        throw Exception('Invalid master password');
      }

      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometric authentication is not available on this device');
      }

      // Test biometric authentication
      final authenticated = await authenticateWithBiometrics(localizedReason: 'Please authenticate to enable biometric unlock');

      if (!authenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Enable biometric authentication
      final enabled = await enableBiometric();
      if (!enabled) {
        throw Exception('Failed to enable biometric authentication');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }
}
