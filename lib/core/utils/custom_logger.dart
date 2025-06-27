import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final loggerProvider = Provider<CustomLogger>((ref) {
  return CustomLogger(logger: ref.read(loggerPackageProvider));
});

final loggerPackageProvider = Provider<Logger>(
  (ref) {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
      ),
    );
  },
);

class CustomLogger {
  final Logger logger;

  // Private constructor
  CustomLogger({Logger? logger}) : logger = logger ?? _defaultLogger();

  // Default logger instance
  static Logger _defaultLogger() {
    return Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
      ),
    );
  }

  void log(String message) {
    if (kDebugMode) logger.f(message,stackTrace: StackTrace.fromString(""));
  }

  void logDebug(String message) {
    if (kDebugMode) logger.d(message);
  }

  void logInfo(String message) {
    if (kDebugMode) logger.i(message);
  }

  void logWarning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) logger.w(message, error: error, stackTrace: stackTrace);
  }

  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) logger.e(message, error: error, stackTrace: stackTrace);
  }

  void logFatal(String message, {dynamic error, StackTrace? stackTrace}) {
    if (kDebugMode) logger.f(message, error: error, stackTrace: stackTrace);
  }
}
