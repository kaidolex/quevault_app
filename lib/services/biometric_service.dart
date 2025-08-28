import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling biometric authentication
class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
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
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric authentication for the app
  Future<bool> enableBiometric() async {
    try {
      await _storage.write(key: _biometricEnabledKey, value: 'true');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric authentication for the app
  Future<bool> disableBiometric() async {
    try {
      await _storage.delete(key: _biometricEnabledKey);
      return true;
    } catch (e) {
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
