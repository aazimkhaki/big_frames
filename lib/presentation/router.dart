import 'package:flutter/material.dart';
import 'package:big_frames/presentation/screens/connections_screen.dart';

class AppRouter {
  static const String home = '/';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const ConnectionsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
