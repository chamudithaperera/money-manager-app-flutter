import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme.dart';
import '../../../providers/settings_provider.dart';
import '../models/wishlist_item.dart';

class WishlistItemWidget extends ConsumerWidget {
  const WishlistItemWidget({
    super.key,
    required this.item,
    this.onLongPress,
    this.onTap,
  });

  final WishlistItem item;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    final dateStr = _formatDate(item.estimatedDate);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTextStyles.transactionTitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr • ${item.description}',
                          style: AppTextStyles.transactionSubtitle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$currency ${item.estimatedPrice.toStringAsFixed(2)}',
              style: AppTextStyles.transactionAmount.copyWith(
                color: AppColors.textPrimary,
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
}
