import 'package:logger/logger.dart';

// Global logger instance
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: Level.all,
);

// Convenience methods untuk logging yang lebih clean
void logDebug(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.d(message, error: error, stackTrace: stackTrace);
}

void logInfo(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.i(message, error: error, stackTrace: stackTrace);
}

void logWarning(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.w(message, error: error, stackTrace: stackTrace);
}

void logError(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.e(message, error: error, stackTrace: stackTrace);
}

void logCritical(String message, {dynamic error, StackTrace? stackTrace}) {
  logger.f(message, error: error, stackTrace: stackTrace);
}
