import 'package:flutter/material.dart';
import 'package:logsnack/ui/main/lines/main_lines_view_model.dart';

class MainLinesWidget extends StatelessWidget {
  const MainLinesWidget({super.key, required this.viewModel});

  final MainLinesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: viewModel.lines.length,
        // prototypeItem: Text(
        //   'ProtoType|',
        //   maxLines: 1,
        //   style: TextStyle(
        //       fontFamily: 'JetBrainsMono', fontSize: 11, color: Colors.white),
        // ),
        itemBuilder: (context, index) {
          return SelectableText(
            '$index ${viewModel.lines[index].text}',
            maxLines: 1,
            scrollPhysics: ClampingScrollPhysics(),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 7 + index % 6,
              color: Colors.white,
            ),
          );
        });
  }
}
