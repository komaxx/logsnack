//
// This file contains a collection of multi-purpose convenience functions
// for basic data types.
//

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:mobi_app_2/util/extensions/collection_extensions.dart';
import 'package:mobi_app_2/util/logging/logging.dart';
import 'package:mobi_app_2/util/scope_functions.dart';

extension AngleConverting on num {
  double radiansToDegrees() => (this * 180.0) / pi;

  double degreesToRadians() => (this / 180.0) * pi;
}

extension SafeSubstring on String {
  ///
  /// Similar to [substring] but in case substrings conditions are not
  /// observed (e.g., end >= string length), `null` is returned instead.
  ///
  String? subStringOrNull(int start, [int? end]) {
    if (start < 0 || start >= length) return null;
    if (end != null && (end < start || end > length)) return null;
    return substring(start, end);
  }

  ///
  /// Similar to [substring] but in case substrings conditions are not
  /// observed (e.g., end >= string length), [start] and [end] will be clamped
  /// to valid ranges.
  ///
  String safeSubString(int start, [int? end]) {
    final safeStart = start.clamp(0, length - 1);
    final safeEnd = end?.let((it) => it.clamp(safeStart, length - 1));
    return substring(safeStart, safeEnd);
  }

  ///
  /// Delivers the last [length] characters of the string.
  /// In case the string is shorter than [length], the returned string will
  /// be the complete string.
  ///
  String postfix(int length) {
    if (this.length < length) return this;
    return substring(this.length - length);
  }
}

extension Hashing on String {
  ///
  /// Creates a simple MD5 hash and returns it converted to a String.
  /// This should be used for convenience only, e.g., to more easily compare
  /// whether Strings are different from each other (think: long JWTs).
  ///
  /// Should NOT be used for ANYTHING security related!
  ///
  String getMd5Hash() => crypto.md5.convert(utf8.encode(this)).toString();
}

extension Trimming on String {
  ///
  /// Similar to the ordinary `trim` method, but removes a specific String
  /// instead of variants of white spaces.
  ///
  String trimAwayRight(String toTrimAway) {
    var ret = this;
    while (ret.endsWith(toTrimAway)) {
      ret = ret.substring(0, ret.length - toTrimAway.length);
    }
    return ret;
  }

  ///
  /// Similar to the ordinary `trim` method, but removes a specific String
  /// instead of variants of white spaces.
  ///
  String trimAwayLeft(String toTrimAway) {
    var ret = this;
    while (ret.startsWith(toTrimAway)) {
      ret = ret.substring(toTrimAway.length);
    }
    return ret;
  }

  ///
  /// Cuts off the string at the given max length, if longer. Otherwise returns
  /// the string itself.
  ///
  String crop([int maxLength = 500]) => substring(0, min(maxLength, length));

  ///
  /// Cuts away from the string at the start to the given max length, if longer.
  /// Otherwise returns the string itself.
  ///
  String cropStart([int maxLength = 500]) =>
      substring(max(0, length - maxLength));
}

extension FilePaths on String {
  ///
  /// Simple util function that joins a base path with a sub-path, making sure
  /// to use the right file system delimiter, and only one.
  /// [subPath] is not sanitized! Make sure to only include characters that are
  /// safe for paths (or use [sanitizedForFilePathUse]).
  ///
  /// Makes no assumptions if `this` is an absolute path or not.
  ///
  String joinAsFilePathWith(String subPath) =>
      '${trimAwayRight(Platform.pathSeparator)}${Platform.pathSeparator}${subPath.trimAwayLeft(Platform.pathSeparator)}';

  ///
  /// Replaces all characters in the String, which are not safe for file paths,
  /// with a [placeholder].
  /// Will *not* replace path separators.
  ///
  String sanitizedForFilePathUse({String placeholder = '_'}) {
    final pathSeparator =
        Platform.pathSeparator == '\\' ? r'\\' : Platform.pathSeparator;
    return replaceAll(RegExp('[^a-zA-Z\\d.\\-_$pathSeparator]'), placeholder);
  }

  ///
  /// Replaces characters that are not accepted by the TMS API. This mostly
  /// affects tag characters used in HTML.
  ///
  String sanitizedForTmsSubjectAndDescription() {
    return replaceAll('<', '&lt;');
  }
}

extension Chunking on String {
  ///
  /// Breaks the the string up into lines with the given length, not taking
  /// into account word wrapping, whitespaces or similar.
  ///
  /// Example:
  ///
  /// `lineWrapString('abcde', 2)` -> `ab\ncd\ne`
  ///
  String lineWrapString(int size) {
    final chunks = <String>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(safeSubString(i, i + size));
    }
    return chunks.join('\n');
  }
}

extension Base64Conversion on String? {
  ///
  /// Attempts to read the given String as a base64 encoded byte array.
  ///
  /// Will *NOT* throw but return `null` if the string could not be decoded,
  /// e.g., because of a format error.
  ///
  Uint8List? decodeAsBase64() => this?.let((it) {
        try {
          return base64.decode(base64.normalize(it));
        } catch (e) {
          L.e('Could not decode String as base64: $e, source: $it');
          return null;
        }
      });
}

extension ByteDataDecoding on Uint8List {
  ///
  /// Attempts to decode the given bytes array as a UTF8 string.
  /// Will return `null` in case the decoding failed.
  ///
  String? decodeAsUtf8String() => tryRun(() => utf8.decode(this));
}

extension Comparison on String? {
  ///
  /// Compares two strings for case-insensitive equality - as far as that is
  /// conceptually possible with Unicode.
  /// Will return `true` in case `this` have the same lower case representation
  /// or BOTH are null.
  ///
  bool equalsIgnoreCase(String? other) =>
      this?.toLowerCase() == other?.toLowerCase();
}

extension JsonParsing on int {
  ///
  /// Interpret this as a Unix timestamp (UTC, seconds since epoch) and
  /// transform to more usable DateTime.
  ///
  DateTime asUnixTimestampToDateTime() =>
      DateTime.fromMillisecondsSinceEpoch(this * 1000);
}

extension UnixTimeStampMapping on DateTime {
  ///
  /// Represents the given DateTime in the format of unix timestamps (seconds
  /// since epoch). This is the complementary method to
  /// [JsonParsing.asUnixTimestampToDateTime].
  ///
  /// Note that by representing a [DateTime] like this, precision is significantly
  /// decreased!
  ///
  int toUnixTimestamp() => millisecondsSinceEpoch ~/ 1000;
}

extension FileNamePrinting on DateTime {
  ///
  /// Renders the given [DateTime] in a form that is suitable for inclusion
  /// in a file name.
  ///
  /// E.g.: "04_01__22_05" for the 1st of April, 10pm and 5 minutes
  ///
  String toStringForFileName() =>
      '${month.toString().padLeft(2, '0')}_${day.toString().padLeft(2, '0')}__${hour.toString().padLeft(2, '0')}_${minute.toString().padLeft(2, '0')}';
}

extension ServerClockOffsetCorrection on DateTime {
  ///
  /// Adjusts `this` timestamp to correct for clock differences between the server
  /// and the local clock.
  ///
  /// Once (ONCE!) this is called, the returned [DateTime] has the clock drift
  /// removed.
  /// Thus, the returned, corrected value can be compared to server-created
  /// timestamps.
  ///
  /// Usually, this is applied to get a `DateTime.now()` that can relate to
  /// timestamps created by and received from the server.
  ///
  /// Example:
  /// Let's assume the local clock is ahead of the server clock by 1 hour, so that
  /// it's 1:30pm on the server but already 2:30 pm on the phone. Now, when an
  /// alarm is triggered and received, we need to compare `now` with the alarm's
  /// `startTime` to check whether we should still show the alarm and play
  /// ringtones. Because of the clock drift though, when we compare [DateTime.now]
  /// with incoming timestamps, it would be computed to be an hour old already.
  /// The alarm would erroneously not be shown.
  /// Calling [adjustLocalToServerTime] will adjust `this` from `2:30pm` to `1:30pm`,
  /// thus converting local timestamps into the reference system of the server.
  ///
  DateTime adjustLocalToServerTime(Duration serverOffset) => add(serverOffset);

  ///
  /// Adjusts `this` timestamp to correct for clock differences between the server
  /// and the local clock.
  /// This will bring server timestamps into the local time reference, i.e., if
  /// the resulting [DateTime] is printed to the screen, it will look correctly
  /// for the local clock.
  ///
  /// Example:
  /// Let's assume the local clock is ahead of the server clock by 1 hour, so that
  /// it's 1:30pm on the server but already 2:30 pm on the phone. Now, when an
  /// alarm is triggered and received, and we display the `startTime`, it would
  /// read `1:30pm` or `1 hour ago` (the server's time) which would be confusing.
  /// After calling [adjustServerToLocalTime] `this` is adjusted to `2:30pm` / `now`,
  /// which would look correct to the user.
  ///
  DateTime adjustServerToLocalTime(Duration serverOffset) => add(-serverOffset);
}

extension AgeComputation on DateTime {
  ///
  /// Computes the time duration between now and `this`.
  /// Negative for [DateTime]s in the future.
  ///
  Duration age() => DateTime.now().difference(this);
}

extension DateTimeArithmetic on DateTime {
  static final distantFuture = DateTime(9999);

  /// Syntactic sugar for [DateTime.add]
  DateTime operator +(Duration d) => add(d);

  /// Syntactic sugar for [isBefore]
  bool operator <(DateTime other) => isBefore(other);

  /// Syntactic sugar for [isAfter]
  bool operator >(DateTime other) => isAfter(other);

  /// Syntactic sugar for [difference]
  Duration operator -(DateTime other) => difference(other);
}

extension DurationComparison on Duration {
  ///
  /// Simple comparison based on the duration representation in milliseconds.
  ///
  bool isLargerThan(Duration other) => inMilliseconds > other.inMilliseconds;

  ///
  /// Compares the absolute value of two durations, i.e.
  /// ```
  /// Duration(seconds: -3).isAbsoluteLargerThan(Duration(seconds: 1)) => true
  /// Duration(seconds: -1).isAbsoluteLargerThan(Duration(seconds: 4)) => false
  /// Duration(seconds: -1).isAbsoluteLargerThan(Duration(seconds: -1)) => false
  /// Duration(seconds: -5).isAbsoluteLargerThan(Duration(seconds: -4)) => true
  /// ```
  ///
  bool isAbsoluteLargerThan(Duration other) => abs().isLargerThan(other.abs());
}

extension Printing on X509Certificate {
  ///
  /// The SHA1 value as a user-friendly string, like:
  /// "12:34:56:78:AE"
  ///
  String get sha1String => sha1
      .map((e) => e.toRadixString(16).toUpperCase())
      .interlaced(by: ':', stepWidth: 1)
      .join();
}

extension Range on Random {
  ///
  /// Creates a new random value in [from] - [to] (exclusive).
  /// If [from] > [to], this will fallback to delivering [from].
  ///
  int intIn({required int from, required int to}) {
    return from + nextInt(max(0, to - from));
  }

  double doubleIn({required double from, required double to}) {
    return from + nextDouble() * (max(0, to - from));
  }
}

extension RandomString on Random {
  ///
  /// Creates a random string that may be used as a identifier, like a UUID.v4
  ///
  /// It's sufficiently long to make even global collisions unlikely.
  ///
  /// Identifiers are generated to be safe to use in most circumstances as they
  /// are limited to printable ascii characters. No escaping necessary.
  ///
  String generateIdentifier() {
    final random = Random();

    final bytes = List<int>.generate(50, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
}

extension DurationCreators on int {
  Duration get ms => Duration(milliseconds: this);

  Duration get seconds => Duration(seconds: this);

  Duration get hours => Duration(hours: this);
}

///
/// Simple function that delivers the maximum of three values, using the same
/// logic and semantics as [max] (which is used in here)
///
T max3<T extends num>(T a, T b, T c) => max(a, max(b, c));

///
/// Simple function that delivers the maximum of four values, using the same
/// logic and semantics as [max] (which is used in here)
///
T max4<T extends num>(T a, T b, T c, T d) => max(a, max(b, max(c, d)));
