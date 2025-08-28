import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:quevault_app/views/app_router.dart';
import 'package:quevault_app/viewmodels/theme_viewmodel.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, child) {
          final themeState = ref.watch(themeViewModelProvider);

          return ShadApp.custom(
            appBuilder: (context) {
              return MaterialApp(
                title: 'QueVault',
                debugShowCheckedModeBanner: false,
                themeMode: themeState.flutterThemeMode,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
                  useMaterial3: true,
                ),
                darkTheme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
                  useMaterial3: true,
                ),
                home: const AppRouter(),
                builder: (context, child) {
                  return ShadAppBuilder(child: child!);
                },
              );
            },
          );
        },
      ),
    );
  }
}
