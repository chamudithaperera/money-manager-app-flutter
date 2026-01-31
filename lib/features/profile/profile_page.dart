import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../home/models/transaction.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final report = _generateReport(widget.transactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          Text('Monthly Analysis', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 16),
          if (report.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No transaction data available yet.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _MonthCard(stats: report[index]),
            ),
          const SizedBox(height: 32),
          Text('Settings', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 16),
          _buildSettingsOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),
          const SizedBox(height: 12),
          _buildSettingsOption(
            icon: Icons.currency_exchange,
            title: 'Change Currency',
            onTap: () {
              // TODO: Open currency picker
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.savings],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.background, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(AppConstants.userDisplayName, style: AppTextStyles.appTitle),
        const SizedBox(height: 4),
        Text(
          'Premium Member',
          style: AppTextStyles.caption.copyWith(color: AppColors.savings),
        ),
      ],
    );
  }

  List<_MonthStats> _generateReport(List<Transaction> transactions) {
    print('Generating report for ${transactions.length} transactions');
    final Map<String, _MonthStats> stats = {};

    for (final tx in transactions) {
      final key = '${tx.date.year}-${tx.date.month}';
      if (!stats.containsKey(key)) {
        stats[key] = _MonthStats(date: DateTime(tx.date.year, tx.date.month));
      }

      final current = stats[key]!;
      if (tx.type == TransactionType.income) {
        current.income += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        current.expenses += tx.amount;
      } else if (tx.type == TransactionType.savings) {
        current.savings += tx.amount;
      }
    }

    final list = stats.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

class _MonthStats {
  _MonthStats({
    required this.date,
    this.income = 0,
    this.expenses = 0,
    this.savings = 0,
  });

  final DateTime date;
  double income;
  double expenses;
  double savings;
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.stats});

  final _MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy');
    final total = stats.income - stats.expenses - stats.savings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatter.format(stats.date),
                style: AppTextStyles.sectionLabel.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${total >= 0 ? "+" : ""}${AppConstants.currencySymbol} ${total.toStringAsFixed(0)}',
                style: AppTextStyles.summaryAmount.copyWith(
                  color: total >= 0 ? AppColors.primary : AppColors.expense,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Bar(
            label: 'Income',
            amount: stats.income,
            color: AppColors.primary,
            total: stats.income + stats.expenses + stats.savings,
          ),
          const SizedBox(height: 8),
          _Bar(
            label: 'Expense',
            amount: stats.expenses,
            color: AppColors.expense,
            total: stats.income + stats.expenses + stats.savings,
          ),
          const SizedBox(height: 8),
          _Bar(
            label: 'Savings',
            amount: stats.savings,
            color: AppColors.savings,
            total: stats.income + stats.expenses + stats.savings,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.amount,
    required this.color,
    required this.total,
  });

  final String label;
  final double amount;
  final Color color;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    // Prevent division by zero if total is 0 (though ideally handled by amount check)
    final percentage = total > 0 ? (amount / total) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
