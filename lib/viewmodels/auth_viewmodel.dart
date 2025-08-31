import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../services/onboarding_service.dart';
import '../services/vault_service.dart';
import '../services/encryption_key_service.dart';
import '../models/vault.dart';

/// Authentication state
@immutable
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isMasterPasswordSetup;
  final bool isOnboardingComplete;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final String biometricType;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.isMasterPasswordSetup = false,
    this.isOnboardingComplete = false,
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
    this.biometricType = 'None',
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isMasterPasswordSetup,
    bool? isOnboardingComplete,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
    String? biometricType,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isMasterPasswordSetup: isMasterPasswordSetup ?? this.isMasterPasswordSetup,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      biometricType: biometricType ?? this.biometricType,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  /// Creates a loading state
  AuthState loading() {
    return copyWith(isLoading: true, errorMessage: null, successMessage: null);
  }

  /// Creates a success state
  AuthState success({String? message}) {
    return copyWith(isLoading: false, successMessage: message, errorMessage: null);
  }

  /// Creates an error state
  AuthState error(String message) {
    return copyWith(isLoading: false, errorMessage: message, successMessage: null);
  }
}

/// Auth ViewModel using Riverpod StateNotifier
class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final OnboardingService _onboardingService;

  AuthViewModel(this._authRepository, this._onboardingService) : super(const AuthState()) {
    _checkInitialState();
  }

  /// Force refresh of all state - useful for debugging or when app resumes
  Future<void> forceRefreshState() async {
    await _checkInitialState();
  }

  /// Debug method to print current biometric state
  Future<void> debugBiometricState() async {
    if (kDebugMode) {
      final isBiometricAvailable = await _authRepository.isBiometricAvailable();
      final isBiometricEnabled = await _authRepository.isBiometricEnabled();
      final biometricType = await _authRepository.getPrimaryBiometricType();
      final storageTest = await _authRepository.testBiometricStorage();

      print('=== BIOMETRIC DEBUG STATE ===');
      print('Available: $isBiometricAvailable');
      print('Enabled: $isBiometricEnabled');
      print('Type: $biometricType');
      print('Storage Test: ${storageTest ? 'PASSED' : 'FAILED'}');
      print('Current State - Available: ${state.isBiometricAvailable}, Enabled: ${state.isBiometricEnabled}, Type: ${state.biometricType}');
      print('============================');
    }
  }

  /// Checks initial authentication state
  Future<void> _checkInitialState() async {
    state = state.loading();

    try {
      final isSetup = await _authRepository.isMasterPasswordSetup();
      final isOnboardingComplete = await _onboardingService.isOnboardingComplete();
      final isBiometricAvailable = await _authRepository.isBiometricAvailable();
      final isBiometricEnabled = await _authRepository.isBiometricEnabled();
      final biometricType = await _authRepository.getPrimaryBiometricType();

      if (kDebugMode) {
        print('AuthViewModel: Initial state check - isBiometricEnabled: $isBiometricEnabled, isBiometricAvailable: $isBiometricAvailable');
      }

      state = state.copyWith(
        isLoading: false,
        isMasterPasswordSetup: isSetup,
        isOnboardingComplete: isOnboardingComplete,
        isBiometricAvailable: isBiometricAvailable,
        isBiometricEnabled: isBiometricEnabled,
        biometricType: biometricType,
      );
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: Error checking initial state: $e');
      }
      state = state.error('Failed to check authentication state');
    }
  }

  /// Sets up master password
  Future<void> setupMasterPassword(String password, String confirmPassword) async {
    state = state.loading();

    try {
      final request = MasterPasswordSetupRequest(password: password, confirmPassword: confirmPassword);

      final result = await _authRepository.setupMasterPassword(request);

      if (result.success) {
        // Initialize encryption key
        final encryptionKeyInitialized = await EncryptionKeyService.instance.initializeEncryptionKey(password);
        if (!encryptionKeyInitialized) {
          if (kDebugMode) {
            print('AuthViewModel: Failed to initialize encryption key during setup');
          }
        }

        // Initialize database and create default vault
        await _initializeDatabaseAndDefaultVault();

        state = state.copyWith(isLoading: false, isMasterPasswordSetup: true, isAuthenticated: true, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Failed to setup master password');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Initialize database and create default vault
  Future<void> _initializeDatabaseAndDefaultVault() async {
    try {
      // Initialize the database (this will create the vaults table)
      await VaultService.instance.database;

      // Create default "Main Vault"
      final defaultVault = Vault(
        id: 'main_vault_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Main Vault',
        description: 'Your primary vault for storing passwords and sensitive information',
        color: Colors.blue.toARGB32(),
        isHidden: false,
        needsUnlock: false,
        useMasterKey: true,
        useDifferentUnlockKey: false,
        unlockKey: null,
        useFingerprint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await VaultService.instance.createVault(defaultVault);

      if (kDebugMode) {
        print('AuthViewModel: Database initialized and default vault created successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthViewModel: Error initializing database: $e');
      }
      // Don't fail the entire setup process if database initialization fails
      // The user can still use the app and create vaults manually
    }
  }

  /// Logs in with master password
  Future<void> login(String password) async {
    state = state.loading();

    try {
      final request = LoginRequest(password: password);
      final result = await _authRepository.login(request);

      if (result.success) {
        // Initialize encryption key for decryption
        final encryptionKeyValidated = await EncryptionKeyService.instance.validateEncryptionKey(password);
        if (!encryptionKeyValidated) {
          if (kDebugMode) {
            print('AuthViewModel: Failed to validate encryption key during login');
          }
        }

        state = state.copyWith(isLoading: false, isAuthenticated: true, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Login failed');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Changes master password
  Future<void> changePassword(String currentPassword, String newPassword, String confirmNewPassword) async {
    state = state.loading();

    try {
      final request = ChangePasswordRequest(currentPassword: currentPassword, newPassword: newPassword, confirmNewPassword: confirmNewPassword);

      final result = await _authRepository.changePassword(request);

      if (result.success) {
        state = state.success(message: result.message);
      } else {
        state = state.error(result.message ?? 'Failed to change password');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Logs out the user
  void logout() {
    // Clear encryption key for security
    EncryptionKeyService.instance.clearEncryptionKey();

    // Preserve biometric settings when logging out
    state = state.copyWith(
      isAuthenticated: false,
      successMessage: 'Logged out successfully',
      // Explicitly preserve biometric state
      isBiometricAvailable: state.isBiometricAvailable,
      isBiometricEnabled: state.isBiometricEnabled,
      biometricType: state.biometricType,
    );
  }

  /// Resets authentication (clears all data)
  Future<void> resetAuth() async {
    state = state.loading();

    try {
      final result = await _authRepository.resetAuth();

      if (result.success) {
        // Preserve biometric settings when resetting auth
        final isBiometricAvailable = await _authRepository.isBiometricAvailable();
        final isBiometricEnabled = await _authRepository.isBiometricEnabled();
        final biometricType = await _authRepository.getPrimaryBiometricType();

        state = const AuthState().copyWith(
          isLoading: false,
          successMessage: result.message,
          isBiometricAvailable: isBiometricAvailable,
          isBiometricEnabled: isBiometricEnabled,
          biometricType: biometricType,
        );
      } else {
        state = state.error(result.message ?? 'Failed to reset authentication');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Clears messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// Gets password strength
  PasswordStrength getPasswordStrength(String password) {
    final request = MasterPasswordSetupRequest(password: password, confirmPassword: '');
    return request.getPasswordStrength(password);
  }

  /// Validates password setup
  AuthResult validatePasswordSetup(String password, String confirmPassword) {
    final request = MasterPasswordSetupRequest(password: password, confirmPassword: confirmPassword);
    return request.validate();
  }

  /// Completes onboarding process
  Future<void> completeOnboarding() async {
    try {
      await _onboardingService.completeOnboarding();
      state = state.copyWith(isOnboardingComplete: true);
    } catch (e) {
      state = state.error('Failed to complete onboarding');
    }
  }

  /// Resets onboarding (for testing/debugging)
  Future<void> resetOnboarding() async {
    try {
      await _onboardingService.resetOnboarding();
      state = state.copyWith(isOnboardingComplete: false);
    } catch (e) {
      state = state.error('Failed to reset onboarding');
    }
  }

  // Biometric Authentication Methods

  /// Enables biometric authentication
  Future<void> enableBiometric(String masterPassword) async {
    state = state.loading();

    try {
      final result = await _authRepository.enableBiometric(masterPassword);

      if (result.success) {
        // Refresh biometric status
        final isBiometricEnabled = await _authRepository.isBiometricEnabled();
        state = state.copyWith(isLoading: false, isBiometricEnabled: isBiometricEnabled, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Failed to enable biometric authentication');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Disables biometric authentication
  Future<void> disableBiometric() async {
    state = state.loading();

    try {
      final result = await _authRepository.disableBiometric();

      if (result.success) {
        state = state.copyWith(isLoading: false, isBiometricEnabled: false, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Failed to disable biometric authentication');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Authenticates using biometric
  Future<void> loginWithBiometric() async {
    state = state.loading();

    try {
      final result = await _authRepository.loginWithBiometric();

      if (result.success) {
        state = state.copyWith(isLoading: false, isAuthenticated: true, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Biometric authentication failed');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Refreshes biometric status
  Future<void> refreshBiometricStatus() async {
    try {
      final isBiometricAvailable = await _authRepository.isBiometricAvailable();
      final isBiometricEnabled = await _authRepository.isBiometricEnabled();
      final biometricType = await _authRepository.getPrimaryBiometricType();

      state = state.copyWith(isBiometricAvailable: isBiometricAvailable, isBiometricEnabled: isBiometricEnabled, biometricType: biometricType);
    } catch (e) {
      // Silent error - don't show to user
      if (kDebugMode) {
        print('AuthViewModel: Error refreshing biometric status: $e');
      }
    }
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final onboardingService = ref.watch(onboardingServiceProvider);
  return AuthViewModel(repository, onboardingService);
});

// Helper providers for specific state access
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isLoading;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isAuthenticated;
});

final isMasterPasswordSetupProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isMasterPasswordSetup;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authViewModelProvider).errorMessage;
});

final authSuccessProvider = Provider<String?>((ref) {
  return ref.watch(authViewModelProvider).successMessage;
});

final isOnboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isOnboardingComplete;
});
