import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../home/models/transaction.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.activeType,
    required this.onTypeChange,
    required this.activeDate,
    required this.onDateChange,
  });

  final TransactionType? activeType;
  final ValueChanged<TransactionType?> onTypeChange;
  final String activeDate;
  final ValueChanged<String> onDateChange;

  @override
  Widget build(BuildContext context) {
    final types = <_TypeChip>[
      const _TypeChip(label: 'All', type: null),
      const _TypeChip(label: 'Income', type: TransactionType.income),
      const _TypeChip(label: 'Expense', type: TransactionType.expense),
      const _TypeChip(label: 'Savings', type: TransactionType.savings),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                final newValue = activeDate == 'All' ? 'This Month' : 'All';
                onDateChange(newValue);
              },
              icon: const Icon(Icons.calendar_month, size: 16),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(activeDate),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more, size: 16),
                ],
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              color: AppColors.textTertiary,
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
