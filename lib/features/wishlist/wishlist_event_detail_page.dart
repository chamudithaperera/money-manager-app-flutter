import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import 'models/wishlist_item.dart';
import 'providers/wishlist_provider.dart';
import 'widgets/add_wishlist_event_modal.dart';
import 'widgets/add_wishlist_modal.dart';
import 'widgets/wishlist_list_item.dart';

class WishlistEventDetailPage extends ConsumerWidget {
  const WishlistEventDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final currency = _currency(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: wishlistAsync.when(
          data: (events) {
            final eventData = findWishlistEventById(events, eventId);
            return Text(eventData?.event.name ?? 'Wishlist Event');
          },
          loading: () => const Text('Wishlist Event'),
          error: (_, _) => const Text('Wishlist Event'),
        ),
        actions: [
          IconButton(
            onPressed: () => _showEventActions(context, ref),
            icon: const Icon(Symbols.more_vert),
          ),
        ],
      ),
      body: SafeArea(
        child: wishlistAsync.when(
          data: (events) {
            final eventData = findWishlistEventById(events, eventId);
            if (eventData == null) {
              return Center(
                child: Text(
                  'This event no longer exists.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final items = eventData.items;
            final planned = items.where((item) => !item.isCompleted).toList();
            final completed = items.where((item) => item.isCompleted).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: _eventTotalCard(
                    currency: currency,
                    total: eventData.totalPrice,
                    itemCount: items.length,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddItemSheet(context, ref),
                      icon: const Icon(Symbols.add_shopping_cart, size: 18),
                      label: const Text('Add Wishlist Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'No items in this event yet.',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView(
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
                                        _showItemActions(context, ref, item),
                                  ),
                                ),
                              ),
                            ],
                            if (completed.isNotEmpty) ...[
                              if (planned.isNotEmpty)
                                const SizedBox(height: 14),
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
                                        _showItemActions(context, ref, item),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error loading event: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
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

  Widget _eventTotalCard({
    required String currency,
    required double total,
    required int itemCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F4C35), Color(0xFF123D2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Event Cost',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currency ${total.toStringAsFixed(2)}',
            style: AppTextStyles.balanceLarge.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount item${itemCount == 1 ? '' : 's'}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _currency(WidgetRef ref) {
    return ref.read(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;
  }

  void _showAddItemSheet(
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
              eventId: eventId,
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
              notifier.addItem(item);
            } else {
              notifier.updateItem(item);
            }
          },
        );
      },
    );
  }

  Future<void> _showEventActions(BuildContext context, WidgetRef ref) async {
    final wishlist = ref.read(wishlistProvider).asData?.value;
    final eventData = wishlist == null
        ? null
        : findWishlistEventById(wishlist, eventId);
    if (eventData == null) return;

    final action = await showModalBottomSheet<_WishlistEventSheetAction>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.edit, color: AppColors.primary),
                title: const Text('Edit Event'),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_WishlistEventSheetAction.edit),
              ),
              ListTile(
                leading: const Icon(Symbols.delete, color: AppColors.expense),
                title: const Text('Delete Event'),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_WishlistEventSheetAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;

    if (action == _WishlistEventSheetAction.edit) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.modalBackground,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modalTop),
          ),
        ),
        builder: (_) {
          return AddWishlistEventModal(
            initialName: eventData.event.name,
            onSubmit: (name) {
              ref
                  .read(wishlistProvider.notifier)
                  .updateEventName(eventId: eventId, name: name);
            },
          );
        },
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete event?'),
        content: const Text(
          'All wishlist items in this event will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(wishlistProvider.notifier).removeEvent(eventId);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showItemActions(
    BuildContext pageContext,
    WidgetRef ref,
    WishlistItem item,
  ) {
    return showModalBottomSheet<_WishlistSheetAction>(
      context: pageContext,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final estimatedDate = DateFormat(
          'MMM d, yyyy',
        ).format(item.estimatedDate);
        final completedDate = item.completedDate == null
            ? null
            : DateFormat('MMM d, yyyy').format(item.completedDate!);
        final status = item.isCompleted ? 'Completed' : 'Pending';
        final shownCost = item.realCost ?? item.estimatedPrice;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wishlist Item Details',
                  style: AppTextStyles.sectionHeader,
                ),
                const SizedBox(height: 12),
                _wishlistDetailRow('Name', item.name),
                _wishlistDetailRow('Description', item.description),
                _wishlistDetailRow('Status', status),
                _wishlistDetailRow('Estimated Date', estimatedDate),
                _wishlistDetailRow(
                  item.isCompleted ? 'Real Cost' : 'Estimated Cost',
                  '${_currency(ref)} ${shownCost.toStringAsFixed(2)}',
                ),
                if (item.isCompleted && completedDate != null)
                  _wishlistDetailRow('Completed Date', completedDate),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Symbols.edit, color: AppColors.primary),
                  title: const Text('Edit'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_WishlistSheetAction.edit),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.isCompleted ? Symbols.restart_alt : Symbols.task_alt,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    item.isCompleted ? 'Edit Completion' : 'Mark as Completed',
                  ),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_WishlistSheetAction.complete),
                ),
                if (item.isCompleted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Symbols.undo,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text('Mark as Pending'),
                    onTap: () => Navigator.of(
                      sheetContext,
                    ).pop(_WishlistSheetAction.pending),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Symbols.delete, color: AppColors.expense),
                  title: const Text('Delete'),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_WishlistSheetAction.delete),
                ),
              ],
            ),
          ),
        );
      },
    ).then((action) async {
      if (!pageContext.mounted || action == null) return;
      switch (action) {
        case _WishlistSheetAction.edit:
          _showAddItemSheet(pageContext, ref, initial: item);
          break;
        case _WishlistSheetAction.complete:
          await _showCompletionSheet(pageContext, ref, item);
          break;
        case _WishlistSheetAction.pending:
          final id = item.id;
          if (id != null) {
            await ref.read(wishlistProvider.notifier).markPending(id);
          }
          break;
        case _WishlistSheetAction.delete:
          await _confirmDeleteItem(pageContext, ref, item);
          break;
      }
    });
  }

  Widget _wishlistDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Future<void> _showCompletionSheet(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) async {
    final currency = _currency(ref);
    final amountController = TextEditingController(
      text: (item.realCost ?? item.estimatedPrice).toStringAsFixed(2),
    );
    DateTime selectedDate = item.completedDate ?? DateTime.now();

    try {
      final result = await showModalBottomSheet<_WishlistCompletionResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.modalBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.modalTop),
          ),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              final dateLabel = DateFormat('MMM d, yyyy').format(selectedDate);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isCompleted
                              ? 'Edit Completion'
                              : 'Mark as Completed',
                          style: AppTextStyles.modalTitle,
                        ),
                        const SizedBox(height: 14),
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
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null && sheetContext.mounted) {
                              setSheetState(() => selectedDate = picked);
                            }
                          },
                          icon: const Icon(Symbols.calendar_month),
                          label: Text('Completed Date: $dateLabel'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final parsed = double.tryParse(
                                    amountController.text.trim(),
                                  );
                                  if (parsed == null || parsed < 0) {
                                    ScaffoldMessenger.of(
                                      sheetContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter a valid real cost.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(sheetContext).pop(
                                    _WishlistCompletionResult(
                                      realCost: parsed,
                                      completedDate: selectedDate,
                                    ),
                                  );
                                },
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (result == null) return;
      final id = item.id;
      if (id == null) return;

      await ref
          .read(wishlistProvider.notifier)
          .markCompleted(
            id: id,
            realCost: result.realCost,
            completedDate: result.completedDate,
          );
    } finally {
      amountController.dispose();
    }
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    WidgetRef ref,
    WishlistItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      await ref.read(wishlistProvider.notifier).removeItem(item.id!);
    }
  }
}

enum _WishlistEventSheetAction { edit, delete }

enum _WishlistSheetAction { edit, complete, pending, delete }

class _WishlistCompletionResult {
  const _WishlistCompletionResult({
    required this.realCost,
    required this.completedDate,
  });

  final double realCost;
  final DateTime completedDate;
}
