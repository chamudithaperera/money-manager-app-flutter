import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/theme.dart';
import '../home/models/transaction.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.activeType,
    required this.onTypeChange,
    required this.activeDate,
    required this.onDateChange,
    required this.activeWalletId,
    required this.onWalletChange,
    required this.walletNameMap,
  });

  final TransactionType? activeType;
  final ValueChanged<TransactionType?> onTypeChange;
  final String activeDate;
  final ValueChanged<String> onDateChange;
  final int? activeWalletId;
  final ValueChanged<int?> onWalletChange;
  final Map<int, String> walletNameMap;

  @override
  Widget build(BuildContext context) {
    final types = <_TypeChip>[
      const _TypeChip(label: 'All', type: null),
      const _TypeChip(label: 'Income', type: TransactionType.income),
      const _TypeChip(label: 'Expense', type: TransactionType.expense),
    ];

    final walletItems = walletNameMap.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    final activeWalletLabel = activeWalletId == null
        ? 'All Wallets'
        : (walletNameMap[activeWalletId] ?? 'Wallet #$activeWalletId');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<String>(
                initialValue: activeDate,
                color: AppColors.surface,
                onSelected: onDateChange,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'All Time', child: Text('All Time')),
                  PopupMenuItem(value: 'This Month', child: Text('This Month')),
                  PopupMenuItem(
                    value: 'Last 3 Months',
                    child: Text('Last 3 Months'),
                  ),
                  PopupMenuItem(value: 'This Year', child: Text('This Year')),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Symbols.calendar_month,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          activeDate,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.chipLabel.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Symbols.expand_more,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PopupMenuButton<int?>(
                initialValue: activeWalletId,
                color: AppColors.surface,
                onSelected: onWalletChange,
                itemBuilder: (context) => [
                  const PopupMenuItem<int?>(
                    value: null,
                    child: Text('All Wallets'),
                  ),
                  ...walletItems.map(
                    (entry) => PopupMenuItem<int?>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Symbols.account_balance_wallet,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          activeWalletLabel,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.chipLabel.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Symbols.expand_more,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: types.map((chip) {
              final isActive = chip.type == activeType;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onTypeChange(chip.type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                      border: Border.all(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.border.withValues(alpha: 0.4),
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      chip.label,
                      style: AppTextStyles.chipLabel.copyWith(
                        color: isActive
                            ? Colors.black
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TypeChip {
  const _TypeChip({required this.label, required this.type});

  final String label;
  final TransactionType? type;
}
