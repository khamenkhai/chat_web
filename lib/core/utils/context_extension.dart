// utils/context_extensions.dart
import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  Color get primaryColor => theme.primaryColor;
  Color get error => theme.colorScheme.onError;
}
