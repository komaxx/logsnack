import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:mobi_app_2/util/logging/logger.dart';

/// [Logger] implementation intended for debug builds. Will provide additional
/// information about log messages (e.g.: where a log message was written) and
/// logs the result to console.
///
/// Might have a negative impact on performance, should only be present in
/// debug builds.
///
/// TIP: Use a console highlighting plugin like "Grep Console" for Intellij IDEs
/// for a more glanceable and comfortable logging experience.
class DebugLogger extends Logger {
  final DateFormat _timeStampFormatter = DateFormat.Hms().addPattern('S', '_');

  @override
  log(LogLevel level, String message) {
    // ignore: avoid_print
    print(_createLogLine(level, message));
  }

  String _createLogLine(LogLevel level, String message) {
    final timeStampString = _timeStampFormatter.format(DateTime.now());
    final levelTag = logLevelToString(level);
    final logSourceString = _extractLogSource();

    return '$timeStampString $levelTag $message ($logSourceString)';
  }

  String _extractLogSource() {
    final current = StackTrace.current;
    final stackLines = current.toString().split('\n');
    if (stackLines.length < 8) {
      // stack trace is too short? Weird!
      return '?:?';
    }
    final sourceLine = stackLines[7];
    final functionContext = _extractFunctionContextFromStackFrame(sourceLine);
    final fileContext = _extractFileContextFromStackFrame(sourceLine);

    return '$functionContext [$fileContext]';
  }

  /// Parses a stack frame and extracts the originally called function where
  /// the logging happened.
  ///
  /// NOTE: Highly dependent on the stack frame format! Probably needs
  /// attention in case the stack frame format changes with a Flutter update.
  String _extractFunctionContextFromStackFrame(String sourceLine) {
    final match = RegExp(r'( {4}(\w.+\w) \()', caseSensitive: false)
        .allMatches(sourceLine)
        .firstOrNull;
    if (match == null || match.groupCount < 2) {
      return '?';
    }

    return match.group(2) ?? '?';
  }

  /// Parses a stack frame and extracts file and line information of the place
  /// where the log call originated. Writes the information into a string.
  ///
  /// NOTE: Highly dependent on the stack frame format! Probably needs
  /// attention in case the stack frame format changes with a Flutter update.
  String _extractFileContextFromStackFrame(String sourceLine) {
    final match = RegExp(r'(\/([a-z_.]+:\d+):)', caseSensitive: false)
        .allMatches(sourceLine)
        .firstOrNull;
    if (match == null || match.groupCount < 2) {
      return '?';
    }

    return match.group(2) ?? '?';
  }
}
