import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Refresh biometric status when login screen is displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).refreshBiometricStatus();
      // Debug: Print biometric state
      ref.read(authViewModelProvider.notifier).debugBiometricState();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authViewModelProvider.notifier).login(_passwordController.text);
    }
  }

  Future<void> _handleBiometricLogin() async {
    await ref.read(authViewModelProvider.notifier).loginWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Listen to state changes for messages
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
                        Icon(Icons.lock_rounded, size: AppSpacing.xxl, color: Theme.of(context).colorScheme.primary),
                        AppSpacing.verticalSpacingMD,
                        Text(
                          'Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.verticalSpacingXS,
                        Text(
                          'Enter your master password to access your vault',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    AppSpacing.verticalSpacingLG,

                    // Login Form Card
                    ShadCard(
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
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            AppSpacing.verticalSpacingLG,

                            // Login Button
                            ShadButton(
                              onPressed: authState.isLoading ? null : _handleLogin,
                              child: authState.isLoading
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                        SizedBox(width: 8),
                                        Text('Unlocking...'),
                                      ],
                                    )
                                  : const Text('Unlock Vault'),
                            ),

                            // Biometric Login Button
                            if (authState.isBiometricAvailable && authState.isBiometricEnabled) ...[
                              AppSpacing.verticalSpacingMD,
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[300])),
                                ],
                              ),
                              AppSpacing.verticalSpacingMD,
                              ShadButton.outline(
                                onPressed: authState.isLoading ? null : _handleBiometricLogin,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fingerprint, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Unlock with ${authState.biometricType}'),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalSpacingMD,

                    // Security Info Card
                    ShadCard(
                      child: Padding(
                        padding: AppSpacing.paddingMD,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20),
                                AppSpacing.horizontalSpacingSM,
                                Text('Security Notice', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            AppSpacing.verticalSpacingSM,
                            Text(
                              'Your master password is never saved in plain text on this device. Only a cryptographic hash is stored for verification. When you enter your password, it unlocks your encrypted vault locally on your device, ensuring your data remains private and secure.',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.left,
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
