import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/theme.dart';
import 'models/wishlist_item.dart';
import 'providers/wishlist_provider.dart';
import 'widgets/add_wishlist_modal.dart';
import 'widgets/wishlist_list_item.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text('Wishlist', style: AppTextStyles.appTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildAddButton(context, ref),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: wishlistAsync.when(
                data: (wishlistItems) {
                  if (wishlistItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No items in your wishlist yet.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  final grouped = <String, List<WishlistItem>>{};
                  for (final item in wishlistItems) {
                    final key = DateFormat(
                      'MMMM yyyy',
                    ).format(item.estimatedDate);
                    grouped.putIfAbsent(key, () => []).add(item);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final key = grouped.keys.elementAt(index);
                      final items = grouped[key]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              key,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: WishlistItemWidget(
                                item: item,
                                onLongPress: () =>
                                    _showItemActions(context, ref, item),
                                onTap: () =>
                                    _showAddSheet(context, ref, initial: item),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading wishlist: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddSheet(context, ref),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Symbols.add, size: 18, color: Colors.black),
        ),
        label: const Text('Add Wishlist Item'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          textStyle: AppTextStyles.buttonLabel.copyWith(color: Colors.black),
        ),
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref, {
    WishlistItem? initial,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.modalBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modalTop),
        ),
      ),
      builder: (context) {
        return AddWishlistModal(
          initial: initial,
          onSubmit: (data) {
            final item = WishlistItem(
              id: data.id,
              name: data.name,
              description: data.description,
              estimatedPrice: data.estimatedPrice,
              estimatedDate: data.estimatedDate,
            );
            final notifier = ref.read(wishlistProvider.notifier);
            if (data.id == null) {
              notifier.add(item);
            } else {
              notifier.updateItem(item);
            }
          },
        );
      },
    );
  }

  void _showItemActions(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.edit, color: AppColors.primary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddSheet(context, ref, initial: item);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.delete, color: AppColors.expense),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, ref, item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      ref.read(wishlistProvider.notifier).remove(item.id!);
    }
  }
}
