enum LogLevel {
  /// Logging used for debugging. Log messages of level should be ignored on
  /// prod builds
  D,

  /// Something expected but interesting happened, e.g., a request completed
  /// successfully
  I,

  /// User action. The user did something, like press a button.
  /// Useful to figure out what happened from a log.
  UA,

  /// Something went wrong but in an expected way, e.g., a login request failed
  /// because of wrong credentials
  W,

  /// Something went wrong unexpectedly, e.g., the data returned from the
  /// backend could not be parsed due to unexpected format.
  /// Worth looking into for a developer
  E,

  /// One of the assumptions built into the code was not met, e.g., a switch
  /// case was missing a value, some state is reached that should be impossible,
  /// ...
  /// Depending on the environment, this will be logged, sent as warning to
  /// a service like Crashlytics, or (for debug builds) will raise an [Error].
  BUG,

  /// Special log level to be used while actively debugging the system.
  /// Other than [LogLevel.D], log messages of this type are supposed to be
  /// deleted as soon as the debugging session is finished.
  ///
  /// There should never be code checked into git with [LogLevel.DEV] log
  /// messages!
  DEV
}

///
/// Interface for the backend of the logging package. Receives log messages
/// and puts them to the appropriate channels as required.
///
abstract class Logger {
  log(LogLevel level, String message);

  /// Commonly used convenience function that prints a log-level as a
  /// 2-character string
  String logLevelToString(LogLevel level) {
    switch (level) {
      case LogLevel.D:
        return 'D ';
      case LogLevel.I:
        return 'I ';
      case LogLevel.UA:
        return 'UA';
      case LogLevel.W:
        return 'W ';
      case LogLevel.E:
      case LogLevel.BUG:
        return 'EE';
      case LogLevel.DEV:
        return 'XX';
    }
  }
}
