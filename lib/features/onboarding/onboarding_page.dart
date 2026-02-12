import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../home/home_page.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController();
  bool _canContinue = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _canContinue = _nameController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(settingsProvider.notifier).updateDisplayName(name);
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFF0D1A12), Color(0xFF0A0A0A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Symbols.person_pin_circle,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome!',
                  style: AppTextStyles.appTitle.copyWith(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Let\'s get to know you better.\nWhat should we call you?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  style: AppTextStyles.appTitle.copyWith(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Your Name',
                    hintStyle: AppTextStyles.appTitle.copyWith(
                      fontSize: 24,
                      color: AppColors.textTertiary.withValues(alpha: 0.3),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _canContinue ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.2,
                    ),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: _canContinue ? 4 : 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: _canContinue
                          ? Colors.black
                          : AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
