import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/credential.dart';
import '../models/vault.dart';
import '../services/credential_service.dart';
import '../services/vault_service.dart';

/// Credentials state
@immutable
class CredentialsState {
  final bool isLoading;
  final List<Credential> allCredentials; // All credentials from all vaults
  final List<Credential> filteredCredentials; // Currently displayed credentials (filtered or all)
  final List<Vault> availableVaults;
  final String searchQuery; // Current search query
  final String? errorMessage;

  const CredentialsState({
    this.isLoading = false,
    this.allCredentials = const [],
    this.filteredCredentials = const [],
    this.availableVaults = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  CredentialsState copyWith({
    bool? isLoading,
    List<Credential>? allCredentials,
    List<Credential>? filteredCredentials,
    List<Vault>? availableVaults,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CredentialsState(
      isLoading: isLoading ?? this.isLoading,
      allCredentials: allCredentials ?? this.allCredentials,
      filteredCredentials: filteredCredentials ?? this.filteredCredentials,
      availableVaults: availableVaults ?? this.availableVaults,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  /// Creates a loading state
  CredentialsState loading() {
    return copyWith(isLoading: true, errorMessage: null);
  }

  /// Creates an error state
  CredentialsState error(String message) {
    return copyWith(isLoading: false, errorMessage: message);
  }

  /// Creates a success state
  CredentialsState success({required List<Credential> allCredentials, required List<Vault> availableVaults}) {
    return copyWith(
      isLoading: false,
      allCredentials: allCredentials,
      filteredCredentials: allCredentials, // Initially show all credentials
      availableVaults: availableVaults,
      errorMessage: null,
    );
  }
}

/// Credentials view model
class CredentialsViewModel extends StateNotifier<CredentialsState> {
  final CredentialService _credentialService;
  final VaultService _vaultService;

  CredentialsViewModel({CredentialService? credentialService, VaultService? vaultService})
    : _credentialService = credentialService ?? CredentialService.instance,
      _vaultService = vaultService ?? VaultService.instance,
      super(const CredentialsState());

  /// Loads all credentials from main vault and visible vaults that don't need unlock
  Future<void> loadCredentials() async {
    state = state.loading();

    try {
      // Get all vaults
      final allVaults = await _vaultService.getAllVaults();

      // Filter vaults: include main vault and unlocked vaults
      final availableVaults = allVaults.where((vault) {
        // Always include main vault
        if (vault.name == 'Main Vault') return true;
        // Exclude hidden vaults
        if (vault.isHidden) return false;
        // Exclude vaults that need unlock (for now, until we implement proper unlocking)
        if (vault.needsUnlock) return false;
        // Include all other visible vaults that don't need unlock
        return true;
      }).toList();

      if (kDebugMode) {
        print('CredentialsViewModel: Found ${allVaults.length} total vaults');
        print(
          'CredentialsViewModel: Available vaults: ${availableVaults.map((v) => '${v.name} (hidden: ${v.isHidden}, needsUnlock: ${v.needsUnlock})').join(', ')}',
        );
      }

      // Get credentials from available vaults
      final List<Credential> allCredentials = [];
      for (final vault in availableVaults) {
        try {
          final vaultCredentials = await _credentialService.getCredentialsByVaultId(vault.id);
          allCredentials.addAll(vaultCredentials);
        } catch (e) {
          if (kDebugMode) {
            print('Error loading credentials for vault ${vault.name}: $e');
          }
          // Continue loading other vaults even if one fails
        }
      }

      // Sort credentials by name
      allCredentials.sort((a, b) => a.name.compareTo(b.name));

      state = state.success(allCredentials: allCredentials, availableVaults: availableVaults);
    } catch (e) {
      if (kDebugMode) {
        print('CredentialsViewModel: Error loading credentials: $e');
      }
      state = state.error('Failed to load credentials');
    }
  }

  /// Refreshes the credentials list
  Future<void> refresh() async {
    await loadCredentials();
  }

  /// Searches credentials locally without making database calls
  void searchCredentials(String query) {
    if (query.isEmpty) {
      // Show all credentials when search is empty
      state = state.copyWith(searchQuery: '', filteredCredentials: state.allCredentials, errorMessage: null);
      return;
    }

    // Filter credentials locally
    final searchResults = state.allCredentials.where((credential) {
      final searchLower = query.toLowerCase();
      return credential.name.toLowerCase().contains(searchLower) ||
          credential.username.toLowerCase().contains(searchLower) ||
          (credential.website?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    if (kDebugMode) {
      print(
        'CredentialsViewModel: Local search for "$query" found ${searchResults.length} results from ${state.allCredentials.length} total credentials',
      );
    }

    state = state.copyWith(searchQuery: query, filteredCredentials: searchResults, errorMessage: null);
  }

  /// Deletes a credential
  Future<void> deleteCredential(String credentialId) async {
    try {
      await _credentialService.deleteCredential(credentialId);
      // Refresh the list after deletion
      await loadCredentials();
    } catch (e) {
      if (kDebugMode) {
        print('CredentialsViewModel: Error deleting credential: $e');
      }
      state = state.error('Failed to delete credential');
    }
  }

  /// Gets vault name by vault ID
  String getVaultName(String vaultId) {
    final vault = state.availableVaults.firstWhere(
      (v) => v.id == vaultId,
      orElse: () => Vault(
        id: vaultId,
        name: 'Unknown Vault',
        description: '',
        color: Colors.grey.value,
        isHidden: false,
        needsUnlock: false,
        useMasterKey: true,
        useDifferentUnlockKey: false,
        useFingerprint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return vault.name;
  }

  /// Gets vault color by vault ID
  int getVaultColor(String vaultId) {
    final vault = state.availableVaults.firstWhere(
      (v) => v.id == vaultId,
      orElse: () => Vault(
        id: vaultId,
        name: 'Unknown Vault',
        description: '',
        color: Colors.grey.value,
        isHidden: false,
        needsUnlock: false,
        useMasterKey: true,
        useDifferentUnlockKey: false,
        useFingerprint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return vault.color;
  }

  /// Gets vault information for debugging
  String getVaultInfo(String vaultId) {
    final vault = state.availableVaults.firstWhere(
      (v) => v.id == vaultId,
      orElse: () => Vault(
        id: vaultId,
        name: 'Unknown Vault',
        description: '',
        color: Colors.grey.value,
        isHidden: false,
        needsUnlock: false,
        useMasterKey: true,
        useDifferentUnlockKey: false,
        useFingerprint: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return '${vault.name} (hidden: ${vault.isHidden}, needsUnlock: ${vault.needsUnlock})';
  }
}

/// Provider for credentials view model
final credentialsViewModelProvider = StateNotifierProvider<CredentialsViewModel, CredentialsState>((ref) {
  return CredentialsViewModel();
});
