// Neat little helper functions that allow to work more elegantly with
// `nullable` variables or fewer in-between variables, inspired by Kotlin.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobi_app_2/util/extensions/primitive_extensions.dart';
import 'package:mobi_app_2/util/logging/logging.dart';

///
/// Execute some code and return the result of the block. Allows for code
/// execution inside of statements.
///
/// Example:
/// ```dart
///   String? foo = null;
///   foo = "foo";
///   var bar = foo ?? run(() { /* some code */ }
/// ```
///
/// NOTE: Also valuable to group and scope code inside large functions/methods
/// where splitting up into smaller functions is not feasible due to e.g., too
/// long parameter lists, or multiple return values.
///
T run<T>(T Function() runBlock) {
  return runBlock();
}

///
/// Execute the given (potentially async) code [runBlock] but make it take at
/// least for [minDuration].
/// I.e., when the execution (e.g., a web request) is quicker, this method will
/// wait until the minDuration is reached. If it takes longer, no additional
/// delay is added.
///
Future<T> runWithMinDuration<T>(
  FutureOr<T> Function() runBlock,
  Duration minDuration,
) async {
  final computationResult = runBlock();
  final minDelay = Future.delayed(minDuration);

  if (computationResult is Future) {
    await Future.wait([computationResult as Future<T>, minDelay]);
  } else {
    await minDelay;
  }

  return computationResult;
}

///
/// Runs the given block in a try/catch environment.
/// In case [runBlock] executes without throwing, its result will be returned,
/// `null` otherwise.
///
T? tryRun<T>(T Function() runBlock, [Function(dynamic)? errorCallback]) {
  try {
    return runBlock();
  } catch (e) {
    errorCallback?.call(e);
    return null;
  }
}

///
/// Run the given function **ONLY ON DEBUG BUILDS**.
/// No-op for `profile` or `release` builds.
///
/// Useful for debugging and development purposes.
///
/// Use [activate] to enable/disable the execution of the [devBlock] for quick
/// switching during testing sessions.
///
bool dev(void Function() devBlock, {bool activate = true, String? message}) {
  if (kReleaseMode || !activate) {
    return false;
  }
  L.dev(
      '${message ?? 'Running dev code block!'} (${findDevBlockCodeLocation(2)})');
  devBlock();
  return true;
}

///
/// Attempts to read the stacktrace and extract the running method from
/// stack trace line [stackTraceOffset].
///
String findDevBlockCodeLocation(int stackTraceOffset) {
  final current = StackTrace.current;
  final stackLines = current.toString().split('\n');
  if (stackLines.length < stackTraceOffset + 1) {
    // stack trace is too short? Weird!
    return '?';
  }
  final sourceLine = stackLines[stackTraceOffset];
  return sourceLine.subStringOrNull(8) ?? '?';
}

///
/// Measures and prints the execution time of a given lambda.
/// This is only done when in dev mode or enforced through [measureInProd]
///
Future<T> measure<T>(
  Future<T> Function() toMeasure, {
  String message = '',
  bool measureInProd = false,
}) async {
  if (kReleaseMode && !measureInProd) {
    return toMeasure();
  }

  final stopwatch = Stopwatch()..start();
  final ret = await toMeasure();
  stopwatch.stop();
  L.d('Measured $message: ${stopwatch.elapsedMilliseconds}ms');
  return ret;
}

///
/// Simple, inline-capable way to cast a value to an expected type, or fallback
/// to null if not of that type.
///
T? tryCast<T>(dynamic x) {
  if (x is T) {
    return x;
  }
  return null;
}

extension ScopeFunctions<T> on T {
  ///
  /// Execute some mapping code on an object.
  /// Useful to only do some work in case an object is not null.
  ///
  /// ```dart
  ///   String? maybeNull = null;
  ///   maybeNull?.let((notNull) => print(notNull));
  /// ```
  ///
  /// Can well be combined with [run]:
  ///
  /// ```dart
  ///   String? maybeNull = null;
  ///   var foo = maybeNull?.let(/*..*/) ?? run(/*..*/);
  /// ```
  ///
  R let<R>(R Function(T it) block) {
    return block(this);
  }

  ///
  /// Returns the given object if in debug mode (and logging [message] if given),
  /// or `null` otherwise.
  ///
  T? ifDev({String? message}) {
    if (!kReleaseMode) {
      L.dev(
          '${message ?? 'Accept as non-null as in dev mode'} (${findDevBlockCodeLocation(2)})');
      return this;
    }
    return null;
  }

  ///
  /// Simple conditional/optional casting.
  /// Returns `this` cast to the given type if it is of that type, null otherwise.
  ///
  C? as<C>() {
    final dynamic x = this;
    if (x is C) return x;
    return null;
  }

  ///
  /// Alias for [let] that can be used when the running operation is mostly
  /// concerned with mapping one thing to another. Functional identical to [let]
  ///
  /// Example:
  /// ```dart
  ///   class Person {
  ///     String lastName = 'itchup`;
  ///     String firstName = 'smac kmab';
  ///   }
  ///
  ///   Person getSomePerson(){ /* db access or idk */ }
  ///
  ///   String fullName = getSomePerson().mapTo(
  ///     (p) => '${p.firstName} ${p.lastName}');
  /// ```
  R mapTo<R>(R Function(T it) block) {
    return block(this);
  }

  ///
  /// Run some code on an object and return the object itself.
  ///
  /// Very close to Dart's `..` operator but better suited to deal with
  /// nullables. Nice to implement side-effects for, e.g., logging.
  ///
  /// Example:
  /// ```dart
  ///   class Person {
  ///     String lastName = 'itchup`;
  ///     String firstName = 'smac kmab';
  ///   }
  ///
  ///   Person fooFunc() => Person().also(print('Person created!'));
  /// ```
  ///
  /// or
  /// ```dart
  ///   String? shouldNotBeNull;
  ///   var output = shouldNotBeNull ?? 'shite'.also((_) => L.bug('Fakap'));
  /// ```
  ///
  T also(void Function(T it) block) {
    block(this);
    return this;
  }

  ///
  /// Run a check and return null if the check fails.
  /// Useful for chaining conditions.
  ///
  /// dart```
  ///   String? nameCandidate = '';
  ///   String name = nameCandidate?.takeIf((s) => s.isNotEmpty) ?? '<MISSING>';
  /// ```
  T? takeIf(bool Function(T it) check) {
    return check(this) ? this : null;
  }

  ///
  /// Run the given block to replace a given value with something different
  /// **ONLY ON DEBUG BUILDS**
  /// No-op for `profile` or `release` builds.
  ///
  /// Example:
  /// ```dart
  ///   String foo = getRealFoo().devOverride((_) => 'devFakeFoo');
  /// ```
  ///
  /// Use the [activateOverride] optional parameter to quickly switch between
  /// overridden and original values.
  ///
  T devOverride(
    T Function(T it) devReplacement, {
    bool activateOverride = true,
    String? name,
  }) {
    if (kReleaseMode || !activateOverride) return this;

    final replacement = devReplacement(this);
    L.dev('Running dev override of "${toString().crop(250)}"'
        '${name?.let((it) => ' for $it') ?? ''}'
        ' to "${replacement.toString().crop(250)}"'
        ' (${findDevBlockCodeLocation(2)})');
    return replacement;
  }
}

extension StringScopeFunctions on String? {
  String? takeIfNotEmpty() {
    if (this?.isNotEmpty == true) return this;
    return null;
  }
}

extension Chaining on bool {
  ///
  /// Executes [toCallIfTrue] only if `this` is true and returns the result
  /// of [toCallIfTrue]. No-op and returns `null` otherwise.
  ///
  T? ifTrue<T>(T Function() toCallIfTrue) {
    if (this) return toCallIfTrue();
    return null;
  }
}

extension ComfortableLoop on int {
  ///
  /// Runs the given function `this` times. If `this` is <= 0, the call is
  /// a no-op.
  ///
  void times(Function() call) {
    for (int i = 0; i < this; i++) {
      call();
    }
  }

  ///
  /// Runs the given function `this` times. If `this` is <= 0, the call is
  /// a no-op.
  ///
  void timesIndexed(Function(int) call) {
    for (int i = 0; i < this; i++) {
      call(i);
    }
  }

  ///
  /// Same as [times] but built to accept async functions. Will await each run
  /// of [call] before proceeding.
  ///
  Future<void> timesAsync(FutureOr Function() call) async {
    for (int i = 0; i < this; i++) {
      await call();
    }
  }
}
