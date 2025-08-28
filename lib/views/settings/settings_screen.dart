import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/viewmodels/theme_viewmodel.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.read(themeViewModelProvider.notifier);
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Setting
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(themeNotifier.isDarkMode ? Icons.dark_mode : Icons.light_mode, size: 28, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dark Mode', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Toggle between light and dark themes',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(value: themeNotifier.isDarkMode, onChanged: (_) => themeNotifier.toggleTheme()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Biometric Authentication Setting
            if (authState.isBiometricAvailable)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint, size: 28, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${authState.biometricType} Unlock',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unlock your vault with ${authState.biometricType.toLowerCase()}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: authState.isBiometricEnabled,
                        onChanged: authState.isLoading ? null : (value) => _handleBiometricToggle(context, ref, value),
                      ),
                    ],
                  ),
                ),
              ),

            if (authState.isBiometricAvailable) const SizedBox(height: 32),

            // Current status
            Center(
              child: Column(
                children: [
                  Text(
                    'Current theme: ${themeNotifier.currentThemeName}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontStyle: FontStyle.italic),
                  ),
                  if (authState.isBiometricAvailable) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${authState.biometricType}: ${authState.isBiometricEnabled ? "Enabled" : "Disabled"}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontStyle: FontStyle.italic),
                    ),
                  ],
                  // Debug button (only in debug mode)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        themeNotifier.debugThemeState();
                        ref.read(authViewModelProvider.notifier).debugBiometricState();
                      },
                      child: const Text('Debug Storage'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBiometricToggle(BuildContext context, WidgetRef ref, bool enable) async {
    final authNotifier = ref.read(authViewModelProvider.notifier);

    if (enable) {
      // Show password dialog to enable biometric
      _showMasterPasswordDialog(context, (password) async {
        await authNotifier.enableBiometric(password);
        _showResultMessage(context, ref);
      });
    } else {
      // Disable biometric
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
}
