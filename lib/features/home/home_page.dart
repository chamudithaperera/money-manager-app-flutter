import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/transaction_providers.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../profile/profile_page.dart';
import '../transaction_history/history_page.dart';
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
  String _dateFilter = 'This Month';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final stats = ref.watch(statsProvider);

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
                    return _buildHome(items, stats);
                  }
                  if (_activeTab == BottomTab.history) {
                    return _buildHistory(items);
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

  Widget _buildHome(List<Transaction> items, HomeStats stats) {
    final recentTransactions = items.take(5).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          BalanceCard(balance: stats.balance),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  type: TransactionType.income,
                  amount: stats.income,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  type: TransactionType.expense,
                  amount: stats.expenses,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  type: TransactionType.savings,
                  amount: stats.savings,
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
                  onLongPress: () => _showTransactionActions(tx),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Money Manager', style: AppTextStyles.appTitle),
            const SizedBox(height: 4),
            Text(
              'Welcome back, ${AppConstants.userDisplayName}',
              style: AppTextStyles.welcome,
            ),
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
            child: Text(
              AppConstants.userInitials,
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
          child: const Icon(Icons.add, size: 18, color: Colors.black),
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
          onPressed: () {},
          child: Text('See All', style: AppTextStyles.link),
        ),
      ],
    );
  }

  Widget _buildHistory(List<Transaction> items) {
    return HistoryPage(
      transactions: items,
      activeType: _filterType,
      onTypeChange: (type) => setState(() => _filterType = type),
      activeDate: _dateFilter,
      onDateChange: (date) => setState(() => _dateFilter = date),
      onTransactionLongPress: _showTransactionActions,
    );
  }

  Widget _buildProfile(List<Transaction> items) {
    return ProfilePage(transactions: items);
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
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddSheet(initial: transaction);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.expense),
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
