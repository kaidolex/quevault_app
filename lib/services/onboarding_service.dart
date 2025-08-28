import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for managing onboarding state
class OnboardingService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Checks if the user has completed onboarding
  Future<bool> isOnboardingComplete() async {
    try {
      final isComplete = await _storage.read(key: _onboardingCompleteKey);
      return isComplete == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error checking onboarding state: $e');
      }
      return false;
    }
  }

  /// Marks onboarding as complete
  Future<bool> completeOnboarding() async {
    try {
      await _storage.write(key: _onboardingCompleteKey, value: 'true');
      if (kDebugMode) {
        print('OnboardingService: Onboarding marked as complete');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error marking onboarding complete: $e');
      }
      return false;
    }
  }

  /// Resets onboarding state (for testing/debugging)
  Future<bool> resetOnboarding() async {
    try {
      await _storage.delete(key: _onboardingCompleteKey);
      if (kDebugMode) {
        print('OnboardingService: Onboarding state reset');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('OnboardingService: Error resetting onboarding: $e');
      }
      return false;
    }
  }
}
