import 'package:logsnack/core/dev_source.dart';

class MainLinesViewModel {
  List<MainLineViewModel> lines = DevSource().lines.value.map((line) => MainLineViewModel(line)).toList();

}

class MainLineViewModel {
  MainLineViewModel(this.text);

  final String text;
}
