import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logsnack/app.dart';
import 'package:logsnack/util/logging/logging.dart';

void main() {
  FlutterError.onError = (details) {
    L.e('UNCAUGHT FLUTTER ERROR ${details.exception}');
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const App());
    },
    (error, stack) {
      L.e('UNCAUGHT ERROR $error, stack: $stack');
      throw error;
    },
  );
}
