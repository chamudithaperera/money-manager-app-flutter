import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../models/transaction.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
  });

  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCategory(transaction.category);
    final color = _amountColor(transaction.type);
    final prefix = switch (transaction.type) {
      TransactionType.income => '+',
      TransactionType.expense => '-',
      TransactionType.savingDeduct => '-',
      TransactionType.savings => '',
    };
    final dateStr = _formatDate(transaction.date);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.transactionTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr • ${transaction.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.transactionSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 132,
              child: Text(
                '$prefix${AppConstants.currencySymbol} ${transaction.amount.toStringAsFixed(2)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextStyles.transactionAmount.copyWith(color: color),
              ),
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
        return Symbols.work;
      case 'freelance':
        return Symbols.laptop;
      case 'food':
        return Symbols.shopping_bag;
      case 'housing':
        return Symbols.home;
      case 'investments':
        return Symbols.trending_up;
      default:
        return Symbols.attach_money;
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
      case TransactionType.savingDeduct:
        return Colors.orange;
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
      case TransactionType.savingDeduct:
        return Colors.orange.withValues(alpha: 0.12);
    }
  }
}
