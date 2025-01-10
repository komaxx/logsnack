import 'package:flutter/material.dart';
import 'package:logsnack/ui/main/main_screen.dart';
import 'package:logsnack/util/flow_navigator.dart';

///
/// Root widget of the app.
/// Initializations go in here.
///
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogSnack',
      initialRoute: '/',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      onGenerateRoute: (settings) => FlowNavigator.generateRoute(
        settings,
        startBuilder: (_) => MainScreen(),
      ),
    );
  }
}
