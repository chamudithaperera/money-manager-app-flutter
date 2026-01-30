import 'package:flutter/material.dart';

/// Dark fintech-inspired color palette for My Money Manager.
abstract final class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF121212);
  static const Color backgroundElevated = Color(0xFF1A1A1A);
  static const Color surface = Color(0xFF232323);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  // Primary accent (income, positive, primary CTA, active states)
  static const Color primary = Color(0xFF28C76F);
  static const Color primaryLight = Color(0xFF3DD97D);
  static const Color primaryDark = Color(0xFF1E9B57);

  // Expense / negative
  static const Color expense = Color(0xFFEA5455);
  static const Color expenseLight = Color(0xFFF06B6C);

  // Savings
  static const Color savings = Color(0xFF8B5CF6);
  static const Color savingsLight = Color(0xFFA78BFA);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF808080);

  // Icons & borders
  static const Color iconActive = Color(0xFF28C76F);
  static const Color iconInactive = Color(0xFF808080);
  static const Color border = Color(0xFF3D3D3D);

  // Profile / avatar
  static const Color avatarAccent = Color(0xFF00ADB5);

  // Progress bar
  static const Color progressTrack = Color(0xFF2C2C2C);
  static const Color progressFill = Color(0xFF28C76F);

  // Modal / overlay
  static const Color modalBackground = Color(0xFF1E1E1E);
  static const Color inputBackground = Color(0xFF2C2C2C);
}
