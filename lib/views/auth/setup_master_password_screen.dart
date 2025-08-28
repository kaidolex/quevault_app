import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';

class SetupMasterPasswordScreen extends StatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() => _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
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
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 8) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
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

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Save master password securely
      // For now, just show a success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Master password has been set successfully!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
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
                        Icon(Icons.security, size: AppSpacing.xxxl, color: Theme.of(context).colorScheme.primary),
                        AppSpacing.verticalSpacingLG,
                        Text(
                          'Setup Master Password',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalSpacingSM,
                        Text(
                          'Create a strong master password to protect your vault. This password will be used to encrypt and decrypt all your stored data.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    AppSpacing.verticalSpacingXXL,

                    // Form Section - Using ShadCard
                    ShadCard(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
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
                                    backgroundColor: Colors.grey.withOpacity(0.3),
                                    valueColor: AlwaysStoppedAnimation<Color>(_getStrengthColor(_getPasswordStrength(_passwordController.text))),
                                  ),
                                ],
                              ),
                            ],

                            AppSpacing.verticalSpacingLG,

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

                            AppSpacing.verticalSpacingXL,

                            // Submit Button - Using ShadButton
                            ShadButton(onPressed: _handleSubmit, child: const Text('Create Master Password')),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalSpacingLG,

                    // Security Tips Card - Using ShadCard
                    ShadCard(
                      child: Padding(
                        padding: AppSpacing.paddingLG,
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
                            AppSpacing.verticalSpacingMD,
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
    );
  }
}

enum PasswordStrength { none, weak, medium, strong }
