import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import 'models/wallet.dart';
import 'providers/wallet_provider.dart';
import 'widgets/transfer_money_modal.dart';
import 'wallet_detail_page.dart';

class WalletsPage extends ConsumerWidget {
  const WalletsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final summaries = ref.watch(walletSummariesProvider);

    final summaryMap = {
      for (final item in summaries)
        if (item.wallet.id != null) item.wallet.id!: item,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text('Wallets', style: AppTextStyles.appTitle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateWalletDialog(context, ref),
                      icon: const Icon(Symbols.add),
                      label: const Text('Add Wallet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTransferModal(context),
                      icon: const Icon(Symbols.swap_horiz),
                      label: const Text('Transfer'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: walletsAsync.when(
                data: (wallets) {
                  if (wallets.isEmpty) {
                    return Center(
                      child: Text(
                        'No wallets available.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final walletId = wallet.id;
                      final summary = walletId == null
                          ? null
                          : summaryMap[walletId];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _walletCard(
                          context,
                          ref,
                          wallet: wallet,
                          balance: summary?.balance ?? 0,
                          income: summary?.income ?? 0,
                          expense: summary?.expense ?? 0,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Failed to load wallets',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.expense,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletCard(
    BuildContext context,
    WidgetRef ref, {
    required Wallet wallet,
    required double balance,
    required double income,
    required double expense,
  }) {
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: () {
        final walletId = wallet.id;
        if (walletId == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WalletDetailPage(walletId: walletId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(wallet.name, style: AppTextStyles.sectionHeader),
                      if (wallet.isDefault) ...[
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
                ),
                PopupMenuButton<String>(
                  color: AppColors.surfaceVariant,
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameWalletDialog(context, ref, wallet);
                        break;
                      case 'delete':
                        _confirmDeleteWallet(context, ref, wallet);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$currency ${balance.toStringAsFixed(2)}',
              style: AppTextStyles.summaryAmount.copyWith(
                color: balance >= 0 ? AppColors.primary : AppColors.expense,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Income: $currency ${income.toStringAsFixed(2)} • Expense: $currency ${expense.toStringAsFixed(2)}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateWalletDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();

    try {
      final created = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create Wallet'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Wallet Name',
              hintText: 'e.g., Bank Account',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (created != true) return;

      final name = controller.text.trim();
      if (name.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet name cannot be empty.')),
        );
        return;
      }

      await ref.read(walletsProvider.notifier).createWallet(name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create wallet: $error')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showRenameWalletDialog(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    final controller = TextEditingController(text: wallet.name);

    try {
      final updated = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Rename Wallet'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Wallet Name'),
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
        ),
      );

      if (updated != true) return;

      final walletId = wallet.id;
      final name = controller.text.trim();

      if (walletId == null) return;
      if (name.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet name cannot be empty.')),
        );
        return;
      }

      await ref
          .read(walletsProvider.notifier)
          .renameWallet(walletId: walletId, name: name);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rename wallet: $error')),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDeleteWallet(
    BuildContext context,
    WidgetRef ref,
    Wallet wallet,
  ) async {
    final walletId = wallet.id;
    if (walletId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete wallet?'),
        content: Text(
          'Transactions in "${wallet.name}" will be reassigned to the default wallet.',
        ),
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

    if (confirmed != true) return;

    try {
      await ref.read(walletsProvider.notifier).deleteWallet(walletId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete wallet: $error')),
      );
    }
  }

  void _showTransferModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.modalBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.modalTop),
        ),
      ),
      builder: (context) => const TransferMoneyModal(),
    );
  }
}
