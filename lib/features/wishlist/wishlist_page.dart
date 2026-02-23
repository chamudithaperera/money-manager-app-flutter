import 'package:flutter/material.dart';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
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

                  final planned =
                      wishlistItems.where((item) => !item.isCompleted).toList()
                        ..sort(
                          (a, b) => a.estimatedDate.compareTo(b.estimatedDate),
                        );
                  final completed =
                      wishlistItems.where((item) => item.isCompleted).toList()
                        ..sort((a, b) {
                          final aDate = a.completedDate ?? a.estimatedDate;
                          final bDate = b.completedDate ?? b.estimatedDate;
                          return bDate.compareTo(aDate);
                        });

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                    children: [
                      if (planned.isNotEmpty) ...[
                        _sectionTitle('Planned Items'),
                        const SizedBox(height: 10),
                        ...planned.map(
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
                      if (completed.isNotEmpty) ...[
                        if (planned.isNotEmpty) const SizedBox(height: 14),
                        _sectionTitle('Completed Items'),
                        const SizedBox(height: 10),
                        ...completed.map(
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
                    ],
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

  Widget _sectionTitle(String label) {
    return Text(
      label,
      style: AppTextStyles.sectionHeader.copyWith(fontSize: 17),
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
              isCompleted: initial?.isCompleted ?? false,
              realCost: initial?.realCost,
              completedDate: initial?.completedDate,
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
                leading: Icon(
                  item.isCompleted ? Symbols.restart_alt : Symbols.task_alt,
                  color: AppColors.primary,
                ),
                title: Text(
                  item.isCompleted ? 'Edit Completion' : 'Mark as Completed',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCompletionDialog(context, ref, item);
                },
              ),
              if (item.isCompleted)
                ListTile(
                  leading: const Icon(
                    Symbols.undo,
                    color: AppColors.textSecondary,
                  ),
                  title: const Text('Mark as Pending'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (item.id != null) {
                      ref.read(wishlistProvider.notifier).markPending(item.id!);
                    }
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

  Future<void> _showCompletionDialog(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) async {
    final currency =
        ref.read(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;
    final amountController = TextEditingController(
      text: (item.realCost ?? item.estimatedPrice).toStringAsFixed(2),
    );
    DateTime completedDate = item.completedDate ?? DateTime.now();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dateLabel = DateFormat('MMM d, yyyy').format(completedDate);
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              item.isCompleted ? 'Edit Completion' : 'Mark as Completed',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Real Cost',
                    prefixText: '$currency ',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: completedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() => completedDate = picked);
                    }
                  },
                  icon: const Icon(Symbols.calendar_month),
                  label: Text('Completed Date: $dateLabel'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    final parsed = double.tryParse(amountController.text.trim());
    amountController.dispose();

    if (shouldSave != true) return;
    if (parsed == null || parsed < 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid real cost.')),
      );
      return;
    }

    final id = item.id;
    if (id == null) return;

    await ref
        .read(wishlistProvider.notifier)
        .markCompleted(id: id, realCost: parsed, completedDate: completedDate);
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
