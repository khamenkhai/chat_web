import 'package:flutter/material.dart';

class SizeConst {
  /// Horizontal padding constant
  static const double kHorizontalPadding = 15;

  /// Vertical spacing constant
  static const double kVerticalSpacing = 15;

  /// Card or container padding (Note: can't be const since it depends on dynamic values)
  static const EdgeInsets kCardPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  /// Border radius (this can't be `const` directly for dynamic radius)
  static const BorderRadius kBorderRadius = BorderRadius.all(
    Radius.circular(10),
  );

  /// Input field padding (can't be `const` for dynamic values)
  static const EdgeInsets kInputPadding = EdgeInsets.symmetric(
    horizontal: 18,
  );

  /// Margin for general spacing (can't be `const` for dynamic values)
  static const EdgeInsets kMargin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  /// Icon size constant
  static const double kIconSize = 24;

  /// Box shadow (can't be `const` because the default values are dynamic)
  static const BoxShadow kBoxShadow = BoxShadow(
    blurRadius: 6.0,
    color: Color(0x29000000),
    offset: Offset(0, 4),
  );

  /// Height of app bar
  static const double kAppBarHeight = 56;

  /// Divider thickness constant
  static const double kDividerThickness = 1.0;
}
