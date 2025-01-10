import 'package:flutter/material.dart';
import 'package:logsnack/ui/main/lines/main_lines_view_model.dart';
import 'package:logsnack/ui/main/lines/main_lines_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final linesViewModel = MainLinesViewModel();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold
    (
      body: Stack(
        children: [
          Positioned.fill(
            child: MainLinesWidget(viewModel: linesViewModel),
          ),
        ],
      ),
    );
  }
}
