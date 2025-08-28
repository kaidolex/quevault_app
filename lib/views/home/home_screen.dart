import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/views/auth/onboarding_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QueVault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authViewModelProvider.notifier).logout();
              // Navigation will be handled automatically by AppRouter
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingLG,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              AppSpacing.verticalSpacingLG,
              Text(
                'Welcome to QueVault!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingMD,
              Text(
                'Your vault is successfully unlocked and ready to use. This is where your password management features will be implemented.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpacingLG,
              ShadButton(
                onPressed: () {
                  // TODO: Navigate to password list or main features
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password management features coming soon!')));
                },
                child: const Text('Explore Vault'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
