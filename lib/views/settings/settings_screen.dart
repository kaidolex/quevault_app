import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/viewmodels/theme_viewmodel.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/viewmodels/credentials_viewmodel.dart';
import 'package:quevault_app/viewmodels/hidden_vault_viewmodel.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/debug/encryption_test.dart';
import 'package:quevault_app/debug/comprehensive_encryption_test.dart';
import 'package:quevault_app/debug/manual_encryption_test.dart';
import 'package:quevault_app/services/export_service.dart' as import_export;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    return BaseScaffold(
      title: 'Settings',
      automaticallyImplyLeading: true,
      body: ListView(
        children: [
          // Dark Mode Setting
          ListTile(
            leading: Icon(themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Theme.of(context).colorScheme.primary),
            title: const Text('Dark Mode'),
            trailing: Switch(value: themeNotifier.isDarkMode, onChanged: (_) => themeNotifier.toggleTheme()),
          ),

          // Biometric Authentication Setting
          if (authState.isBiometricAvailable) ...[
            const Divider(),
            ListTile(
              leading: Icon(Icons.fingerprint, color: Theme.of(context).colorScheme.primary),
              title: Text('${authState.biometricType} Unlock'),
              trailing: Switch(
                value: authState.isBiometricEnabled,
                onChanged: authState.isLoading ? null : (value) => _handleBiometricToggle(context, ref, value),
              ),
            ),
          ],

          // Export section
          const Divider(),
          ListTile(
            leading: Icon(Icons.file_download, color: Theme.of(context).colorScheme.primary),
            title: const Text('Export'),
            subtitle: const Text('Export vaults and credentials to JSON'),
            onTap: () => _handleExport(context),
          ),
          ListTile(
            leading: Icon(Icons.file_upload, color: Theme.of(context).colorScheme.primary),
            title: const Text('Import'),
            subtitle: const Text('Import vaults and credentials from JSON'),
            onTap: () => _handleImport(context, ref),
          ),

          // Debug section (only in debug mode)
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Storage'),
              onTap: () {
                themeNotifier.debugThemeState();
                ref.read(authViewModelProvider.notifier).debugBiometricState();
              },
            ),
            ListTile(leading: const Icon(Icons.security), title: const Text('Test Encryption'), onTap: () => _runEncryptionTests(context)),
            ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('Comprehensive Encryption Test'),
              onTap: () => _runComprehensiveEncryptionTests(context),
            ),
            ListTile(leading: const Icon(Icons.speed), title: const Text('Quick Encryption Test'), onTap: () => _runQuickEncryptionTest(context)),
          ],
        ],
      ),
    );
  }

  void _handleBiometricToggle(BuildContext context, WidgetRef ref, bool enable) async {
    final authNotifier = ref.read(authViewModelProvider.notifier);

    if (enable) {
      _showMasterPasswordDialog(context, (password) async {
        await authNotifier.enableBiometric(password);
        _showResultMessage(context, ref);
      });
    } else {
      await authNotifier.disableBiometric();
      _showResultMessage(context, ref);
    }
  }

  void _showMasterPasswordDialog(BuildContext context, Function(String) onConfirm) {
    final passwordController = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enter Master Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your master password to enable biometric authentication.'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: 'Master Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscureText = !obscureText),
                  ),
                ),
                onSubmitted: (_) => _confirmPassword(context, passwordController.text, onConfirm),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => _confirmPassword(context, passwordController.text, onConfirm), child: const Text('Confirm')),
          ],
        ),
      ),
    );
  }

  void _confirmPassword(BuildContext context, String password, Function(String) onConfirm) {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your master password')));
      return;
    }
    Navigator.of(context).pop();
    onConfirm(password);
  }

  void _showResultMessage(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authViewModelProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authState.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error));
      } else if (authState.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authState.successMessage!), backgroundColor: Colors.green));
      }

      // Clear messages
      ref.read(authViewModelProvider.notifier).clearMessages();
    });
  }

  void _runEncryptionTests(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Encryption Tests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Testing encryption and decryption...')],
        ),
      ),
    );

    try {
      // Run basic encryption tests
      await EncryptionTest.runEncryptionTest();

      // Run encryption key service tests
      await EncryptionTest.runEncryptionKeyServiceTest();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Encryption tests completed! Check debug console for results.'), backgroundColor: Colors.green));
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Encryption test failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _runComprehensiveEncryptionTests(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Comprehensive Encryption Tests'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Running comprehensive encryption tests...')],
        ),
      ),
    );

    try {
      // Run comprehensive encryption tests
      await ComprehensiveEncryptionTest.runAllTests();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprehensive encryption tests completed! Check debug console for results.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comprehensive encryption test failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _runQuickEncryptionTest(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Running Quick Encryption Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Running quick encryption test...')],
        ),
      ),
    );

    try {
      // Run quick encryption test
      await ManualEncryptionTest.runQuickTest();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick encryption test completed! Check debug console for results.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quick encryption test failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _handleExport(BuildContext context) async {
    // Show confirmation dialog
    final shouldExport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will export all your vaults and credentials to a JSON file. '
              'The data will be decrypted and saved in plain text. '
              'Make sure to save it in a secure location.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The exported file will contain decrypted passwords in plain text.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );

    if (shouldExport != true) return;

    // Show master password dialog
    final passwordController = TextEditingController();
    bool obscureText = true;
    String? masterPassword;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Enter Master Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please enter your master password to export your data.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () => setState(() => obscureText = !obscureText),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (passwordController.text.isNotEmpty) {
                        masterPassword = passwordController.text;
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This password is required to verify your identity before exporting sensitive data.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  masterPassword = passwordController.text;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Please enter your master password'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (masterPassword == null) return; // User cancelled password entry

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            const Text('Exporting Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Preparing export...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gathering vaults and credentials...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Get export stats first
      final stats = await import_export.ImportExportService.instance.getExportStats();

      // Perform the export
      final outputPath = await import_export.ImportExportService.instance.exportToJson();

      // Close loading dialog
      Navigator.of(context).pop();

      if (outputPath != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Export completed successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${stats['vaults']} vaults and ${stats['credentials']} credentials exported to:', style: const TextStyle(fontSize: 12)),
                Text(
                  outputPath.split(Platform.pathSeparator).last,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        // User cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Export cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Export failed: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleImport(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will import vaults and credentials from a JSON file. '
              'The main vault will not be imported, but its credentials will be added to your existing main vault. '
              'All imported items will be created with new IDs.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only vault name, description, isHidden, createdAt, updatedAt, and credentials will be imported.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (shouldImport != true) return;

    // Show master password dialog
    final passwordController = TextEditingController();
    bool obscureText = true;
    String? masterPassword;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Enter Master Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Please enter your master password to import data.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: passwordController,
                    obscureText: obscureText,
                    decoration: InputDecoration(
                      labelText: 'Master Password',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      suffixIcon: IconButton(
                        icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        onPressed: () => setState(() => obscureText = !obscureText),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (passwordController.text.isNotEmpty) {
                        masterPassword = passwordController.text;
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This password is required to verify your identity before importing data.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  masterPassword = passwordController.text;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Please enter your master password'), backgroundColor: Theme.of(context).colorScheme.error),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    if (masterPassword == null) return; // User cancelled password entry

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(width: 12),
            const Text('Importing Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Processing import file...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(Icons.file_upload_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reading and validating import data...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Perform the import
      final importStats = await import_export.ImportExportService.instance.importFromJson();

      // Close loading dialog
      Navigator.of(context).pop();

      if (importStats != null) {
        // Refresh the credentials and vaults data
        ref.read(credentialsViewModelProvider.notifier).loadCredentials();

        // Trigger app drawer refresh
        ref.read(hiddenVaultViewModelProvider.notifier).triggerRefresh();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Import completed successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${importStats['vaults']} vaults and ${importStats['credentials']} credentials imported.', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 2),
                Text('Data refreshed automatically.', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else {
        // User cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('Import cancelled'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Import failed: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
