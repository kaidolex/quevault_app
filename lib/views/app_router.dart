import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'auth/onboarding_screen.dart';
import 'auth/setup_master_password_screen.dart';
import 'auth/login_screen.dart';
import 'auth/home_screen.dart';

/// Main app router that determines which screen to show based on app state
class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);

    // Show loading screen while determining initial state
    if (authState.isLoading) {
      return const LoadingScreen();
    }

    // Navigation logic based on state
    if (!authState.isOnboardingComplete) {
      // User hasn't completed onboarding yet
      return const OnboardingScreen();
    } else if (!authState.isMasterPasswordSetup) {
      // Onboarding complete but no master password set
      return const SetupMasterPasswordScreen();
    } else if (!authState.isAuthenticated) {
      // Master password exists but user not authenticated
      return const LoginScreen();
    } else {
      // Fully authenticated - show main app
      return const HomeScreen();
    }
  }
}

/// Loading screen shown while determining app state
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(Icons.security_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),

            // App name
            Text(
              'QueVault',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Secure Password Manager',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 16),

            // Loading text
            Text(
              'Initializing...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
