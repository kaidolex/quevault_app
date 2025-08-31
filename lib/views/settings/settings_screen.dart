import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/viewmodels/theme_viewmodel.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/widgets/base_scaffold.dart';
import 'package:quevault_app/debug/encryption_test.dart';
import 'package:quevault_app/debug/comprehensive_encryption_test.dart';
import 'package:quevault_app/debug/manual_encryption_test.dart';

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
        children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Testing basic encryption functionality...')],
      ),
    ),
  );

  try {
    // Run quick encryption test
    await ManualEncryptionTest.runQuickTest();

    // Close loading dialog
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Quick encryption test completed! Check debug console for results.'), backgroundColor: Colors.green));
  } catch (e) {
    // Close loading dialog
    Navigator.of(context).pop();

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Quick encryption test failed: $e'), backgroundColor: Colors.red));
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
        children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Running full encryption test suite...')],
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
      const SnackBar(
        content: Text('Comprehensive encryption tests completed! Check debug console for detailed results.'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // Close loading dialog
    Navigator.of(context).pop();

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comprehensive encryption test failed: $e'), backgroundColor: Colors.red));
  }
}
