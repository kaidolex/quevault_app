import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Theme mode state
enum AppThemeMode { light, dark, system }

/// Theme state class
class ThemeState {
  final AppThemeMode themeMode;
  final bool isLoading;

  const ThemeState({this.themeMode = AppThemeMode.system, this.isLoading = false});

  ThemeState copyWith({AppThemeMode? themeMode, bool? isLoading}) {
    return ThemeState(themeMode: themeMode ?? this.themeMode, isLoading: isLoading ?? this.isLoading);
  }

  /// Convert to Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Theme ViewModel using Riverpod StateNotifier
class ThemeViewModel extends StateNotifier<ThemeState> {
  static const String _themeKey = 'app_theme_mode';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ThemeViewModel() : super(const ThemeState()) {
    _loadTheme();
  }

  /// Load theme from storage
  Future<void> _loadTheme() async {
    try {
      state = state.copyWith(isLoading: true);

      final savedTheme = await _storage.read(key: _themeKey);
      if (savedTheme != null) {
        final themeMode = AppThemeMode.values.firstWhere((mode) => mode.toString() == savedTheme, orElse: () => AppThemeMode.system);
        state = state.copyWith(themeMode: themeMode);
      }
    } catch (e) {
      // If loading fails, use system default
      state = state.copyWith(themeMode: AppThemeMode.system);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);

    try {
      await _storage.write(key: _themeKey, value: themeMode.toString());
    } catch (e) {
      // Handle storage error silently
    }
  }

  /// Toggle between light and dark mode (ignores system)
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Get readable theme mode name
  String get currentThemeName {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  /// Check if current mode is dark
  bool get isDarkMode => state.themeMode == AppThemeMode.dark;

  /// Check if current mode is light
  bool get isLightMode => state.themeMode == AppThemeMode.light;

  /// Check if current mode is system
  bool get isSystemMode => state.themeMode == AppThemeMode.system;
}

/// Provider for theme state
final themeViewModelProvider = StateNotifierProvider<ThemeViewModel, ThemeState>((ref) {
  return ThemeViewModel();
});
