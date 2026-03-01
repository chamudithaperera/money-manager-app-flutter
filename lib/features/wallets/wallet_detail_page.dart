import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_providers.dart';
import '../home/models/transaction.dart';
import 'models/wallet.dart';
import 'models/wallet_transfer.dart';
import 'providers/wallet_provider.dart';
import 'providers/wallet_transfer_provider.dart';

class WalletDetailPage extends ConsumerWidget {
  const WalletDetailPage({super.key, required this.walletId});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final walletNameMap = ref.watch(walletNameMapProvider);
    final summaries = ref.watch(walletSummariesProvider);
    final transactions = ref.watch(transactionsProvider).value ?? const [];
    final transfers = ref.watch(walletTransfersProvider).value ?? const [];
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    final wallet = _findWallet(wallets);
    if (wallet == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Wallet Details')),
        body: Center(
          child: Text(
            'Wallet not found.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final summary = _findSummary(summaries);
    final activities = _buildActivities(
      walletId: walletId,
      transactions: transactions,
      transfers: transfers,
      walletNameMap: walletNameMap,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(wallet.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(summary, wallet.isDefault, currency),
            const SizedBox(height: 16),
            _buildSummaryRow(summary, currency),
            const SizedBox(height: 18),
            Text('Activity', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            if (activities.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'No activity for this wallet yet.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...activities.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.isPositive
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.expense.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 19,
                          color: item.isPositive
                              ? AppColors.primary
                              : AppColors.expense,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: AppTextStyles.transactionTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: AppTextStyles.transactionSubtitle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.isPositive ? '+' : '-'}$currency ${item.amount.toStringAsFixed(2)}',
                            style: AppTextStyles.transactionAmount.copyWith(
                              color: item.isPositive
                                  ? AppColors.primary
                                  : AppColors.expense,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(item.date),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  WalletSummary? _findSummary(List<WalletSummary> summaries) {
    for (final summary in summaries) {
      if (summary.wallet.id == walletId) return summary;
    }
    return null;
  }

  Wallet? _findWallet(List<Wallet> wallets) {
    for (final wallet in wallets) {
      if (wallet.id == walletId) return wallet;
    }
    return null;
  }

  Widget _buildHeaderCard(
    WalletSummary? summary,
    bool isDefault,
    String currency,
  ) {
    final balance = summary?.balance ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Wallet Balance', style: AppTextStyles.sectionLabel),
              if (isDefault) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Default',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$currency ${balance.toStringAsFixed(2)}',
            style: AppTextStyles.balanceLarge.copyWith(
              color: balance >= 0 ? AppColors.primary : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(WalletSummary? summary, String currency) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            label: 'Income',
            amount: summary?.income ?? 0,
            currency: currency,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryTile(
            label: 'Expense',
            amount: summary?.expense ?? 0,
            currency: currency,
            color: AppColors.expense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryTile(
            label: 'Net Flow',
            amount: (summary?.income ?? 0) - (summary?.expense ?? 0),
            currency: currency,
            color: AppColors.savings,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String label,
    required double amount,
    required String currency,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            '$currency${amount.toStringAsFixed(0)}',
            style: AppTextStyles.summaryAmount.copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<_WalletActivityEntry> _buildActivities({
    required int walletId,
    required List<Transaction> transactions,
    required List<WalletTransfer> transfers,
    required Map<int, String> walletNameMap,
  }) {
    final activities = <_WalletActivityEntry>[];

    for (final tx in transactions) {
      if (tx.walletId != walletId) continue;

      final isPositive = tx.type == TransactionType.income;
      final amount = tx.amount;
      final icon = switch (tx.type) {
        TransactionType.income => Symbols.trending_up,
        TransactionType.expense => Symbols.trending_down,
      };

      activities.add(
        _WalletActivityEntry(
          date: tx.date,
          title: tx.title,
          subtitle: '${_typeLabel(tx.type)} • ${tx.category}',
          amount: amount,
          isPositive: isPositive,
          icon: icon,
        ),
      );
    }

    for (final transfer in transfers) {
      if (transfer.fromWalletId != walletId &&
          transfer.toWalletId != walletId) {
        continue;
      }

      final isIncoming = transfer.toWalletId == walletId;
      final otherWalletId = isIncoming
          ? transfer.fromWalletId
          : transfer.toWalletId;
      final otherWalletName =
          walletNameMap[otherWalletId] ?? 'Wallet #$otherWalletId';

      activities.add(
        _WalletActivityEntry(
          date: transfer.date,
          title: isIncoming ? 'Transfer In' : 'Transfer Out',
          subtitle: isIncoming
              ? 'From $otherWalletName'
              : 'To $otherWalletName',
          amount: transfer.amount,
          isPositive: isIncoming,
          icon: isIncoming ? Symbols.call_received : Symbols.call_made,
        ),
      );
    }

    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  String _typeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
    };
  }

  String _formatDate(DateTime date) {
    final month = _monthName(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _monthName(int month) {
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
    return months[month - 1];
  }
}

class _WalletActivityEntry {
  const _WalletActivityEntry({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isPositive,
    required this.icon,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final bool isPositive;
  final IconData icon;
}
