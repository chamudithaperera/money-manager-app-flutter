import 'package:flutter/material.dart';

import '../core/theme/theme.dart';
import '../features/home/home_page.dart';
import '../features/splash/splash_screen.dart';

/// Root widget: shows splash then home.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _splashComplete = false;

  void _onSplashComplete() {
    setState(() => _splashComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Money Manager',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: _splashComplete
          ? const HomePage()
          : SplashScreen(onComplete: _onSplashComplete),
    );
  }
}
