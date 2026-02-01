import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
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
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    // Collect available months
    final availableMonths = _getAvailableMonths();
    if (!availableMonths.any((d) => isSameMonth(d, _selectedMonth))) {
      if (availableMonths.isNotEmpty) {
        _selectedMonth = availableMonths.first;
      }
    }

    final dailyStats = _getDailyStats(_selectedMonth);
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildMonthSelector(availableMonths),
          const SizedBox(height: 16),
          _buildChartSection(dailyStats, currency),
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
          const SizedBox(height: 32),
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

  bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  List<DateTime> _getAvailableMonths() {
    final Set<String> uniqueMonths = {};
    final List<DateTime> months = [];

    // Always include current month
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month}';
    uniqueMonths.add(currentKey);
    months.add(DateTime(now.year, now.month));

    for (final tx in widget.transactions) {
      final key = '${tx.date.year}-${tx.date.month}';
      if (!uniqueMonths.contains(key)) {
        uniqueMonths.add(key);
        months.add(DateTime(tx.date.year, tx.date.month));
      }
    }

    months.sort((a, b) => b.compareTo(a)); // Newest first
    return months;
  }

  Map<int, _DailyStats> _getDailyStats(DateTime month) {
    final Map<int, _DailyStats> stats = {};
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    // Initialize all days
    for (int i = 1; i <= daysInMonth; i++) {
      stats[i] = _DailyStats();
    }

    for (final tx in widget.transactions) {
      if (isSameMonth(tx.date, month)) {
        final day = tx.date.day;
        final current = stats[day]!;
        switch (tx.type) {
          case TransactionType.income:
            current.income += tx.amount;
            break;
          case TransactionType.expense:
            current.expense += tx.amount;
            break;
          case TransactionType.savings:
            current.savings += tx.amount;
            break;
          case TransactionType.savingDeduct:
            current.savingDeduct += tx.amount;
            break;
        }
      }
    }
    return stats;
  }

  Widget _buildMonthSelector(List<DateTime> months) {
    final formatter = DateFormat('MMMM yyyy');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: months.firstWhere(
            (m) => isSameMonth(m, _selectedMonth),
            orElse: () => months.first,
          ),
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.calendar_month, color: AppColors.primary),
          isExpanded: true,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          items: months.map((date) {
            return DropdownMenuItem(
              value: date,
              child: Text(formatter.format(date)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedMonth = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildChartSection(Map<int, _DailyStats> dailyStats, String currency) {
    final days = dailyStats.keys.toList()..sort();
    if (days.isEmpty) return const SizedBox.shrink();

    // Prepare spots
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> savingsSpots = [];
    final List<FlSpot> deductSpots = [];

    double maxY = 0;

    for (final day in days) {
      final stat = dailyStats[day]!;
      incomeSpots.add(FlSpot(day.toDouble(), stat.income));
      expenseSpots.add(FlSpot(day.toDouble(), stat.expense));
      savingsSpots.add(FlSpot(day.toDouble(), stat.savings));
      deductSpots.add(FlSpot(day.toDouble(), stat.savingDeduct));

      maxY = [
        maxY,
        stat.income,
        stat.expense,
        stat.savings,
        stat.savingDeduct,
      ].reduce((a, b) => a > b ? a : b);
    }

    // Add some buffer to maxY
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartLegend('Income', AppColors.primary),
              _chartLegend('Expense', AppColors.expense),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _chartLegend('Savings', AppColors.savings),
              _chartLegend(
                'From Sav.',
                Colors.orange,
              ), // Custom color for deduct
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value > days.last)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 5,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          _compactCurrency(value),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: days.last.toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  _lineData(incomeSpots, AppColors.primary),
                  _lineData(expenseSpots, AppColors.expense),
                  _lineData(savingsSpots, AppColors.savings),
                  _lineData(deductSpots, Colors.orange),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.surfaceVariant,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(0)}',
                          AppTextStyles.caption.copyWith(
                            color: spot.bar.color,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  // Settings methods
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
}

class _DailyStats {
  double income = 0;
  double expense = 0;
  double savings = 0;
  double savingDeduct = 0;
}
