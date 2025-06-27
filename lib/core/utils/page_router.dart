import 'package:flutter/material.dart';

class AppNavigator {
  /// Pushes a new page with default transition
  static Future<T?> pushPage<T extends Object?>(
      BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Pushes a new page and removes the current one from the stack
  static Future<T?> pushReplacement<T extends Object?>(
      BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, void>(
      context,
      MaterialPageRoute<T>(
        builder: (context) => page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
    );
  }

  /// Pushes a new page and clears all previous routes
  static Future<void> pushAndRemove(BuildContext context, Widget page) {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        settings: RouteSettings(name: page.runtimeType.toString()),
      ),
      (route) => false,
    );
  }

  /// Pops the current page
  static void popPage(BuildContext context, {dynamic result}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  static Future<T?> pushWithFade<T extends Object?>(
      BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
