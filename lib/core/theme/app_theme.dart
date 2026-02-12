import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Main dark fintech theme for My Money Manager.
abstract final class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: _colorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.progressFill,
        linearTrackColor: AppColors.progressTrack,
        circularTrackColor: AppColors.progressTrack,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.modalBackground,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modalTop),
          ),
        ),
        dragHandleColor: AppColors.textTertiary,
        dragHandleSize: const Size(40, 4),
      ),
    );
  }

  static ColorScheme get _colorScheme {
    return const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.textPrimary,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.savings,
      onSecondary: AppColors.textPrimary,
      error: AppColors.expense,
      onError: AppColors.textPrimary,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.surface,
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      headlineLarge: AppTextStyles.balanceLarge,
      headlineMedium: AppTextStyles.sectionHeader,
      titleLarge: AppTextStyles.appTitle,
      titleMedium: AppTextStyles.modalTitle,
      titleSmall: AppTextStyles.transactionTitle,
      bodyLarge: AppTextStyles.inputText,
      bodyMedium: AppTextStyles.summaryLabel,
      bodySmall: AppTextStyles.transactionSubtitle,
      labelLarge: AppTextStyles.buttonLabel,
      labelMedium: AppTextStyles.formLabel,
      labelSmall: AppTextStyles.caption,
    );
  }

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppTextStyles.appTitle,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    );
  }

  static CardThemeData get _cardTheme {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        textStyle: AppTextStyles.buttonLabel,
      ),
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.expense),
      ),
      hintStyle: AppTextStyles.placeholder,
      labelStyle: AppTextStyles.formLabel,
    );
  }

  static ChipThemeData get _chipTheme {
    return ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      labelStyle: AppTextStyles.chipLabel.copyWith(
        color: AppColors.textSecondary,
      ),
      secondaryLabelStyle: AppTextStyles.chipLabel.copyWith(
        color: AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
    );
  }

  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.iconInactive,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }
}
