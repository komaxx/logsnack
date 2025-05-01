import 'package:logsnack/core/dev_source.dart';

class MainLinesViewModel {
  List<LineViewData> lines =
      DevSource().lines.value.map((line) => LineViewData(line)).toList();
}

class LineViewData {
  LineViewData(this.text);

  final String text;
}
