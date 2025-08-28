import '../models/auth_models.dart';
import '../services/secure_storage_service.dart';
import '../services/biometric_service.dart';

/// Repository for handling authentication operations
class AuthRepository {
  final SecureStorageService _secureStorageService;
  final BiometricService _biometricService;

  AuthRepository({SecureStorageService? secureStorageService, BiometricService? biometricService})
    : _secureStorageService = secureStorageService ?? SecureStorageService(),
      _biometricService = biometricService ?? BiometricService();

  /// Sets up the master password for the first time
  Future<AuthResult> setupMasterPassword(MasterPasswordSetupRequest request) async {
    try {
      // Validate the request
      final validation = request.validate();
      if (!validation.success) {
        return validation;
      }

      // Check if secure storage is available
      final isStorageAvailable = await _secureStorageService.isStorageAvailable();
      if (!isStorageAvailable) {
        return AuthResult.failure(
          message: 'Secure storage is not available on this device. Please check your device settings.',
          error: AuthError.storageError,
        );
      }

      // Check if master password is already set up
      final isAlreadySetup = await _secureStorageService.isMasterPasswordSetup();
      if (isAlreadySetup) {
        return AuthResult.failure(message: 'Master password is already set up', error: AuthError.unknown);
      }

      // Store the master password
      final success = await _secureStorageService.storeMasterPassword(request.password);

      if (success) {
        return AuthResult.success(message: 'Master password has been set successfully!');
      } else {
        return AuthResult.failure(message: 'Failed to store master password. Please try again.', error: AuthError.storageError);
      }
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: ${e.toString()}', error: AuthError.unknown);
    }
  }

  /// Authenticates user with master password
  Future<AuthResult> login(LoginRequest request) async {
    try {
      // Validate the request
      final validation = request.validate();
      if (!validation.success) {
        return validation;
      }

      // Check if master password is set up
      final isSetup = await _secureStorageService.isMasterPasswordSetup();
      if (!isSetup) {
        return AuthResult.failure(message: 'Master password is not set up', error: AuthError.unknown);
      }

      // Verify the password
      final isValid = await _secureStorageService.verifyMasterPassword(request.password);

      if (isValid) {
        return AuthResult.success(message: 'Login successful');
      } else {
        return AuthResult.failure(message: 'Invalid master password', error: AuthError.invalidPassword);
      }
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: ${e.toString()}', error: AuthError.unknown);
    }
  }

  /// Changes the master password
  Future<AuthResult> changePassword(ChangePasswordRequest request) async {
    try {
      // Validate the request
      final validation = request.validate();
      if (!validation.success) {
        return validation;
      }

      // Change the password
      final success = await _secureStorageService.changeMasterPassword(request.currentPassword, request.newPassword);

      if (success) {
        return AuthResult.success(message: 'Password changed successfully');
      } else {
        return AuthResult.failure(message: 'Failed to change password. Please check your current password.', error: AuthError.invalidPassword);
      }
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: ${e.toString()}', error: AuthError.unknown);
    }
  }

  /// Checks if master password is set up
  Future<bool> isMasterPasswordSetup() async {
    try {
      return await _secureStorageService.isMasterPasswordSetup();
    } catch (e) {
      return false;
    }
  }

  /// Resets all authentication data (logout/reset)
  Future<AuthResult> resetAuth() async {
    try {
      final success = await _secureStorageService.clearMasterPassword();

      if (success) {
        return AuthResult.success(message: 'Authentication data cleared');
      } else {
        return AuthResult.failure(message: 'Failed to clear authentication data', error: AuthError.storageError);
      }
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: ${e.toString()}', error: AuthError.unknown);
    }
  }

  /// Checks if secure storage is available
  Future<bool> isStorageAvailable() async {
    try {
      return await _secureStorageService.isStorageAvailable();
    } catch (e) {
      return false;
    }
  }

  // Biometric Authentication Methods

  /// Checks if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _biometricService.isBiometricAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Checks if biometric authentication is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      return await _biometricService.isBiometricEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Gets the primary biometric type
  Future<String> getPrimaryBiometricType() async {
    try {
      return await _biometricService.getPrimaryBiometricType();
    } catch (e) {
      return 'None';
    }
  }

  /// Enables biometric authentication (requires master password verification)
  Future<AuthResult> enableBiometric(String masterPassword) async {
    try {
      // Check if master password is correct first
      final isPasswordValid = await _secureStorageService.verifyMasterPassword(masterPassword);
      if (!isPasswordValid) {
        return AuthResult.failure(message: 'Invalid master password', error: AuthError.invalidPassword);
      }

      // Setup biometric authentication
      final success = await _biometricService.setupBiometric(
        masterPassword: masterPassword,
        verifyMasterPassword: _secureStorageService.verifyMasterPassword,
      );

      if (success) {
        return AuthResult.success(message: 'Biometric authentication enabled successfully');
      } else {
        return AuthResult.failure(message: 'Failed to enable biometric authentication', error: AuthError.unknown);
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().contains('Exception: ')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to enable biometric authentication: ${e.toString()}',
        error: AuthError.unknown,
      );
    }
  }

  /// Disables biometric authentication
  Future<AuthResult> disableBiometric() async {
    try {
      final success = await _biometricService.disableBiometric();

      if (success) {
        return AuthResult.success(message: 'Biometric authentication disabled');
      } else {
        return AuthResult.failure(message: 'Failed to disable biometric authentication', error: AuthError.unknown);
      }
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: ${e.toString()}', error: AuthError.unknown);
    }
  }

  /// Authenticates using biometric
  Future<AuthResult> loginWithBiometric() async {
    try {
      // Check if biometric is enabled
      final isEnabled = await _biometricService.isBiometricEnabled();
      if (!isEnabled) {
        return AuthResult.failure(message: 'Biometric authentication is not enabled', error: AuthError.unknown);
      }

      // Check if master password is set up
      final isSetup = await _secureStorageService.isMasterPasswordSetup();
      if (!isSetup) {
        return AuthResult.failure(message: 'Master password is not set up', error: AuthError.unknown);
      }

      // Authenticate using biometric
      final success = await _biometricService.authenticateWithBiometrics(localizedReason: 'Unlock your QueVault with your fingerprint');

      if (success) {
        return AuthResult.success(message: 'Biometric authentication successful');
      } else {
        return AuthResult.failure(message: 'Biometric authentication failed', error: AuthError.unknown);
      }
    } catch (e) {
      return AuthResult.failure(
        message: e.toString().contains('Exception: ')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Biometric authentication failed: ${e.toString()}',
        error: AuthError.unknown,
      );
    }
  }
}
