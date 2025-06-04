// utils/context_extensions.dart
import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  Color get cardColor => theme.cardColor;
  Color get primaryColor => theme.primaryColor;
  Color get onPrimary => theme.colorScheme.onPrimary;
  Color get secondary => theme.colorScheme.secondary;
  Color get onSecondary => theme.colorScheme.onSecondary;
  Color get error => theme.colorScheme.error;
  Color get onError => theme.colorScheme.onError;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get onSurfaceVariant => theme.colorScheme.onSurfaceVariant;
  Color get tertiary => theme.colorScheme.tertiary;
  Color get secondaryTextColor => theme.colorScheme.primaryContainer;
  /// Returns an inferred ThemeMode based on current brightness and theme
  ThemeMode get themeMode =>
      theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  
  bool get isLightTheme => themeMode == ThemeMode.light;
}
