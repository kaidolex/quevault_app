import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/models/auth_models.dart';
import 'package:quevault_app/debug/storage_debug.dart';

class SetupMasterPasswordScreen extends ConsumerStatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  ConsumerState<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends ConsumerState<SetupMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  PasswordStrength _getPasswordStrength(String password) {
    return ref.read(authViewModelProvider.notifier).getPasswordStrength(password);
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  double _getStrengthProgress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.medium:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Use the ViewModel to setup master password
      await ref.read(authViewModelProvider.notifier).setupMasterPassword(_passwordController.text, _confirmPasswordController.text);
    } else {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fix the errors in the form'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Listen to state changes for showing snackbars
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      } else if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green));
        // Navigation will be handled automatically by AppRouter
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: Theme.of(context).colorScheme.background,
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingMD,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      Column(
                        children: [
                          Icon(Icons.security, size: AppSpacing.xxl, color: Theme.of(context).colorScheme.primary),
                          AppSpacing.verticalSpacingMD,
                          Text(
                            'Setup Master Password',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          AppSpacing.verticalSpacingXS,
                          Text(
                            'Create a strong master password to protect your vault. This password will be used to encrypt and decrypt all your stored data.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                      AppSpacing.verticalSpacingLG,

                      // Form Section - Using ShadCard
                      ShadCard(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Master Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Master Password',
                                  hintText: 'Enter your master password',
                                  prefixIcon: const Icon(Icons.key),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Master password is required';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters long';
                                  }
                                  final strength = _getPasswordStrength(value);
                                  if (strength == PasswordStrength.weak) {
                                    return 'Please choose a stronger password';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),

                              // Password Strength Indicator
                              if (_passwordController.text.isNotEmpty) ...[
                                AppSpacing.verticalSpacingMD,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Password Strength', style: Theme.of(context).textTheme.bodySmall),
                                        Text(
                                          _getStrengthText(_getPasswordStrength(_passwordController.text)),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: _getStrengthColor(_getPasswordStrength(_passwordController.text)),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    AppSpacing.verticalSpacingXS,
                                    LinearProgressIndicator(
                                      value: _getStrengthProgress(_getPasswordStrength(_passwordController.text)),
                                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(_getPasswordStrength(_passwordController.text))),
                                    ),
                                  ],
                                ),
                              ],

                              AppSpacing.verticalSpacingMD,

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Master Password',
                                  hintText: 'Re-enter your master password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),

                              AppSpacing.verticalSpacingLG,

                              // Submit Button - Using ShadButton
                              ShadButton(
                                onPressed: authState.isLoading ? null : _handleSubmit,
                                child: authState.isLoading
                                    ? const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                          SizedBox(width: 8),
                                          Text('Creating...'),
                                        ],
                                      )
                                    : const Text('Create Master Password'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      AppSpacing.verticalSpacingMD,

                      // Debug section (only in debug mode)
                      if (kDebugMode) ...[
                        ShadCard(
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: AppSpacing.paddingMD,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Debug Tools',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                                ),
                                AppSpacing.verticalSpacingSM,
                                Row(
                                  children: [
                                    Expanded(
                                      child: ShadButton(
                                        onPressed: () async {
                                          await StorageDebug.testStorageSetup();
                                        },
                                        child: const Text('Test Storage'),
                                      ),
                                    ),
                                    AppSpacing.horizontalSpacingSM,
                                    Expanded(
                                      child: ShadButton(
                                        onPressed: () async {
                                          await StorageDebug.clearAllData();
                                          await ref.read(authViewModelProvider.notifier).resetOnboarding();
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debug: All data cleared')));
                                        },
                                        child: const Text('Reset App'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppSpacing.verticalSpacingMD,
                      ],

                      // Security Tips Card - Using ShadCard
                      ShadCard(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: AppSpacing.paddingMD,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb, size: 20),
                                  AppSpacing.horizontalSpacingSM,
                                  Text('Security Tips', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              AppSpacing.verticalSpacingSM,
                              ...[
                                'Use at least 12 characters for better security',
                                'Include uppercase and lowercase letters',
                                'Add numbers and special characters',
                                'Avoid common words or personal information',
                                'Consider using a passphrase with spaces',
                              ].map(
                                (tip) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodySmall)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
