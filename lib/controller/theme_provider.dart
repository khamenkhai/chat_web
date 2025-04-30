// lib/core/providers/theme_provider.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Model: Theme state
class ThemeState {
  final ThemeMode themeMode;
  final bool isDarkMode;

  ThemeState({
    required this.themeMode,
    required this.isDarkMode,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    bool? isDarkMode,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

// Controller: Theme Notifier
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(
    themeMode: ThemeMode.system,
    isDarkMode: false,
  ));

  // Initialize from preferences
  Future<void> loadTheme() async {
    // Here you would load from SharedPreferences or similar
    // For simplicity, we'll use system theme by default
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    state = state.copyWith(
      themeMode: ThemeMode.light,
      // themeMode: ThemeMode.system,
      isDarkMode: brightness == Brightness.dark,
    );
  }

  // Change theme mode
  void toggleTheme(bool isDark) {
    state = state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      isDarkMode: isDark,
    );
    // Here you would save to SharedPreferences or similar
  }

  // Switch between light/dark/system
  void setThemeMode(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark || 
                  (mode == ThemeMode.system && 
                   WidgetsBinding.instance.window.platformBrightness == Brightness.dark);
    
    state = state.copyWith(
      themeMode: mode,
      isDarkMode: isDark,
    );
    // Here you would save to SharedPreferences or similar
  }
}

// Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});