import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared storage configuration for all services
/// This ensures all services use the same storage backend and configuration
class StorageConfig {
  static const FlutterSecureStorage secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'quevault_secure_prefs'),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
}
