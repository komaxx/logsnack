import 'package:flutter/foundation.dart';
import 'package:logsnack/util/logging/debug_logger.dart';
import 'package:logsnack/util/logging/logger.dart';
import 'package:rxdart/rxdart.dart';

/// Central logging class.
///
/// All logging needs should run through this facade. It will internally then
/// relay them to a set of [Logger] instances, which will format proper log
/// messages and print them to the console, or write them to files as needed.
///
/// Call [setUp] to configure what will be logged and where by providing a new
/// set of [Logger]s. By default, will only log to the console.
///
/// Usage:
/// Simply call the appropriate static method that fits the intended log level
/// on [L], e.g.:
/// ``` dart
/// L.e('This is bad, mmkay?');    // will log an error
/// ```
///
class L {
  /// All currently set loggers.
  /// Manipulation at runtime is not supported! It's recommended to call [setUp]
  /// during initialisation of the app.
  static List<Logger> _loggers = [
    DebugLogger(),
  ];

  /// The minimum log level that will be logged. Logging calls with a log level
  /// lower than this, will simply be ignored.
  static LogLevel minLogLevel = kDebugMode ? LogLevel.D : LogLevel.I;

  /// Access all currently set loggers.
  /// Modify this list by calling [setUp] with a new set of loggers.
  static List<Logger> get loggers => _loggers;

  /// Call this to configure the logging behaviour of the system. Provide
  /// an empty list to stop logging altogether.
  static setUp(List<Logger> newLoggers) {
    _loggers = newLoggers;
  }

  /// Logging used for (later) debugging. Log messages of this level are
  /// normally ignored on prod builds. Can contain sensitive data!
  static d([String? message]) => _writeLog(LogLevel.D, message);

  /// Something expected but interesting happened, e.g., a request completed
  /// successfully.
  static i([String? message]) => _writeLog(LogLevel.I, message);

  /// User action. The user did something, like press a button.
  static ua([String? message]) => _writeLog(LogLevel.UA, message);

  /// Something went wrong but in an expected way, e.g., a login request failed
  /// because of wrong credentials
  static w([String? message]) => _writeLog(LogLevel.W, message);

  /// Something went wrong unexpectedly, e.g., the data returned from the
  /// backend could not be parsed due to unexpected format.
  /// Worth looking into for a developer
  static e([String? message]) => _writeLog(LogLevel.E, message);

  /// One of the assumptions built into the code was not met, e.g., a switch
  /// case was missing a value, some state is reached that should be impossible,
  /// ...
  /// Depending on the environment, this will be logged, sent as warning to
  /// a service like Crashlytics, or (for debug builds) will raise an [Error].
  static bug([String? message]) => _writeLog(LogLevel.BUG, message);

  /// Special log level that should *ONLY* be used while actively debugging
  /// something. Will be rendered in console logs especially visible.
  ///
  /// Log messages of this type should NOT be checked into git!
  /// Motivation: Compare to [dev] scope function.
  static dev([String? message]) => _writeLog(LogLevel.DEV, message);

  static void _writeLog(LogLevel level, String? message) {
    if (level.index < minLogLevel.index) {
      // log level is too low. Ignore.
      return;
    }

    for (var logger in loggers) {
      logger.log(level, message ?? '_');
    }
  }
}

extension StreamDevLogging<T> on Stream<T> {
  Stream<T> devLog([String Function(T event)? logFunction]) {
    if (logFunction == null) {
      return doOnData((event) => L.dev('$event'));
    }
    return doOnData((event) => L.dev(logFunction(event)));
  }
}
