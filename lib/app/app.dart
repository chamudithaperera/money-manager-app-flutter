import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/splash/splash_screen.dart';
import '../providers/settings_provider.dart';

/// Root widget: shows splash, then checks if onboarding is needed.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  _AppScreen _currentScreen = _AppScreen.splash;

  void _onSplashComplete() {
    final settings = ref.read(settingsProvider).asData?.value;
    // Check if name is the default 'Your Name'
    if (settings != null && settings.displayName == 'Your Name') {
      setState(() => _currentScreen = _AppScreen.onboarding);
    } else {
      setState(() => _currentScreen = _AppScreen.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Money Manager',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: switch (_currentScreen) {
        _AppScreen.splash => SplashScreen(onComplete: _onSplashComplete),
        _AppScreen.onboarding => const OnboardingPage(),
        _AppScreen.home => const HomePage(),
      },
    );
  }
}

enum _AppScreen { splash, onboarding, home }
