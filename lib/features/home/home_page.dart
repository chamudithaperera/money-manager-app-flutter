import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../features/wallets/models/wallet_transfer.dart';
import '../../features/wallets/providers/wallet_provider.dart';
import '../../features/wallets/providers/wallet_transfer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../profile/profile_page.dart';
import '../transaction_history/history_page.dart';
import '../wallets/wallets_page.dart';
import '../wishlist/wishlist_page.dart';
import 'models/transaction.dart';
import 'widgets/activity_item.dart';
import 'widgets/add_transaction_modal.dart';
import 'widgets/balance_card.dart';
import 'widgets/stat_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  BottomTab _activeTab = BottomTab.home;
  TransactionType? _filterType;
  String _dateFilter = 'All Time';
  int? _walletFilterId;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final transfers = ref.watch(walletTransfersProvider).value ?? const [];
    final walletNameMap = ref.watch(walletNameMapProvider);
    final regularSummaries = ref.watch(regularWalletSummariesProvider);

    final regularIncome = regularSummaries.fold<double>(
      0,
      (sum, item) => sum + item.income,
    );
    final regularExpense = regularSummaries.fold<double>(
      0,
      (sum, item) => sum + item.expense,
    );
    final savingsBalance = ref.watch(savingsBalanceProvider);
    final totalBalance = ref.watch(totalRegularWalletBalanceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: transactionsAsync.when(
                data: (items) {
                  if (_activeTab == BottomTab.home) {
                    return _buildHome(
                      items: items,
                      walletNameMap: walletNameMap,
                      totalBalance: totalBalance,
                      income: regularIncome,
                      expense: regularExpense,
                      savings: savingsBalance,
                    );
                  }
                  if (_activeTab == BottomTab.history) {
                    return _buildHistory(items, transfers, walletNameMap);
                  }
                  if (_activeTab == BottomTab.wallets) {
                    return _buildWallets();
                  }
                  if (_activeTab == BottomTab.wishlist) {
                    return _buildWishlist();
                  }
                  return _buildProfile(items);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Failed to load transactions',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          BottomNav(
            activeTab: _activeTab,
            onTabChange: (tab) => setState(() => _activeTab = tab),
          ),
        ],
      ),
    );
  }

  Widget _buildHome({
    required List<Transaction> items,
    required Map<int, String> walletNameMap,
    required double totalBalance,
    required double income,
    required double expense,
    required double savings,
  }) {
    final recentTransactions = items.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          BalanceCard(
            balance: totalBalance,
            income: income,
            expenses: expense,
            savings: savings,
            onTap: _showWalletBalances,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Income',
                  amount: income,
                  icon: Symbols.trending_up,
                  color: AppColors.primary,
                  bgColor: const Color(0x1A28C76F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Expenses',
                  amount: expense,
                  icon: Symbols.trending_down,
                  color: AppColors.expense,
                  bgColor: const Color(0x1AEA5455),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Savings',
                  amount: savings,
                  icon: Symbols.savings,
                  color: AppColors.savings,
                  bgColor: const Color(0x1A8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAddButton(),
          const SizedBox(height: 24),
          _buildRecentHeader(),
          const SizedBox(height: 8),
          Column(
            children: [
              for (final tx in recentTransactions)
                ActivityItem(
                  transaction: tx,
                  walletName: walletNameMap[tx.walletId],
                  onTap: () => _showTransactionDetails(tx),
                  onLongPress: () => _showTransactionActions(tx),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.asData?.value;

    final displayName = settings?.displayName ?? AppConstants.userDisplayName;
    final initials = settings?.initials ?? AppConstants.userInitials;
    final imagePath = settings?.profileImagePath;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Money Manager', style: AppTextStyles.appTitle),
            const SizedBox(height: 4),
            Text('Welcome back, $displayName', style: AppTextStyles.welcome),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.savings],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            child: imagePath != null
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Text(
                      initials,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(
                    initials,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showAddSheet(),
        icon: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Symbols.add, size: 18, color: Colors.black),
        ),
        label: const Text('Add Transaction'),
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

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Recent Activity', style: AppTextStyles.sectionHeader),
        TextButton(
          onPressed: () => setState(() => _activeTab = BottomTab.history),
          child: Text('See All', style: AppTextStyles.link),
        ),
      ],
    );
  }

  Widget _buildHistory(
    List<Transaction> items,
    List<WalletTransfer> transfers,
    Map<int, String> walletNameMap,
  ) {
    return HistoryPage(
      transactions: items,
      transfers: transfers,
      walletNameMap: walletNameMap,
      activeType: _filterType,
      onTypeChange: (type) => setState(() => _filterType = type),
      activeDate: _dateFilter,
      onDateChange: (date) => setState(() => _dateFilter = date),
      activeWalletId: _walletFilterId,
      onWalletChange: (walletId) => setState(() => _walletFilterId = walletId),
      onTransactionTap: _showTransactionDetails,
      onTransactionLongPress: _showTransactionActions,
    );
  }

  Widget _buildProfile(List<Transaction> items) {
    return ProfilePage(transactions: items);
  }

  Widget _buildWallets() {
    return const WalletsPage();
  }

  Widget _buildWishlist() {
    return const WishlistPage();
  }

  void _showAddSheet({Transaction? initial}) {
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
        return AddTransactionModal(
          initial: initial,
          onSubmit: (data) {
            final transaction = Transaction(
              id: data.id,
              walletId: data.walletId,
              title: data.description,
              category: data.category,
              type: data.type,
              amount: data.amount,
              date: data.date,
            );
            final notifier = ref.read(transactionsProvider.notifier);
            if (transaction.id == null) {
              notifier.add(transaction);
            } else {
              notifier.updateTransaction(transaction);
            }
          },
        );
      },
    );
  }

  void _showTransactionActions(Transaction transaction) {
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
                  _showAddSheet(initial: transaction);
                },
              ),
              ListTile(
                leading: const Icon(Symbols.delete, color: AppColors.expense),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTransactionDetails(Transaction transaction) async {
    final currency =
        ref.read(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;
    final dateText = _formatDateTime(transaction.date);
    final walletName = _walletLabel(transaction.walletId);
    final amountPrefix = switch (transaction.type) {
      TransactionType.income => '+',
      TransactionType.expense => '-',
    };

    final action = await showModalBottomSheet<_TransactionDetailAction>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction Details', style: AppTextStyles.sectionHeader),
                const SizedBox(height: 14),
                _detailRow('Title', transaction.title),
                _detailRow('Category', transaction.category),
                _detailRow('Type', _typeLabel(transaction.type)),
                _detailRow('Wallet', walletName),
                _detailRow('Date', dateText),
                _detailRow(
                  'Amount',
                  '$amountPrefix$currency ${transaction.amount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(
                          sheetContext,
                        ).pop(_TransactionDetailAction.edit),
                        icon: const Icon(Symbols.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.expense,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(
                          sheetContext,
                        ).pop(_TransactionDetailAction.delete),
                        icon: const Icon(Symbols.delete),
                        label: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _TransactionDetailAction.edit:
        _showAddSheet(initial: transaction);
        break;
      case _TransactionDetailAction.delete:
        await _confirmDelete(transaction);
        break;
    }
  }

  String _typeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.income => 'Income',
      TransactionType.expense => 'Expense',
    };
  }

  String _formatDateTime(DateTime date) {
    final month = _monthName(date.month);
    final minute = date.minute.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    return '$month ${date.day}, ${date.year} $hour:$minute';
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _walletLabel(int walletId) {
    final walletMap = ref.read(walletNameMapProvider);
    return walletMap[walletId] ?? 'Wallet #$walletId';
  }

  Future<void> _showWalletBalances() async {
    await ref.read(walletsProvider.future);
    await ref.read(walletTransfersProvider.future);
    if (!mounted) return;

    final regularWalletSummaries = ref.read(regularWalletSummariesProvider);
    final savingWalletSummary = ref.read(savingWalletSummaryProvider);
    final currency =
        ref.read(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    if (regularWalletSummaries.isEmpty && savingWalletSummary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No wallets available yet.')),
      );
      return;
    }

    final total = regularWalletSummaries.fold<double>(
      0,
      (sum, item) => sum + item.balance,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wallet Balances', style: AppTextStyles.sectionHeader),
                const SizedBox(height: 10),
                ...regularWalletSummaries.map((summary) {
                  final name = summary.wallet.name;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          summary.wallet.isDefault ? '$name (Default)' : name,
                          style: AppTextStyles.body,
                        ),
                        Text(
                          '$currency ${summary.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (savingWalletSummary != null) ...[
                  const Divider(height: 22, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${savingWalletSummary.wallet.name} (Built-in Saving)',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.savings,
                          ),
                        ),
                        Text(
                          '$currency ${savingWalletSummary.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.savings,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 22, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$currency ${total.toStringAsFixed(2)}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete transaction?'),
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
    if (confirmed == true) {
      await ref.read(transactionsProvider.notifier).deleteTransaction(id);
    }
  }
}

enum _TransactionDetailAction { edit, delete }
