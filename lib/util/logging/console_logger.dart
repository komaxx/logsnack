import 'package:intl/intl.dart';
import 'package:logsnack/util/logger.dart';

///
/// Simple [Logger] implementation that just prints everything to the console
/// and decorates the messages with a timestamp and the log level.
///
class ConsoleLogger extends Logger {
  final DateFormat _timeStampFormatter = DateFormat.Hms().addPattern('S', '_');

  @override
  log(LogLevel level, String message) {
    // ignore: avoid_print
    print(_createLogLine(level, message));
  }

  String _createLogLine(LogLevel level, String message) {
    final timeStampString = _timeStampFormatter.format(DateTime.now());
    final levelTag = logLevelToString(level);

    return '$timeStampString $levelTag ${message.crop(500)}';
  }
}
