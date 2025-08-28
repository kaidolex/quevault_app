import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:quevault_app/core/constants/app_spacing.dart';
import 'package:quevault_app/viewmodels/auth_viewmodel.dart';
import 'package:quevault_app/views/auth/setup_master_password_screen.dart';
import 'package:quevault_app/views/auth/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final introKey = GlobalKey<IntroductionScreenState>();

  @override
  void initState() {
    super.initState();
    // Check if we should show onboarding or navigate directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = ref.read(authViewModelProvider);
    if (!authState.isLoading) {
      if (authState.isMasterPasswordSetup) {
        // Master password is already setup, go to login
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
      // If master password is not setup, stay on onboarding
    }
  }

  void _onIntroEnd(context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const SetupMasterPasswordScreen()));
  }

  Widget _buildPage({required String title, required String body, required IconData icon, required Color iconColor}) {
    return Container(
      padding: AppSpacing.paddingLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: AppSpacing.borderRadiusXL),
            child: Icon(icon, size: 60, color: iconColor),
          ),

          AppSpacing.verticalSpacingXXL,

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),

          AppSpacing.verticalSpacingLG,

          // Body text
          Padding(
            padding: AppSpacing.paddingHorizontalMD,
            child: Text(
              body,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Show loading if auth state is still being determined
    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return IntroductionScreen(
      key: introKey,
      globalBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
      allowImplicitScrolling: true,
      autoScrollDuration: null, // Disable auto scroll
      infiniteAutoScroll: false,

      pages: [
        PageViewModel(
          titleWidget: Container(), // Empty container since we're using custom layout
          bodyWidget: _buildPage(
            title: "Welcome to QueVault",
            body: "Your secure, personal password manager that keeps all your credentials safe and organized in one place.",
            icon: Icons.security_rounded,
            iconColor: Colors.blue,
          ),
        ),

        PageViewModel(
          titleWidget: Container(),
          bodyWidget: _buildPage(
            title: "Military-Grade Encryption",
            body: "Your passwords are protected with AES-256 encryption, the same standard used by banks and governments worldwide.",
            icon: Icons.lock_rounded,
            iconColor: Colors.green,
          ),
        ),

        PageViewModel(
          titleWidget: Container(),
          bodyWidget: _buildPage(
            title: "Generate Strong Passwords",
            body: "Create unique, complex passwords for all your accounts with our built-in password generator.",
            icon: Icons.vpn_key_rounded,
            iconColor: Colors.orange,
          ),
        ),

        PageViewModel(
          titleWidget: Container(),
          bodyWidget: _buildPage(
            title: "Offline & Private",
            body: "Your data stays on your device. No cloud storage, no tracking, no data collection. Complete privacy guaranteed.",
            icon: Icons.phone_android_rounded,
            iconColor: Colors.purple,
          ),
        ),

        PageViewModel(
          titleWidget: Container(),
          bodyWidget: _buildPage(
            title: "Master Password",
            body: "One password to rule them all. Your master password is the only key you'll need to remember.",
            icon: Icons.key_rounded,
            iconColor: Colors.red,
          ),
        ),
      ],

      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),

      showSkipButton: true,
      showBackButton: true,
      showDoneButton: true,
      showNextButton: true,

      skipOrBackFlex: 0,
      nextFlex: 0,

      back: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
      skip: Text(
        'Skip',
        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
      ),
      next: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary),
      done: Text(
        'Get Started',
        style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
      ),

      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: AppSpacing.paddingMD,
      controlsPadding: const EdgeInsets.all(12.0),

      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: Theme.of(context).colorScheme.outline,
        activeSize: const Size(22.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        activeShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
      ),

      dotsContainerDecorator: ShapeDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
      ),
    );
  }
}
