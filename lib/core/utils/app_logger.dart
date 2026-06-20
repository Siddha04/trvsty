import 'package:logger/logger.dart';

import '../../config/env_config.dart';

/// Thin wrapper around the [Logger] package.
///
/// In production, verbose/debug logs are suppressed and only warnings and
/// errors are emitted (which can be forwarded to Crashlytics).
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
    level: EnvConfig.isProduction ? Level.warning : Level.debug,
  );

  static void d(dynamic message) => _logger.d(message);
  static void i(dynamic message) => _logger.i(message);
  static void w(dynamic message) => _logger.w(message);

  static void e(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
