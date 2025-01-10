import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobi_app_2/util/logging/logging.dart';
import 'package:mobi_app_2/util/system.dart';

///
/// Defines one navigation transaction from one screen to another, encapsulating
/// the details required, like which screen will be shown and in which
/// [Navigator].
/// To be consumed by [FlowNavigator] objects.
///
/// By convention, should contain a static `push` function that triggers the
/// actual navigation, e.g.:
///
/// ``` dart
/// class FooNavigation extends Navigation {
///   static push(BuildContext context, String fooId) => Navigator.of(context)
///      .pushNamed("foo", arguments: FooNavigation._(fooId));
///   FooNavigation._(String fooId) : super((_) => Placeholder());
/// }
/// ```
///
/// Navigation is then triggered in some `onClick` function, BLoC or ViewModel
/// like this:
///
/// ``` dart
/// FooNavigation.push(context, "fooId");
/// ```
///
abstract class Navigation {
  final WidgetBuilder routeBuilder;
  final bool modal;

  Navigation(this.routeBuilder, {this.modal = false});
}

///
/// Stateless widget with a nested [Navigator] that establishes a custom way
/// navigation is defined:
/// The [FlowNavigator] can only be used in circumstances where navigation is
/// triggered via [Navigation] objects.
/// It utilizes the usual [Navigator.pushNamed] scheme - but does no awkward
/// pattern matching of route names and casting of arguments. Instead, the name
/// is ignored but the `arguments` MUST be a [Navigation] object. Generation of
/// a new route is then delegated to that object.
/// Back Navigation on Android is handled by a [PopScope].
///
class FlowNavigator extends StatelessWidget {
  final WidgetBuilder startBuilder;
  final navigatorKey = GlobalKey<NavigatorState>();

  FlowNavigator({required this.startBuilder});

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: navigatorKey.currentState?.canPop() ?? false,
        child: Navigator(
          initialRoute: '',
          key: navigatorKey,
          onGenerateRoute: (settings) => generateRoute(settings, startBuilder),
        ),
      );

  ///
  /// Creates a new [PageRoute] for a requested navigation.
  /// Expects [RouteSettings.arguments] to be a [Navigation] object; the content
  /// for the created PageRoute will be built by the navigation object.
  ///
  /// In case the settings parameter does not carry arguments (or the arguments
  /// are not of type [Navigation]), a route with the content created by
  /// [startBuilder] will be returned instead.
  ///
  static Route generateRoute(
    RouteSettings settings,
    WidgetBuilder startBuilder,
  ) {
    if (settings.arguments is Navigation) {
      final navigation = settings.arguments as Navigation;
      L.ua('-Navigating- $navigation');
      return _generateRouteWithBuilder(
        navigation.routeBuilder,
        modal: navigation.modal,
      );
    }

    return _generateRouteWithBuilder(startBuilder);
  }

  static Route _generateRouteWithBuilder(
    WidgetBuilder builder, {
    bool modal = false,
  }) {
    if (modal) {
      return RawDialogRoute(
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return builder(context);
        },
      );
    }

    if (System.isAndroid) {
      return MaterialPageRoute(builder: builder);
    } else {
      return CupertinoPageRoute(builder: builder);
    }
  }
}
