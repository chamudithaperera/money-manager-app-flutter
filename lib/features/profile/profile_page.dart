import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';

import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../shared/utils/downloads.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../wallets/providers/wallet_provider.dart';
import '../home/models/transaction.dart';
import 'analysis_report_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).asData?.value;
    final currency = settings?.currencySymbol ?? AppConstants.currencySymbol;
    final regularSummaries = ref.watch(regularWalletSummariesProvider);
    final savingWalletSummary = ref.watch(savingWalletSummaryProvider);
    final savingsBalance = ref.watch(savingsBalanceProvider);
    final totalRegularBalance = ref.watch(totalRegularWalletBalanceProvider);

    final regularIncome = regularSummaries.fold<double>(
      0,
      (sum, item) => sum + item.income,
    );
    final regularExpense = regularSummaries.fold<double>(
      0,
      (sum, item) => sum + item.expense,
    );

    final stats = _buildStats(
      widget.transactions,
      income: regularIncome,
      expense: regularExpense,
      savings: savingsBalance,
      balance: totalRegularBalance,
    );

    final monthlyBudget = settings?.monthlyBudget;
    final savingWalletId = savingWalletSummary?.wallet.id;
    final thisMonthExpense = _thisMonthExpense(
      widget.transactions,
      excludedWalletId: savingWalletId,
    );
    final savingsRate = stats.income <= 0
        ? 0.0
        : (stats.savings / stats.income) * 100;
    final averageTransaction = _averageTransactionAmount(widget.transactions);
    final topExpenseCategory = _topExpenseCategory(
      widget.transactions,
      excludedWalletId: savingWalletId,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileDetailsCard(
            settings,
            currency,
            stats,
            thisMonthExpense: thisMonthExpense,
          ),
          const SizedBox(height: 22),
          Text('Financial Snapshot', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),
          _buildSummaryTiles(stats, currency),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  title: 'Avg Transaction',
                  value: '$currency${averageTransaction.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _detailTile(
                  title: 'Top Expense',
                  value: topExpenseCategory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBudgetCard(
            currency: currency,
            monthlyBudget: monthlyBudget,
            thisMonthExpense: thisMonthExpense,
          ),
          const SizedBox(height: 22),
          Text('Smart Insights', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),
          _buildInsightGrid(
            currency: currency,
            savingsRate: savingsRate,
            averageTransaction: averageTransaction,
            topExpenseCategory: topExpenseCategory,
            thisMonthExpense: thisMonthExpense,
          ),
          const SizedBox(height: 22),
          Text('Quick Actions', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),
          _buildActionGrid(
            actions: [
              _ActionItem(
                icon: Symbols.person,
                title: 'Edit Profile',
                subtitle: 'Name and profile photo',
                onTap: _showEditProfileDialog,
              ),
              _ActionItem(
                icon: Symbols.analytics,
                title: 'Reports',
                subtitle: 'View analysis and export PDF',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          AnalysisReportPage(transactions: widget.transactions),
                    ),
                  );
                },
              ),
              _ActionItem(
                icon: Symbols.download,
                title: 'Export CSV',
                subtitle: 'Download transaction history',
                onTap: _exportTransactionsCsv,
              ),
              _ActionItem(
                icon: Symbols.currency_exchange,
                title: 'Currency',
                subtitle: 'Change symbol and display',
                onTap: _showCurrencyPicker,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Settings', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),
          _buildSettingsOption(
            icon: Symbols.target,
            title: 'Monthly Budget',
            subtitle: monthlyBudget == null
                ? 'Set your monthly spending target'
                : 'Current budget: $currency${monthlyBudget.toStringAsFixed(0)}',
            onTap: () => _showBudgetDialog(currency, monthlyBudget),
          ),
          const SizedBox(height: 10),
          _buildSettingsOption(
            icon: Symbols.info,
            title: 'About App',
            subtitle: 'Version and developer details',
            onTap: _showAboutDialog,
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Product of ChamXdev by Chamuditha Perera',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  _ProfileStats _buildStats(
    List<Transaction> transactions, {
    required double income,
    required double expense,
    required double savings,
    required double balance,
  }) {
    final now = DateTime.now();
    final thisMonthCount = transactions.where((tx) {
      return tx.date.year == now.year && tx.date.month == now.month;
    }).length;

    final oldestDate = transactions.isEmpty
        ? now
        : transactions
              .map((tx) => tx.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);

    return _ProfileStats(
      income: income,
      expense: expense,
      savings: savings,
      balance: balance,
      totalTransactions: transactions.length,
      thisMonthTransactions: thisMonthCount,
      memberSince: oldestDate,
    );
  }

  Widget _buildProfileDetailsCard(
    SettingsState? settings,
    String currency,
    _ProfileStats stats, {
    required double thisMonthExpense,
  }) {
    final displayName = settings?.displayName ?? AppConstants.userDisplayName;
    final initials = settings?.initials ?? AppConstants.userInitials;
    final imagePath = settings?.profileImagePath;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF252525), Color(0xFF1D1D1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(imagePath, initials, 70),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Currency: $currency',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Member since ${DateFormat('MMM yyyy').format(stats.memberSince)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _showEditProfileDialog,
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  title: 'Transactions',
                  value: '${stats.totalTransactions}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detailTile(
                  title: 'This Month',
                  value: '${stats.thisMonthTransactions}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _detailTile(
                  title: 'Spend This Month',
                  value: '$currency${thisMonthExpense.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spendable Balance',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$currency${stats.balance.toStringAsFixed(2)}',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? imagePath, String initials, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.savings],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath != null
          ? Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.appTitle.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                initials,
                style: AppTextStyles.appTitle.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryTiles(_ProfileStats stats, String currency) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            'Income',
            stats.income,
            currency,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryTile(
            'Expense',
            stats.expense,
            currency,
            AppColors.expense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryTile(
            'Savings',
            stats.savings,
            currency,
            AppColors.savings,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard({
    required String currency,
    required double? monthlyBudget,
    required double thisMonthExpense,
  }) {
    final budget = monthlyBudget;
    final hasBudget = budget != null && budget > 0;
    final ratio = hasBudget ? (thisMonthExpense / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = hasBudget ? budget - thisMonthExpense : 0.0;
    final isOverBudget = hasBudget && remaining < 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.target, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly Budget',
                  style: AppTextStyles.sectionLabel,
                ),
              ),
              TextButton(
                onPressed: () => _showBudgetDialog(currency, monthlyBudget),
                child: Text(hasBudget ? 'Edit' : 'Set'),
              ),
            ],
          ),
          if (!hasBudget)
            Text(
              'Set a monthly target to track this month spending against your goal.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            const SizedBox(height: 6),
            Text(
              'Spent: $currency${thisMonthExpense.toStringAsFixed(2)} / $currency${budget.toStringAsFixed(2)}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppColors.expense : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Over budget by $currency${(-remaining).toStringAsFixed(2)}'
                  : 'Remaining: $currency${remaining.toStringAsFixed(2)}',
              style: AppTextStyles.caption.copyWith(
                color: isOverBudget
                    ? AppColors.expense
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightGrid({
    required String currency,
    required double savingsRate,
    required double averageTransaction,
    required String topExpenseCategory,
    required double thisMonthExpense,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _insightTile(
          icon: Symbols.savings,
          title: 'Savings Rate',
          value: '${savingsRate.toStringAsFixed(1)}%',
          color: AppColors.savings,
        ),
        _insightTile(
          icon: Symbols.monitoring,
          title: 'Avg Transaction',
          value: '$currency${averageTransaction.toStringAsFixed(2)}',
          color: AppColors.primary,
        ),
        _insightTile(
          icon: Symbols.category,
          title: 'Top Expense',
          value: topExpenseCategory,
          color: AppColors.expense,
        ),
        _insightTile(
          icon: Symbols.calendar_month,
          title: 'Month Expense',
          value: '$currency${thisMonthExpense.toStringAsFixed(2)}',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildActionGrid({required List<_ActionItem> actions}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 18, color: AppColors.primary),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
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

  Widget _insightTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    String label,
    double value,
    String currency,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currency${value.toStringAsFixed(0)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.summaryAmount.copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile({required String title, required String value}) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  double _thisMonthExpense(
    List<Transaction> transactions, {
    int? excludedWalletId,
  }) {
    final now = DateTime.now();
    return transactions
        .where(
          (tx) =>
              tx.type == TransactionType.expense &&
              tx.walletId != excludedWalletId &&
              tx.date.year == now.year &&
              tx.date.month == now.month,
        )
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _averageTransactionAmount(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    final total = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    return total / transactions.length;
  }

  String _topExpenseCategory(
    List<Transaction> transactions, {
    int? excludedWalletId,
  }) {
    final categoryTotals = <String, double>{};
    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;
      if (tx.walletId == excludedWalletId) continue;
      categoryTotals.update(
        tx.category,
        (value) => value + tx.amount,
        ifAbsent: () => tx.amount,
      );
    }
    if (categoryTotals.isEmpty) return 'N/A';
    final top = categoryTotals.entries.reduce((a, b) {
      return a.value >= b.value ? a : b;
    });
    return top.key;
  }

  Future<void> _showBudgetDialog(String currency, double? currentBudget) async {
    final controller = TextEditingController(
      text: currentBudget?.toStringAsFixed(2) ?? '',
    );

    try {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Monthly Budget'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Budget Amount',
              prefixText: '$currency ',
              hintText: '0.00',
            ),
          ),
          actions: [
            if (currentBudget != null)
              TextButton(
                onPressed: () => Navigator.of(context).pop('clear'),
                child: const Text('Clear'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('save'),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (action == 'clear') {
        await ref.read(settingsProvider.notifier).updateMonthlyBudget(null);
        return;
      }

      if (action != 'save') return;

      final parsed = double.tryParse(controller.text.trim());
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid budget amount.')),
        );
        return;
      }

      await ref.read(settingsProvider.notifier).updateMonthlyBudget(parsed);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showEditProfileDialog() async {
    final settings = ref.read(settingsProvider).asData?.value;
    final initialName = settings?.displayName ?? AppConstants.userDisplayName;
    final initialImage = settings?.profileImagePath;

    final nameController = TextEditingController(text: initialName);
    String? newImagePath = initialImage;
    final ImagePicker picker = ImagePicker();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => newImagePath = image.path);
                    }
                  },
                  child: Stack(
                    children: [
                      _buildAvatar(
                        newImagePath,
                        settings?.initials ?? AppConstants.userInitials,
                        84,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Symbols.camera_alt,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (newImagePath != null)
                  TextButton(
                    onPressed: () => setState(() => newImagePath = null),
                    child: const Text('Remove Photo'),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newName = nameController.text.trim();
                  if (newName.isNotEmpty) {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateDisplayName(newName);
                  }

                  if (newImagePath == null) {
                    await ref
                        .read(settingsProvider.notifier)
                        .clearProfileImage();
                  } else if (newImagePath != initialImage) {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateProfileImage(newImagePath!);
                  }

                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCurrencyPicker() {
    const currencies = [
      {'code': 'USD', 'symbol': '\$'},
      {'code': 'EUR', 'symbol': '€'},
      {'code': 'GBP', 'symbol': '£'},
      {'code': 'JPY', 'symbol': '¥'},
      {'code': 'LKR', 'symbol': 'Rs'},
      {'code': 'INR', 'symbol': '₹'},
    ];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: currencies.length,
        itemBuilder: (context, index) {
          final currency = currencies[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.background,
              child: Text(
                currency['symbol']!,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
            title: Text('${currency['code']} (${currency['symbol']})'),
            onTap: () async {
              await ref
                  .read(settingsProvider.notifier)
                  .updateCurrency(currency['symbol']!);
              if (!mounted) return;
              Navigator.of(this.context).pop();
            },
          );
        },
      ),
    );
  }

  Future<void> _exportTransactionsCsv() async {
    final settings = ref.read(settingsProvider).asData?.value;
    final currency = settings?.currencySymbol ?? AppConstants.currencySymbol;
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    final walletMap = {
      for (final wallet in wallets)
        if (wallet.id != null) wallet.id!: wallet.name,
    };

    final sorted = [...widget.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final csv = StringBuffer();
    csv.writeln('Date,Title,Category,Type,Wallet,Amount ($currency)');

    for (final tx in sorted) {
      final walletName = walletMap[tx.walletId] ?? 'Wallet #${tx.walletId}';
      csv.writeln(
        '${formatter.format(tx.date)},${_escapeCsv(tx.title)},${_escapeCsv(tx.category)},${tx.type.name},${_escapeCsv(walletName)},${tx.amount.toStringAsFixed(2)}',
      );
    }

    try {
      final directory = await getMoneyManagerDownloadDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = p.join(directory.path, 'transactions_$timestamp.csv');
      await File(path).writeAsBytes(utf8.encode(csv.toString()), flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV exported to: $path')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export CSV: $error')));
    }
  }

  String _escapeCsv(String input) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('About My Money Manager'),
        content: Text(
          'Track your income, expenses, and savings in one place.\n\nVersion: 1.0.0\nDeveloper: Chamuditha Perera',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ProfileStats {
  const _ProfileStats({
    required this.income,
    required this.expense,
    required this.savings,
    required this.balance,
    required this.totalTransactions,
    required this.thisMonthTransactions,
    required this.memberSince,
  });

  final double income;
  final double expense;
  final double savings;
  final double balance;
  final int totalTransactions;
  final int thisMonthTransactions;
  final DateTime memberSince;
}
