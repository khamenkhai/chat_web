import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class AppTheme {
  // System UI Overlay Styles
  static const SystemUiOverlayStyle _lightSystemOverlayStyle = SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.dark,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle _darkSystemOverlayStyle = SystemUiOverlayStyle(
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  );

  // Color Palette (ShadCN inspired)
  static const Color _primary = Color(0xFF3B82F6); // Blue-500
  static const Color _primaryForeground = Colors.white;
  static const Color _secondary = Color(0xFF64748B); // Slate-500
  static const Color _secondaryForeground = Colors.white;
  static const Color _destructive = Color(0xFFEF4444); // Red-500
  static const Color _destructiveForeground = Colors.white;
  static const Color _muted = Color(0xFFF1F5F9); // Slate-100
  static const Color _mutedForeground = Color(0xFF64748B); // Slate-500
  // static const Color _accent = Color(0xFFE2E8F0); // Slate-200
  // static const Color _accentForeground = Color(0xFF0F172A); // Slate-900

  // Dark mode variants
  static const Color _darkPrimary = Color(0xFF60A5FA); // Blue-400
  static const Color _darkPrimaryForeground = Color(0xFF020617); // Slate-950
  static const Color _darkSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color _darkSecondaryForeground = Color(0xFF020617); // Slate-950
  static const Color _darkMuted = Color(0xFF1E293B); // Slate-800
  static const Color _darkMutedForeground = Color(0xFF94A3B8); // Slate-400
  // static const Color _darkAccent = Color(0xFF334155); // Slate-700
  // static const Color _darkAccentForeground = Color(0xFFF8FAFC); // Slate-50

  // Text Styles
  static const TextStyle _baseTextStyle = TextStyle(
    fontFamily: 'Inter', // Recommended to use Inter font
    height: 1.5,
  );

  static TextTheme _buildTextTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      displayLarge: _baseTextStyle.copyWith(
        fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: _baseTextStyle.copyWith(
        fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: _baseTextStyle.copyWith(
        fontSize: 30, fontWeight: FontWeight.bold, color: textColor),
      headlineLarge: _baseTextStyle.copyWith(
        fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: _baseTextStyle.copyWith(
        fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: _baseTextStyle.copyWith(
        fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
      titleLarge: _baseTextStyle.copyWith(
        fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium: _baseTextStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      titleSmall: _baseTextStyle.copyWith(
        fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: _baseTextStyle.copyWith(
        fontSize: 16, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: _baseTextStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
      bodySmall: _baseTextStyle.copyWith(
        fontSize: 12, fontWeight: FontWeight.normal, color: textColor),
      labelLarge: _baseTextStyle.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, color: mutedColor),
      labelMedium: _baseTextStyle.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: mutedColor),
      labelSmall: _baseTextStyle.copyWith(
        fontSize: 10, fontWeight: FontWeight.w500, color: mutedColor),
    );
  }

  // Light Theme
  static ThemeData light({String? fontFamily}) {
    final textTheme = _buildTextTheme(Colors.black, _mutedForeground);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primary,
        onPrimary: _primaryForeground,
        secondary: _secondary,
        onSecondary: _secondaryForeground,
        error: _destructive,
        onError: _destructiveForeground,
        background: Colors.white,
        onBackground: Colors.black,
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceVariant: _muted,
        onSurfaceVariant: _mutedForeground,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: _lightSystemOverlayStyle,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(color: _primaryForeground),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: _primaryForeground),
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: _primary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _mutedForeground),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _mutedForeground),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: _secondary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        checkColor: MaterialStateProperty.all(_primaryForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primary;
          }
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primary;
          }
          return const Color(0xFFE2E8F0);
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _primary.withOpacity(0.5);
          }
          return const Color(0xFFE2E8F0);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primary,
        unselectedItemColor: _mutedForeground,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _muted,
        disabledColor: _muted,
        selectedColor: _primary,
        secondarySelectedColor: _primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: textTheme.labelMedium?.copyWith(color: Colors.black),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: _primaryForeground),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }

  // Dark Theme
  static ThemeData dark({String? fontFamily}) {
    final textTheme = _buildTextTheme(Colors.white, _darkMutedForeground);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: _darkPrimaryForeground,
        secondary: _darkSecondary,
        onSecondary: _darkSecondaryForeground,
        error: _destructive,
        onError: _destructiveForeground,
        background: const Color(0xFF020617), // Slate-950
        onBackground: Colors.white,
        surface: const Color(0xFF0F172A), // Slate-900
        onSurface: Colors.white,
        surfaceVariant: _darkMuted,
        onSurfaceVariant: _darkMutedForeground,
      ),
      scaffoldBackgroundColor: const Color(0xFF020617), // Slate-950
      appBarTheme: AppBarTheme(
        systemOverlayStyle: _darkSystemOverlayStyle,
        backgroundColor: const Color(0xFF0F172A), // Slate-900
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: textTheme,
      primaryTextTheme: textTheme.copyWith(
        bodyLarge: textTheme.bodyLarge?.copyWith(color: _darkPrimaryForeground),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: _darkPrimaryForeground),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B), // Slate-800
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF0F172A), // Slate-900
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1), // Slate-800
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: _darkPrimary,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: _darkPrimaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFF334155)), // Slate-700
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _destructive, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _darkMutedForeground),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _darkMutedForeground),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: _darkSecondary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        checkColor: MaterialStateProperty.all(_darkPrimaryForeground),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimary;
          }
          return Colors.transparent;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimary;
          }
          return const Color(0xFF334155); // Slate-700
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimary.withOpacity(0.5);
          }
          return const Color(0xFF334155); // Slate-700
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A), // Slate-900
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkMutedForeground,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF0F172A), // Slate-900
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1), // Slate-800
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkMuted,
        disabledColor: _darkMuted,
        selectedColor: _darkPrimary,
        secondarySelectedColor: _darkPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        labelStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: _darkPrimaryForeground),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0), // Slate-200
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.black),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF0F172A), // Slate-900
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1), // Slate-800
        ),
        textStyle: textTheme.bodyMedium,
      ),
    );
  }
}