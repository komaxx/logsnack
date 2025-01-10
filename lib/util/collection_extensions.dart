import 'dart:math';

import 'package:collection/collection.dart';
import 'package:logsnack/util/logging/logging.dart';

extension MapExtension<T> on Map<T, dynamic> {
  ///
  /// Convenience function that only adds the given pair to the Map
  /// in case both, the key and value, are != null.
  ///
  void addValueIfNotNull({T? key, dynamic value}) {
    if (key == null || value == null) {
      return;
    }

    addAll({key: value});
  }

  ///
  /// Iterates over all stored values and removes all entries for which the
  /// `value` is null.
  ///
  void clearNullValues() => removeWhere((key, value) => value == null);
}

extension MapFiltering<S, T> on Map<S, T> {
  ///
  /// Creates a new Map from `this` that only contains the MapEntries for which
  /// [predicate] delivered `true`.
  ///
  Map<S, T> where(bool Function(S key, T value) predicate) {
    final Map<S, T> ret = {};
    forEach((key, value) {
      if (predicate(key, value)) {
        ret[key] = value;
      }
    });
    return ret;
  }
}

extension ListFiltering<T> on Iterable<T> {
  ///
  /// Syntactic sugar that creates a new Iterable that contains all original
  /// elements of the set apart from [toRemove].
  ///
  /// Will always return a new [Iterable] even if [toRemove] was not found in the
  /// original Iterable.
  ///
  Iterable<T> without(T toRemove) => where((it) => it != toRemove);
}

extension FormUrlPayload on Map {
  ///
  /// Encodes all entries of this map into a single String in the form that is
  /// required for query parameters of form-url POST requests.
  /// Url-encodes as required.
  ///
  /// { 'a':'aValue', 'b':'b value' } => 'a=aValue&b=b%20value
  ///
  String toFormUrlRequestPayload() => entries
      .map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      )
      .join('&');
}

extension StringMapHashing on Map<String, String> {
  int deepHash() => Object.hashAllUnordered(
        entries.map((it) => it.hashSource()),
      );
}

extension _StringMapEntryHash on MapEntry<String, String> {
  int hashSource() => key.hashCode ^ value.hashCode;
}

extension AsyncProcessing<T> on Iterable<T> {
  ///
  /// Function that allows for filtering of an iterable with an async function
  /// call.
  /// Note that this operates on the Iterable at the time of calling this
  /// function; changes to it while the Future is being processed are not
  /// reflected in the result and can not disturb the processing.
  ///
  Future<Iterable<T>> whereAsync(Future<bool> Function(T) check) async {
    // copy to avoid concurrent access errors.
    final elements = List.from(this);

    final List<T> result = [];
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (await check(element)) {
        result.add(element);
      }
    }
    return result;
  }

  ///
  /// Map all elements of the Iterable to a new Iterable using an async function
  ///
  Future<Iterable<R>> mapAsync<R>(Future<R> Function(T) mapper) async {
    return Future.wait(map((e) => mapper(e)));
  }

  ///
  /// Map all elements of the Iterable to a new Iterable with index information
  /// using an async function
  ///
  Future<Iterable<R>> mapIndexedAsync<R>(
    Future<R> Function(int index, T) mapper,
  ) async {
    return Future.wait(mapIndexed((index, e) => mapper(index, e)));
  }
}

extension Maximum<T> on Iterable<T> {
  ///
  /// Delivers the entry with the highest value, as extracted by the
  /// [comparableExtractor].
  /// No guarantee which element will be returned if there are multiple entries
  /// with the same value.
  ///
  T? maximum(Comparable Function(T) comparableExtractor) {
    if (isEmpty) {
      return null;
    }
    var maxElement = first;
    var maxValue = comparableExtractor(first);
    skip(1).forEach((element) {
      final candidateValue = comparableExtractor(element);
      if (candidateValue.compareTo(maxValue) > 0) {
        maxElement = element;
        maxValue = candidateValue;
      }
    });
    return maxElement;
  }

  ///
  /// Delivers the entry with the lowest value, as extracted by the
  /// [comparableExtractor].
  /// No guarantee which element will be returned if there are multiple entries
  /// with the same value.
  ///
  T? minimum(Comparable Function(T) comparableExtractor) {
    if (isEmpty) {
      return null;
    }
    var minElement = first;
    var minValue = comparableExtractor(first);
    skip(1).forEach((element) {
      final candidateValue = comparableExtractor(element);
      if (candidateValue.compareTo(minValue) < 0) {
        minElement = element;
        minValue = candidateValue;
      }
    });
    return minElement;
  }
}

extension Converting<T> on Iterable<T> {
  ///
  /// Creates a map built from the entries of `this` by calling the [keyBuilder]
  /// and [valueBuilder] function for each element.
  ///
  Map<R, S> toMap<R, S>({
    required R Function(T) keyBuilder,
    required S Function(T) valueBuilder,
  }) {
    final Map<R, S> ret = {};
    forEach((element) => ret[keyBuilder(element)] = valueBuilder(element));
    return ret;
  }

  ///
  /// Creates a map with the entries of `this` iterable as map values. Keys
  /// are computed using the [byKey] function. Greedy.
  ///
  Map<R, T> toMapValues<R>({required R Function(T) byKey}) {
    final Map<R, T> ret = {};
    forEach((element) => ret[byKey(element)] = element);
    return ret;
  }

  ///
  /// Creates a map with the entries of `this` iterable as map keys. Values are
  /// computed using the [createValue] function for each element. Greedy.
  ///
  Map<T, R> toMapKeys<R>({required R Function(T) createValue}) {
    final Map<T, R> ret = {};
    forEach((element) => ret[element] = createValue(element));
    return ret;
  }

  /// Creates a [Set] containing the value extracted from each element of this
  /// iterable by the [extractor] function.
  Set<E> toMappedSet<E>(E Function(T value) extractor) =>
      map(extractor).toSet();
}

extension Ranging on int {
  ///
  /// Creates a range list from `this` to [endExclusive], not containing
  /// [endExclusive] - as the name suggests. Can range up and down.
  ///
  /// Examples:
  /// ```dart
  /// 0.to(3) -> [0, 1, 2]
  /// 3.to(0) -> [3, 2, 1]
  /// ```
  ///
  /// Special case: If `this` and [endExclusive] are equal, the resulting list
  /// is EMPTY!
  /// ```dart
  /// 0.to(0) -> []
  /// ```
  ///
  Iterable<int> to(int endExclusive) {
    if (endExclusive == this) return [];
    if (this < endExclusive) {
      // range up
      return [for (int i = this; i < endExclusive; i++) i];
      // range down
    } else {
      return [for (int i = this; i > endExclusive; i--) i];
    }
  }
}

extension Repeating<T> on Iterable<T> {
  ///
  /// Creates a new List that contains the original content repeated
  /// **additionally** [times] times.
  ///
  /// [times] must be >=0. Values <0 will be clamped to 0 silently.
  ///
  /// Examples:
  /// ['a', 'b'].repeated(times: 1) => ['a', 'b', 'a', 'b']
  /// [1].repeated(times: 5) => [1, 1, 1, 1, 1, 1]
  ///
  /// Trivial cases:
  /// ['a'].repeated(times: 0) => ['a']
  /// [].repeated(times: 123) => []
  ///
  /// **NOTE** Performance considerations:
  /// The current implementation follows a naïve approach with no regard for
  /// runtime or memory performance. Rewrite if you required for larger lists
  /// or big [times]
  ///
  Iterable<T> repeated({required int times}) {
    if (isEmpty) return List<T>.empty();
    return [...this, for (var _ in 0.to(max(times, 0))) ...this];
  }
}

extension Interlacing<T> on Iterable<T> {
  ///
  /// Creates a new List that contains the original content but between each two
  /// elements, the [by] element is injected.
  /// [stepWidth] MUST be >= 1.
  ///
  /// Examples:
  /// ['a', 'b'].interlaced(by: 'x') => ['a', 'x', 'b']
  /// ['a', 'b', 'c', 'd'].interlaced(by: ':', stepWidth: 2)
  ///   => ['a', 'b', ':', 'c', 'd']
  ///
  /// Trivial cases:
  /// ['a'].interlaced(by: 'x') => ['a']
  /// [].interlaced(by: 'x') => []
  ///
  Iterable<T> interlaced({required T by, int stepWidth = 1}) {
    if (stepWidth < 1) {
      L.bug(
          'NOT interlacing $this with `$by`, and stepWidth `$stepWidth`: A StepWidth < 1 is not permitted');
      return this;
    }
    if (isEmpty) return this;
    final List<T> interlacedList = [first];
    skip(1).forEachIndexed((index, element) {
      if ((index - 1) % stepWidth == 0) {
        interlacedList.add(by);
      }
      interlacedList.add(element);
    });
    return interlacedList;
  }

  ///
  /// Creates a new List that contains the original content but at the start,
  /// end, and between each two elements, the [by] element is injected.
  ///
  /// Examples:
  /// ['a', 'b'].interlaced(by: 'x') => ['x', 'a', 'x', 'b', 'x']
  ///
  /// Trivial cases:
  /// ['a'].interlaced(by: 'x') => ['x', 'a', 'x']
  /// [].interlaced(by: 'x') => ['x']
  ///
  Iterable<T> wrapped({required T by}) {
    if (isEmpty) return [by];
    final List<T> wrappedList = [by];
    forEach((element) {
      wrappedList.add(element);
      wrappedList.add(by);
    });
    return wrappedList;
  }
}

extension BoolFolding on Iterable<bool> {
  ///
  /// True when the iterable is empty or all entries are `true`.
  ///
  bool allTrue() => none((it) => !it);
}
