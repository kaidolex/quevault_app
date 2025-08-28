import '../models/auth_models.dart';
import '../services/secure_storage_service.dart';

/// Repository for handling authentication operations
class AuthRepository {
  final SecureStorageService _secureStorageService;

  AuthRepository({SecureStorageService? secureStorageService}) : _secureStorageService = secureStorageService ?? SecureStorageService();

  /// Sets up the master password for the first time
  Future<AuthResult> setupMasterPassword(MasterPasswordSetupRequest request) async {
    try {
      // Validate the request
      final validation = request.validate();
      if (!validation.success) {
        return validation;
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
}
