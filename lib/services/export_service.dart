import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/credential.dart';
import '../models/vault.dart';
import 'vault_service.dart';
import 'credential_service.dart';

class ImportExportService {
  static final ImportExportService instance = ImportExportService._internal();
  ImportExportService._internal();

  /// Exports all vaults and their credentials to JSON format
  /// Returns the path where the file was saved, or null if cancelled/failed
  Future<String?> exportToJson() async {
    try {
      // Get all vaults and credentials
      final vaults = await VaultService.instance.getAllVaults();
      final allCredentials = await CredentialService.instance.getAllCredentials();

      // Group credentials by vault
      final Map<String, List<Credential>> credentialsByVault = {};
      for (final credential in allCredentials) {
        credentialsByVault.putIfAbsent(credential.vaultId, () => []).add(credential);
      }

      // Prepare export data
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'vaults': vaults.map((vault) {
          return {
            'id': vault.id,
            'name': vault.name,
            'description': vault.description,
            'color': vault.color,
            'isHidden': vault.isHidden,
            'needsUnlock': vault.needsUnlock,
            'useMasterKey': vault.useMasterKey,
            'useDifferentUnlockKey': vault.useDifferentUnlockKey,
            'unlockKey': vault.unlockKey,
            'useFingerprint': vault.useFingerprint,
            'createdAt': vault.createdAt.toIso8601String(),
            'updatedAt': vault.updatedAt.toIso8601String(),
            'credentials':
                credentialsByVault[vault.id]?.map((credential) {
                  return {
                    'id': credential.id,
                    'name': credential.name,
                    'username': credential.username,
                    'password': credential.password, // Already decrypted by CredentialService
                    'website': credential.website,
                    'notes': credential.notes,
                    'customFields': credential.customFields.map((field) => {'id': field.id, 'name': field.name, 'value': field.value}).toList(),
                    'createdAt': credential.createdAt.toIso8601String(),
                    'updatedAt': credential.updatedAt.toIso8601String(),
                  };
                }).toList() ??
                [],
          };
        }).toList(),
      };

      // Convert to JSON with pretty formatting
      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);

      // Convert JSON string to bytes for mobile platforms
      final jsonBytes = utf8.encode(jsonString);

      // Let user choose where to save the file
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save QueVault Export',
        fileName: 'quevault_export_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: jsonBytes, // Required for Android & iOS
      );

      if (outputFile == null) {
        // User cancelled
        return null;
      }

      // On desktop platforms, we need to write the file ourselves
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final file = File(outputFile);
        await file.writeAsString(jsonString);
      }
      // On mobile platforms, FilePicker handles the file writing automatically

      if (kDebugMode) {
        print('ImportExportService: Successfully exported ${vaults.length} vaults with ${allCredentials.length} credentials to $outputFile');
      }

      return outputFile;
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error during export: $e');
      }
      rethrow;
    }
  }

  /// Imports vaults and credentials from JSON format
  /// Returns import statistics, or null if cancelled/failed
  Future<Map<String, int>?> importFromJson() async {
    try {
      // Let user choose the file to import
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select QueVault Export File',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled
        return null;
      }

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        throw Exception('Selected file does not exist');
      }

      // Read and parse the JSON file
      final jsonString = await file.readAsString();
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      // Validate the import data structure
      if (!importData.containsKey('vaults') || !(importData['vaults'] is List)) {
        throw Exception('Invalid import file format: missing or invalid vaults data');
      }

      final List<dynamic> vaultsData = importData['vaults'];
      int importedVaults = 0;
      int importedCredentials = 0;

      // Get the main vault (we'll import credentials to it)
      final mainVault = await _getMainVault();
      if (mainVault == null) {
        throw Exception('Main vault not found. Please ensure you have set up your vault first.');
      }

      // Process each vault in the import data
      for (final vaultData in vaultsData) {
        if (vaultData is! Map<String, dynamic>) {
          continue; // Skip invalid vault data
        }

        // Skip the main vault - we don't import it
        if (vaultData['name'] == 'Main Vault' || vaultData['name'] == mainVault.name) {
          // Import credentials from main vault to the existing main vault
          final credentials = vaultData['credentials'] as List<dynamic>? ?? [];
          for (final credentialData in credentials) {
            if (credentialData is Map<String, dynamic>) {
              await _importCredential(credentialData, mainVault.id);
              importedCredentials++;
            }
          }
          continue;
        }

        // Import non-main vaults
        final importedVault = await _importVault(vaultData);
        if (importedVault != null) {
          importedVaults++;

          // Import credentials for this vault
          final credentials = vaultData['credentials'] as List<dynamic>? ?? [];
          for (final credentialData in credentials) {
            if (credentialData is Map<String, dynamic>) {
              await _importCredential(credentialData, importedVault.id);
              importedCredentials++;
            }
          }
        }
      }

      if (kDebugMode) {
        print('ImportExportService: Successfully imported $importedVaults vaults and $importedCredentials credentials');
      }

      return {'vaults': importedVaults, 'credentials': importedCredentials};
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error during import: $e');
      }
      rethrow;
    }
  }

  /// Gets the main vault
  Future<Vault?> _getMainVault() async {
    final vaults = await VaultService.instance.getAllVaults();
    return vaults.isNotEmpty ? vaults.first : null;
  }

  /// Imports a single vault
  Future<Vault?> _importVault(Map<String, dynamic> vaultData) async {
    try {
      // Extract only the required fields for vault import
      final name = vaultData['name'] as String?;
      final description = vaultData['description'] as String?;
      final isHidden = vaultData['isHidden'] as bool? ?? false;
      final createdAt = _parseDateTime(vaultData['createdAt']);
      final updatedAt = _parseDateTime(vaultData['updatedAt']);

      if (name == null || description == null || createdAt == null || updatedAt == null) {
        if (kDebugMode) {
          print('ImportExportService: Skipping vault with missing required fields');
        }
        return null;
      }

      // Create new vault with generated ID
      final newVault = Vault(
        id: 'vault_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        description: description,
        color: vaultData['color'] as int? ?? 4280391411, // Default color
        isHidden: isHidden,
        needsUnlock: false, // Default values for imported vaults
        useMasterKey: true,
        useDifferentUnlockKey: false,
        unlockKey: null,
        useFingerprint: false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      await VaultService.instance.createVault(newVault);
      return newVault;
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error importing vault: $e');
      }
      return null;
    }
  }

  /// Imports a single credential
  Future<void> _importCredential(Map<String, dynamic> credentialData, String vaultId) async {
    try {
      // Extract credential fields
      final name = credentialData['name'] as String?;
      final username = credentialData['username'] as String?;
      final password = credentialData['password'] as String?;
      final website = credentialData['website'] as String?;
      final notes = credentialData['notes'] as String?;
      final createdAt = _parseDateTime(credentialData['createdAt']);
      final updatedAt = _parseDateTime(credentialData['updatedAt']);

      if (name == null || username == null || password == null || createdAt == null || updatedAt == null) {
        if (kDebugMode) {
          print('ImportExportService: Skipping credential with missing required fields');
        }
        return;
      }

      // Parse custom fields
      final customFieldsData = credentialData['customFields'] as List<dynamic>? ?? [];
      final customFields = customFieldsData
          .map((fieldData) {
            if (fieldData is Map<String, dynamic>) {
              return CustomField(
                id: 'field_${DateTime.now().millisecondsSinceEpoch}_${fieldData.hashCode}',
                name: fieldData['name'] as String? ?? '',
                value: fieldData['value'] as String? ?? '',
              );
            }
            return null;
          })
          .whereType<CustomField>()
          .toList();

      // Create new credential with generated ID
      final newCredential = Credential(
        id: 'credential_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        vaultId: vaultId,
        username: username,
        password: password,
        website: website,
        notes: notes,
        customFields: customFields,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      await CredentialService.instance.createCredential(newCredential);
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error importing credential: $e');
      }
    }
  }

  /// Parses DateTime from string
  DateTime? _parseDateTime(dynamic dateTimeData) {
    if (dateTimeData == null) return null;

    try {
      if (dateTimeData is String) {
        return DateTime.parse(dateTimeData);
      } else if (dateTimeData is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateTimeData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error parsing date: $e');
      }
    }
    return null;
  }

  /// Gets export statistics for display
  Future<Map<String, int>> getExportStats() async {
    try {
      final vaults = await VaultService.instance.getAllVaults();
      final credentials = await CredentialService.instance.getAllCredentials();

      return {'vaults': vaults.length, 'credentials': credentials.length};
    } catch (e) {
      if (kDebugMode) {
        print('ImportExportService: Error getting export stats: $e');
      }
      return {'vaults': 0, 'credentials': 0};
    }
  }
}
