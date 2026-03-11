import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import 'providers/wishlist_provider.dart';
import 'widgets/add_wishlist_event_modal.dart';
import 'wishlist_event_detail_page.dart';

class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final currency = _currency(ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Text('Wishlist Events', style: AppTextStyles.appTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Create events like "April Trip" and add related wishlist items inside each event.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildAddEventButton(context, ref),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: wishlistAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        'No wishlist events yet.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final eventData = events[index];
                      return _eventCard(
                        context: context,
                        ref: ref,
                        eventData: eventData,
                        currency: currency,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading wishlist events: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEventButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddEventSheet(context, ref),
        icon: const Icon(Symbols.event_available, size: 18),
        label: const Text('Add Wishlist Event'),
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

  Widget _eventCard({
    required BuildContext context,
    required WidgetRef ref,
    required WishlistEventData eventData,
    required String currency,
  }) {
    final eventId = eventData.event.id;
    final createdLabel = DateFormat(
      'MMM d, yyyy',
    ).format(eventData.event.createdAt);
    final plannedCount = eventData.pendingCount;
    final completedCount = eventData.completedCount;

    return InkWell(
      onTap: eventId == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WishlistEventDetailPage(eventId: eventId),
              ),
            ),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.event_note, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventData.event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionHeader.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created $createdLabel',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$plannedCount planned • $completedCount completed',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ${eventData.totalPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.transactionAmount.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  onPressed: eventId == null
                      ? null
                      : () => _showEventActions(context, ref, eventData),
                  icon: const Icon(Symbols.more_horiz),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _currency(WidgetRef ref) {
    return ref.read(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;
  }

  void _showAddEventSheet(BuildContext context, WidgetRef ref) {
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
          onSubmit: (name) async {
            final newEventId = await ref
                .read(wishlistProvider.notifier)
                .addEvent(name);
            if (newEventId != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WishlistEventDetailPage(eventId: newEventId),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showEventActions(
    BuildContext context,
    WidgetRef ref,
    WishlistEventData eventData,
  ) async {
    final action = await showModalBottomSheet<_WishlistEventAction>(
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
                leading: const Icon(Symbols.open_in_new),
                title: const Text('Open Event'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_WishlistEventAction.open),
              ),
              ListTile(
                leading: const Icon(Symbols.edit, color: AppColors.primary),
                title: const Text('Edit Event'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_WishlistEventAction.edit),
              ),
              ListTile(
                leading: const Icon(Symbols.delete, color: AppColors.expense),
                title: const Text('Delete Event'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_WishlistEventAction.delete),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) return;
    final eventId = eventData.event.id;
    if (eventId == null) return;

    if (action == _WishlistEventAction.open) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WishlistEventDetailPage(eventId: eventId),
        ),
      );
      return;
    }

    if (action == _WishlistEventAction.edit) {
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
    }
  }
}

enum _WishlistEventAction { open, edit, delete }
