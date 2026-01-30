import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../shared/widgets/bottom_nav.dart';
import 'data/mock_data.dart';
import 'models/transaction.dart';
import 'widgets/activity_item.dart';
import 'widgets/balance_card.dart';
import 'widgets/stat_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BottomTab _activeTab = BottomTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: _activeTab == BottomTab.home
                ? _buildHome()
                : _buildHistoryPlaceholder(),
          ),
          BottomNav(
            activeTab: _activeTab,
            onTabChange: (tab) => setState(() => _activeTab = tab),
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final recentTransactions = transactions.take(5).toList();
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
                ActivityItem(transaction: tx),
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
            Text('Welcome back, Alex', style: AppTextStyles.welcome),
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
              'AL',
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

  Widget _buildHistoryPlaceholder() {
    return Center(
      child: Text(
        'History',
        style: AppTextStyles.sectionHeader.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showAddSheet() {
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add Transaction', style: AppTextStyles.modalTitle),
              const SizedBox(height: 8),
              Text(
                'Modal UI will be added next.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
