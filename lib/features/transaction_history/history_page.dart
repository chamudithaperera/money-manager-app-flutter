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
    required this.onTransactionTap,
    required this.onTransactionLongPress,
  });

  final List<Transaction> transactions;
  final TransactionType? activeType;
  final ValueChanged<TransactionType?> onTypeChange;
  final String activeDate;
  final ValueChanged<String> onDateChange;
  final ValueChanged<Transaction> onTransactionTap;
  final ValueChanged<Transaction> onTransactionLongPress;

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((transaction) {
      final typeMatches = activeType == null || transaction.type == activeType;
      if (!typeMatches) return false;
      return _matchesDateFilter(transaction.date, activeDate);
    }).toList();

    final grouped = _groupByDate(filtered);

    final groupedEntries = grouped.entries.toList();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          sliver: SliverToBoxAdapter(
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
        ),
        if (groupedEntries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No transactions found for this filter.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = groupedEntries[index];
                final dateHeader = _formatHeader(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 8),
                        child: Text(
                          dateHeader,
                          style: AppTextStyles.dateGroupHeader.copyWith(
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          for (final tx in entry.value)
                            ActivityItem(
                              transaction: tx,
                              onTap: () => onTransactionTap(tx),
                              onLongPress: () => onTransactionLongPress(tx),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: groupedEntries.length),
            ),
          ),
      ],
    );
  }

  bool _matchesDateFilter(DateTime date, String filter) {
    final now = DateTime.now();
    final dayOnly = DateTime(date.year, date.month, date.day);

    switch (filter) {
      case 'This Month':
      case 'Month':
        return dayOnly.year == now.year && dayOnly.month == now.month;
      case 'Last 3 Months':
        final start = DateTime(now.year, now.month - 2, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return !dayOnly.isBefore(start) && dayOnly.isBefore(end);
      case 'This Year':
        return dayOnly.year == now.year;
      case 'All':
      case 'All Time':
      default:
        return true;
    }
  }

  Map<DateTime, List<Transaction>> _groupByDate(List<Transaction> items) {
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
    final sorted = <DateTime, List<Transaction>>{};
    for (final key in sortedKeys) {
      sorted[key] = grouped[key]!;
    }
    return sorted;
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
