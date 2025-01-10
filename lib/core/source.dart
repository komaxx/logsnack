import 'package:rxdart/rxdart.dart';

abstract class Source {
  ValueStream<Iterable<String>> get lines;
}

class DummySource implements Source {
  @override
  ValueStream<Iterable<String>> get lines => BehaviorSubject.seeded([]);
}
