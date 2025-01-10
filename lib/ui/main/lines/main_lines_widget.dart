import 'package:flutter/material.dart';
import 'package:logsnack/ui/main/lines/main_lines_view_model.dart';

class MainLinesWidget extends StatelessWidget {
  const MainLinesWidget({super.key, required this.viewModel});

  final MainLinesViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: viewModel.lines.length,
      itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.0),
        child: Text(
          '${viewModel.lines[index].text}',
          style: TextStyle(fontFamily: 'JetBrainsMono'),
        ),
      );
    });
  }
}
