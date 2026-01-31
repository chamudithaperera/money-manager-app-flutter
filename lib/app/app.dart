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
  bool _minSplashTimePassed = false;

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // Determines which screen to show
    Widget getScreen() {
      // 1. If explicitly stuck on splash (timer not done), show splash
      if (!_minSplashTimePassed) {
        return SplashScreen(
          onComplete: () {
            setState(() => _minSplashTimePassed = true);
          },
        );
      }

      // 2. Timer is done. Check if settings are loaded.
      return settingsAsync.when(
        data: (settings) {
          // Settings loaded. Check user name.
          if (settings.displayName == 'Your Name') {
            return const OnboardingPage();
          } else {
            return const HomePage();
          }
        },
        // If loading or error, keep showing splash (or a generic loader)
        // Since SplashScreen handles its own animation, we can just return it
        // passing a no-op callback or keeping the original one (it won't fire again if widget is rebuilt).
        // Actually, simpler: just return SplashScreen with a no-op if we are waiting for data but timer is done.
        loading: () => SplashScreen(onComplete: () {}),
        error: (_, __) => const HomePage(), // Fallback on error
      );
    }

    return MaterialApp(
      title: 'My Money Manager',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: getScreen(),
    );
  }
}
