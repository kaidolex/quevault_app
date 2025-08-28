import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../services/onboarding_service.dart';

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

  /// Checks initial authentication state
  Future<void> _checkInitialState() async {
    state = state.loading();

    try {
      final isSetup = await _authRepository.isMasterPasswordSetup();
      final isOnboardingComplete = await _onboardingService.isOnboardingComplete();
      final isBiometricAvailable = await _authRepository.isBiometricAvailable();
      final isBiometricEnabled = await _authRepository.isBiometricEnabled();
      final biometricType = await _authRepository.getPrimaryBiometricType();

      state = state.copyWith(
        isLoading: false,
        isMasterPasswordSetup: isSetup,
        isOnboardingComplete: isOnboardingComplete,
        isBiometricAvailable: isBiometricAvailable,
        isBiometricEnabled: isBiometricEnabled,
        biometricType: biometricType,
      );
    } catch (e) {
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
        state = state.copyWith(isLoading: false, isMasterPasswordSetup: true, isAuthenticated: true, successMessage: result.message);
      } else {
        state = state.error(result.message ?? 'Failed to setup master password');
      }
    } catch (e) {
      state = state.error('An unexpected error occurred');
    }
  }

  /// Logs in with master password
  Future<void> login(String password) async {
    state = state.loading();

    try {
      final request = LoginRequest(password: password);
      final result = await _authRepository.login(request);

      if (result.success) {
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
    state = state.copyWith(isAuthenticated: false, successMessage: 'Logged out successfully');
  }

  /// Resets authentication (clears all data)
  Future<void> resetAuth() async {
    state = state.loading();

    try {
      final result = await _authRepository.resetAuth();

      if (result.success) {
        state = const AuthState().success(message: result.message);
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
