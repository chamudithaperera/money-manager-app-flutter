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
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: AppConstants.userDisplayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _generateReport(widget.transactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Monthly Analysis', style: AppTextStyles.sectionHeader),
          ),
          const SizedBox(height: 16),
          if (report.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No transaction data available yet.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
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
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
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
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isEditingName)
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: AppTextStyles.appTitle,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => setState(() => _isEditingName = false),
                ),
              )
            else
              Text(_nameController.text, style: AppTextStyles.appTitle),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isEditingName ? Icons.check : Icons.edit,
                size: 18,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() => _isEditingName = !_isEditingName);
              },
            ),
          ],
        ),
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
