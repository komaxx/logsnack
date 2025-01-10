import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:mobi_app_2/util/logging/logger.dart';
import 'package:mobi_app_2/util/logging/logging.dart';

/// [Logger] implementation that is intended to be used for development and
/// testing builds.
/// Will throw an [Error] (thus: crashing the app) in case something on level
/// [LogLevel.BUG] is to be logged. Will also automatically stop the debugger
/// in a breakpoint, in case a debugger is attached.
/// This ensures that programming mistakes can not be overlooked when testing.
///
/// NOTE: It is recommended to add this logger as the LAST list entry, when
/// calling [L.setUp] to ensure that other loggers had a chance to react before
/// an error is raised in here.
class BugThrowLogger extends Logger {
  @override
  log(LogLevel level, String message) {
    if (level != LogLevel.BUG) {
      return;
    }

    debugPrintStack(label: 'BUG');
    exit(1);
  }
}
