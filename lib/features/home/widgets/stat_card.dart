import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../models/transaction.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.type, required this.amount});

  final TransactionType type;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(type);

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
          Text(
            config.label,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${AppConstants.currencySymbol} ${amount.toStringAsFixed(0)}',
              style: AppTextStyles.summaryAmount.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  _StatConfig _configFor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return const _StatConfig(
          icon: Symbols.trending_up,
          label: 'Income',
          color: AppColors.primary,
          bgColor: Color(0x1A28C76F),
        );
      case TransactionType.expense:
        return const _StatConfig(
          icon: Symbols.trending_down,
          label: 'Expenses',
          color: AppColors.expense,
          bgColor: Color(0x1AEA5455),
        );
      case TransactionType.savings:
        return const _StatConfig(
          icon: Symbols.savings,
          label: 'Savings',
          color: AppColors.savings,
          bgColor: Color(0x1A8B5CF6),
        );
      case TransactionType.savingDeduct:
        return const _StatConfig(
          icon: Symbols.money_off,
          label: 'Saving Deduct',
          color: Colors.orange,
          bgColor: Color(0x1AFFA726),
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
