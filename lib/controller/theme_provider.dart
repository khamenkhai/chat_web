// ignore_for_file: deprecated_member_use

import 'package:chat_web/core/local_data/shared_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPref _sharedPref = SharedPref();

  ThemeNotifier() : super(ThemeState(
    themeMode: ThemeMode.system,
    isDarkMode: false,
  ));

  Future<void> loadTheme() async {
    try {
      // Load saved theme mode (0=system, 1=light, 2=dark)
      final savedThemeIndex = await _sharedPref.getInt(key: _sharedPref.themeKey);
      final themeMode = ThemeMode.values[savedThemeIndex.clamp(0, 2)];
      
      // Determine if dark mode should be enabled
      bool isDark;
      if (themeMode == ThemeMode.system) {
        final brightness = WidgetsBinding.instance.window.platformBrightness;
        isDark = brightness == Brightness.dark;
      } else {
        isDark = themeMode == ThemeMode.dark;
      }

      state = state.copyWith(
        themeMode: themeMode,
        isDarkMode: isDark,
      );
    } catch (e) {
      // Fallback to system theme if loading fails
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      state = state.copyWith(
        themeMode: ThemeMode.system,
        isDarkMode: brightness == Brightness.dark,
      );
    }
  }

  void toggleTheme(bool isDark) {
    final themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(
      themeMode: themeMode,
      isDarkMode: isDark,
    );
    _sharedPref.setInt(
      value: themeMode.index,
      key: _sharedPref.themeKey,
    );
  }

  void setThemeMode(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark || 
                  (mode == ThemeMode.system && 
                   WidgetsBinding.instance.window.platformBrightness == Brightness.dark);
    
    state = state.copyWith(
      themeMode: mode,
      isDarkMode: isDark,
    );
    _sharedPref.setInt(
      value: mode.index,
      key: _sharedPref.themeKey,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final notifier = ThemeNotifier();
  notifier.loadTheme(); // Load saved theme when provider is created
  return notifier;
});

