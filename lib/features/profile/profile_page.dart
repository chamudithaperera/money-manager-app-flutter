import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../home/models/transaction.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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
            onTap: _showEditProfileDialog,
          ),
          const SizedBox(height: 12),
          _buildSettingsOption(
            icon: Icons.currency_exchange,
            title: 'Change Currency',
            onTap: _showCurrencyPicker,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final settings = ref.read(settingsProvider).asData?.value;
    final initialName = settings?.displayName ?? AppConstants.userDisplayName;
    final initialImage = settings?.profileImagePath;

    final nameController = TextEditingController(text: initialName);
    String? newImagePath = initialImage;
    final ImagePicker picker = ImagePicker();

    // Use a StatefulBuilder to handle local state within the dialog
    await showDialog(
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
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() => newImagePath = image.path);
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: newImagePath != null
                            ? Image.file(File(newImagePath!), fit: BoxFit.cover)
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.textSecondary,
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                  if (newImagePath != initialImage && newImagePath != null) {
                    await ref
                        .read(settingsProvider.notifier)
                        .updateProfileImage(newImagePath!);
                  }
                  if (mounted) Navigator.pop(context);
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
    final currencies = [
      {'code': 'USD', 'symbol': '\$'},
      {'code': 'EUR', 'symbol': '€'},
      {'code': 'GBP', 'symbol': '£'},
      {'code': 'JPY', 'symbol': '¥'},
      {'code': 'LK', 'symbol': 'Rs'},
      {'code': 'INR', 'symbol': '₹'},
    ];

    showModalBottomSheet(
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
            onTap: () {
              ref
                  .read(settingsProvider.notifier)
                  .updateCurrency(currency['symbol']!);
              Navigator.pop(context);
            },
          );
        },
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
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.asData?.value;

    final displayName = settings?.displayName ?? AppConstants.userDisplayName;
    final initials = settings?.initials ?? AppConstants.userInitials;
    final imagePath = settings?.profileImagePath;

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
          clipBehavior: Clip.antiAlias,
          child: imagePath != null
              ? Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 48, color: Colors.white),
                )
              : Text(
                  initials,
                  style: AppTextStyles.appTitle.copyWith(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(displayName, style: AppTextStyles.appTitle),
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
