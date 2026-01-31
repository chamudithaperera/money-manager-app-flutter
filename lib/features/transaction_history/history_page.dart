import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../home/models/transaction.dart';
import '../home/widgets/activity_item.dart';
import 'filter_bar.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.transactions,
    required this.activeType,
    required this.onTypeChange,
    required this.activeDate,
    required this.onDateChange,
    required this.onTransactionLongPress,
  });

  final List<Transaction> transactions;
  final TransactionType? activeType;
  final ValueChanged<TransactionType?> onTypeChange;
  final String activeDate;
  final ValueChanged<String> onDateChange;
  final ValueChanged<Transaction> onTransactionLongPress;

  @override
  Widget build(BuildContext context) {
    // 1. Filter
    final filtered = transactions.where((transaction) {
      if (activeType == null) return true;
      return transaction.type == activeType;
    }).toList();

    // 2. Group and Flatten
    final flatList = _buildFlatList(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction History', style: AppTextStyles.appTitle),
              const SizedBox(height: 20),
              FilterBar(
                activeType: activeType,
                onTypeChange: onTypeChange,
                activeDate: activeDate,
                onDateChange: onDateChange,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (flatList.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No transactions found for this filter.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
              itemCount: flatList.length,
              itemBuilder: (context, index) {
                final item = flatList[index];
                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 8, top: 18),
                    child: Text(
                      item,
                      style: AppTextStyles.dateGroupHeader.copyWith(
                        letterSpacing: 1,
                      ),
                    ),
                  );
                } else if (item is Transaction) {
                  return ActivityItem(
                    transaction: item,
                    onLongPress: () => onTransactionLongPress(item),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
      ],
    );
  }

  List<Object> _buildFlatList(List<Transaction> items) {
    final Map<DateTime, List<Transaction>> grouped = {};
    for (final transaction in items) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(transaction);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final flatList = <Object>[];
    for (final key in sortedKeys) {
      flatList.add(_formatHeader(key));
      flatList.addAll(grouped[key]!);
    }
    return flatList;
  }

  String _formatHeader(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '${weekday.toUpperCase()}, ${month.toUpperCase()} ${date.day}';
  }
}
