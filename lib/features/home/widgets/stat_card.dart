import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../providers/settings_provider.dart';
import '../models/transaction.dart';

class StatCard extends ConsumerWidget {
  const StatCard({super.key, required this.type, required this.amount});

  final TransactionType type;
  final double amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = _configFor(type);
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: config.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, size: 20, color: config.color),
          ),
          const SizedBox(height: 10),
          Text(config.label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            '$currency ${amount.toStringAsFixed(0)}',
            style: AppTextStyles.summaryAmount.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  _StatConfig _configFor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const _StatConfig(
          icon: Icons.trending_up,
          label: 'Income',
          color: AppColors.primary,
          bgColor: Color(0x1A28C76F),
        );
      case TransactionType.expense:
        return const _StatConfig(
          icon: Icons.trending_down,
          label: 'Expenses',
          color: AppColors.expense,
          bgColor: Color(0x1AEA5455),
        );
      case TransactionType.savings:
        return const _StatConfig(
          icon: Icons.savings,
          label: 'Savings',
          color: AppColors.savings,
          bgColor: Color(0x1A8B5CF6),
        );
      case TransactionType.savingDeduct:
        return const _StatConfig(
          icon: Icons.remove_circle,
          label: 'Deductions',
          color: AppColors.expense,
          bgColor: Color(0x1AEA5455),
        );
    }
  }
}

class _StatConfig {
  const _StatConfig({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
}
