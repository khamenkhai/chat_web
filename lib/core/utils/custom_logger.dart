import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class CustomLogger {

  final Logger logger;

  CustomLogger({required this.logger});

  void log(String message) {
    if (kDebugMode) {
      logger.f(message, stackTrace: StackTrace.fromString(""));
    }
  }
  void logDebug(String message) {
    if (kDebugMode) {
      logger.t(message, stackTrace: StackTrace.fromString(""));
    }
  }

  void logInfo(String message) {
    if (kDebugMode) {
      logger.i(message,);
    }
  }

  void logWarning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      logger.w(
        message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      logger.f(
        message,
      );
    }
  }
}
