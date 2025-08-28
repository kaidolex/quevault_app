import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/views/auth/setup_master_password_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: ShadApp(title: 'QueVault', debugShowCheckedModeBanner: false, home: const SetupMasterPasswordScreen()),
    );
  }
}
