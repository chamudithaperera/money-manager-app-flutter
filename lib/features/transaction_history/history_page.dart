import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../home/models/transaction.dart';
import '../home/widgets/activity_item.dart';
import '../wallets/models/wallet_transfer.dart';
import 'filter_bar.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.transactions,
    required this.transfers,
    required this.walletNameMap,
    required this.activeType,
    required this.onTypeChange,
    required this.activeDate,
    required this.onDateChange,
    required this.activeWalletId,
    required this.onWalletChange,
    required this.onTransactionTap,
    required this.onTransactionLongPress,
  });

  final List<Transaction> transactions;
  final List<WalletTransfer> transfers;
  final Map<int, String> walletNameMap;
  final TransactionType? activeType;
  final ValueChanged<TransactionType?> onTypeChange;
  final String activeDate;
  final ValueChanged<String> onDateChange;
  final int? activeWalletId;
  final ValueChanged<int?> onWalletChange;
  final ValueChanged<Transaction> onTransactionTap;
  final ValueChanged<Transaction> onTransactionLongPress;

  @override
  Widget build(BuildContext context) {
    final filtered = _buildFilteredEntries();
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
                  activeWalletId: activeWalletId,
                  onWalletChange: onWalletChange,
                  walletNameMap: walletNameMap,
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
                          for (final item in entry.value)
                            if (item.transaction != null)
                              ActivityItem(
                                transaction: item.transaction!,
                                walletName: walletNameMap[item.walletId!],
                                onTap: () =>
                                    onTransactionTap(item.transaction!),
                                onLongPress: () =>
                                    onTransactionLongPress(item.transaction!),
                              )
                            else
                              _TransferActivityItem(
                                transfer: item.transfer!,
                                walletNameMap: walletNameMap,
                                activeWalletId: activeWalletId,
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

  List<_HistoryEntry> _buildFilteredEntries() {
    final entries = <_HistoryEntry>[];

    for (final transaction in transactions) {
      final typeMatches = activeType == null || transaction.type == activeType;
      if (!typeMatches) continue;
      final walletMatches =
          activeWalletId == null || transaction.walletId == activeWalletId;
      if (!walletMatches) continue;
      if (!_matchesDateFilter(transaction.date, activeDate)) continue;

      entries.add(_HistoryEntry.transaction(transaction));
    }

    if (activeType == null) {
      for (final transfer in transfers) {
        final walletMatches =
            activeWalletId == null ||
            transfer.fromWalletId == activeWalletId ||
            transfer.toWalletId == activeWalletId;
        if (!walletMatches) continue;
        if (!_matchesDateFilter(transfer.date, activeDate)) continue;

        entries.add(_HistoryEntry.transfer(transfer));
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Map<DateTime, List<_HistoryEntry>> _groupByDate(List<_HistoryEntry> items) {
    final Map<DateTime, List<_HistoryEntry>> grouped = {};
    for (final item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <DateTime, List<_HistoryEntry>>{};
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

class _HistoryEntry {
  const _HistoryEntry._({required this.date, this.transaction, this.transfer});

  factory _HistoryEntry.transaction(Transaction tx) =>
      _HistoryEntry._(date: tx.date, transaction: tx);

  factory _HistoryEntry.transfer(WalletTransfer transfer) =>
      _HistoryEntry._(date: transfer.date, transfer: transfer);

  final DateTime date;
  final Transaction? transaction;
  final WalletTransfer? transfer;

  int? get walletId => transaction?.walletId;
}

class _TransferActivityItem extends StatelessWidget {
  const _TransferActivityItem({
    required this.transfer,
    required this.walletNameMap,
    required this.activeWalletId,
  });

  final WalletTransfer transfer;
  final Map<int, String> walletNameMap;
  final int? activeWalletId;

  @override
  Widget build(BuildContext context) {
    final fromWalletName =
        walletNameMap[transfer.fromWalletId] ??
        'Wallet #${transfer.fromWalletId}';
    final toWalletName =
        walletNameMap[transfer.toWalletId] ?? 'Wallet #${transfer.toWalletId}';
    final dateStr = _formatDate(transfer.date);

    final transferState = _stateForSelectedWallet();
    final title = switch (transferState) {
      _SelectedWalletTransferState.incoming => 'Transfer In',
      _SelectedWalletTransferState.outgoing => 'Transfer Out',
      _SelectedWalletTransferState.global => 'Wallet Transfer',
    };
    final subtitle = switch (transferState) {
      _SelectedWalletTransferState.incoming =>
        '$dateStr • From $fromWalletName',
      _SelectedWalletTransferState.outgoing => '$dateStr • To $toWalletName',
      _SelectedWalletTransferState.global =>
        '$dateStr • $fromWalletName → $toWalletName',
    };

    final icon = switch (transferState) {
      _SelectedWalletTransferState.incoming => Symbols.call_received,
      _SelectedWalletTransferState.outgoing => Symbols.call_made,
      _SelectedWalletTransferState.global => Symbols.swap_horiz,
    };
    final color = switch (transferState) {
      _SelectedWalletTransferState.incoming => AppColors.primary,
      _SelectedWalletTransferState.outgoing => AppColors.expense,
      _SelectedWalletTransferState.global => AppColors.savings,
    };
    final iconBg = switch (transferState) {
      _SelectedWalletTransferState.incoming => AppColors.primary.withValues(
        alpha: 0.1,
      ),
      _SelectedWalletTransferState.outgoing => AppColors.expense.withValues(
        alpha: 0.1,
      ),
      _SelectedWalletTransferState.global => AppColors.savings.withValues(
        alpha: 0.1,
      ),
    };
    final amountPrefix = switch (transferState) {
      _SelectedWalletTransferState.incoming => '+',
      _SelectedWalletTransferState.outgoing => '-',
      _SelectedWalletTransferState.global => '',
    };

    return Padding(
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
                    color: iconBg,
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
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.transactionTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
              '$amountPrefix${AppConstants.currencySymbol} ${transfer.amount.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.transactionAmount.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  _SelectedWalletTransferState _stateForSelectedWallet() {
    if (activeWalletId == null) {
      return _SelectedWalletTransferState.global;
    }

    if (transfer.toWalletId == activeWalletId) {
      return _SelectedWalletTransferState.incoming;
    }
    return _SelectedWalletTransferState.outgoing;
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
}

enum _SelectedWalletTransferState { incoming, outgoing, global }
