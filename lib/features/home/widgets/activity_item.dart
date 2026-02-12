import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../models/transaction.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({super.key, required this.transaction, this.onLongPress});

  final Transaction transaction;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(transaction.category);
    final color = _amountColor(transaction.type);
    final prefix = transaction.type == TransactionType.income
        ? '+'
        : transaction.type == TransactionType.expense
        ? '-'
        : '';
    final dateStr = _formatDate(transaction.date);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: () {},
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBg(transaction.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: AppTextStyles.transactionTitle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • ${transaction.category}',
                      style: AppTextStyles.transactionSubtitle,
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$prefix${AppConstants.currencySymbol} ${transaction.amount.toStringAsFixed(2)}',
              style: AppTextStyles.transactionAmount.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}';
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.work;
      case 'freelance':
        return Icons.laptop;
      case 'food':
        return Icons.shopping_bag;
      case 'housing':
        return Icons.home;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.attach_money;
    }
  }

  Color _amountColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.primary;
      case TransactionType.expense:
        return AppColors.textPrimary;
      case TransactionType.savings:
        return AppColors.savings;
    }
  }

  Color _iconBg(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return AppColors.primary.withValues(alpha: 0.1);
      case TransactionType.expense:
        return AppColors.expense.withValues(alpha: 0.1);
      case TransactionType.savings:
        return AppColors.savings.withValues(alpha: 0.1);
    }
  }
}
