import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';

/// Empty home page shown after splash.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Home',
          style: AppTextStyles.sectionHeader.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
