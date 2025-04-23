// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  /// Small font style
  static TextStyle kSmallFont({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Normal font style
  static TextStyle kNormalFont({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: color,
    );
  }

  /// Subtitle font style
  static TextStyle kSubTitle({Color? color}) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  /// Heading font style
  static TextStyle kHeading({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.bold, // Default to bold if not provided
      color: color,
    );
  }

  /// Large font style
  static TextStyle kLargeText({Color? color}) {
    return TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.bold,
      color: color,
    );
  }

  /// Button text style
  static TextStyle kButtonText({Color? color}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}
