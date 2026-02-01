import 'dart:io';
import 'dart:math' as math; // Import math for min/max

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
  DateTime? _selectedMonth; // Null represents "All"

  @override
  void initState() {
    super.initState();
    _selectedMonth = null;
  }

  @override
  Widget build(BuildContext context) {
    // Collect available months
    final availableMonths = _getAvailableMonths();

    // Ensure selection is valid
    if (_selectedMonth != null &&
        !availableMonths.contains(_selectedMonth) &&
        !availableMonths.any(
          (d) => d != null && isSameMonth(d, _selectedMonth!),
        )) {
      // If selected month (not null) is invalid, fallback
      // Here we can fallback to the first available month or null (All)
      // Let's fallback to current month if in list, otherwise null
      final now = DateTime(DateTime.now().year, DateTime.now().month);
      if (availableMonths.any((d) => d != null && isSameMonth(d, now))) {
        _selectedMonth = now;
      } else {
        _selectedMonth = null;
      }
    }

    final chartData = _getChartData(_selectedMonth);
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
          _buildChartSection(chartData, currency),
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

  List<DateTime?> _getAvailableMonths() {
    final Set<String> uniqueMonths = {};
    final List<DateTime> months = [];

    // Always include current month in the list if we have transactions, or just always?
    // Let's just rely on transaction data + current month relative to now.
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
    return [null, ...months]; // Prepend null for "All"
  }

  // Unified data access
  List<_ChartPoint> _getChartData(DateTime? month) {
    if (month != null) {
      return _getDailyChartData(month);
    } else {
      return _getMonthlyChartData();
    }
  }

  List<_ChartPoint> _getDailyChartData(DateTime month) {
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
        _accumulateStats(current, tx);
      }
    }

    // Convert to ChartPoints
    final List<_ChartPoint> points = [];
    final sortedDays = stats.keys.toList()..sort();
    for (final day in sortedDays) {
      final stat = stats[day]!;
      points.add(
        _ChartPoint(
          label: day.toString(),
          income: stat.income,
          expense: stat.expense,
          savings: stat.savings,
          deduct: stat.savingDeduct,
        ),
      );
    }
    return points;
  }

  List<_ChartPoint> _getMonthlyChartData() {
    final Map<String, _DailyStats> stats = {}; // Key: "YYYY-MM-DD"
    final List<DateTime> dateKeys = [];

    for (final tx in widget.transactions) {
      // Create key based on full date
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      if (!stats.containsKey(key)) {
        stats[key] = _DailyStats();
        dateKeys.add(DateTime(tx.date.year, tx.date.month, tx.date.day));
      }
      final current = stats[key]!;
      _accumulateStats(current, tx);
    }

    final sortedUniqueDates = dateKeys.toSet().toList()
      ..sort((a, b) => a.compareTo(b));

    final List<_ChartPoint> points = [];
    final formatter = DateFormat('MMM d');

    for (final date in sortedUniqueDates) {
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final stat = stats[key] ?? _DailyStats();
      points.add(
        _ChartPoint(
          label: formatter.format(date),
          income: stat.income,
          expense: stat.expense,
          savings: stat.savings,
          deduct: stat.savingDeduct,
        ),
      );
    }
    return points;
  }

  void _accumulateStats(_DailyStats current, Transaction tx) {
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

  Widget _buildMonthSelector(List<DateTime?> months) {
    final formatter = DateFormat('MMMM yyyy');

    // Find effective value
    DateTime? groupValue;
    if (_selectedMonth == null) {
      groupValue = null;
    } else {
      // Match by value equality
      try {
        groupValue = months.firstWhere(
          (m) => m != null && isSameMonth(m, _selectedMonth!),
        );
      } catch (e) {
        groupValue = null; // Should not happen given build logic
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime?>(
          value: groupValue,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.calendar_month, color: AppColors.primary),
          isExpanded: true,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          items: months.map((date) {
            return DropdownMenuItem<DateTime?>(
              value: date,
              child: Text(date == null ? 'All Time' : formatter.format(date)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedMonth = value);
          },
        ),
      ),
    );
  }

  Widget _buildChartSection(List<_ChartPoint> data, String currency) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Prepare spots
    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> savingsSpots = [];
    final List<FlSpot> deductSpots = [];

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    double totalSavingsRaw = 0;
    double totalDeduct = 0;

    double maxY = 0;
    double minY = 0;

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i.toDouble();

      // Calculate NET savings for the point (as requested "deduct reduce from saving")
      // Visualizing the Net Savings flow
      final netSavings = point.savings - point.deduct;

      incomeSpots.add(FlSpot(x, point.income));
      expenseSpots.add(FlSpot(x, point.expense));
      savingsSpots.add(FlSpot(x, netSavings)); // Plot Net Savings
      deductSpots.add(FlSpot(x, point.deduct));

      totalIncome += point.income;
      totalExpense += point.expense;
      totalSavingsRaw += point.savings;
      totalDeduct += point.deduct;

      final pointMax = [
        point.income,
        point.expense,
        netSavings,
        point.deduct,
      ].reduce(math.max);
      final pointMin = [
        point.income,
        point.expense,
        netSavings,
        point.deduct,
      ].reduce(math.min);

      if (pointMax > maxY) maxY = pointMax;
      if (pointMin < minY) minY = pointMin;
    }

    double totalNetSavings = totalSavingsRaw - totalDeduct;

    // Add buffers
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;
    // Lower buffer if we have negative values
    if (minY < 0)
      minY = minY * 1.2;
    else
      minY = 0;

    // Grid interval
    final interval = (maxY - minY) / 5;
    final double safeInterval = interval <= 0 ? 20 : interval;

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
              _chartLegend('Income', AppColors.primary, totalIncome, currency),
              _chartLegend(
                'Expense',
                AppColors.expense,
                totalExpense,
                currency,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Show Net Savings in legend
              _chartLegend(
                'Savings',
                AppColors.savings,
                totalNetSavings,
                currency,
              ),
              _chartLegend('From Sav.', Colors.orange, totalDeduct, currency),
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
                  horizontalInterval: safeInterval,
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
                      interval: 1, // Show all or skip? For daily use dynamic?
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length)
                          return const SizedBox.shrink();

                        // Optimize labels: if many points, skip some
                        if (data.length > 10 &&
                            index % (data.length ~/ 6) != 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            data[index].label,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: safeInterval,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        // Avoid clutter
                        if (value == minY && minY == 0)
                          return const SizedBox.shrink();

                        return Text(
                          _compactCurrency(value),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: minY,
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
                        // Find matching chart point logic if needed, but Y value is mostly enough
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

  Widget _chartLegend(
    String label,
    Color color,
    double amount,
    String currency,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $currency${amount.toStringAsFixed(0)}',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  String _compactCurrency(double value) {
    if (value.abs() >= 1000) {
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

class _ChartPoint {
  _ChartPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.savings,
    required this.deduct,
  });

  final String label;
  final double income;
  final double expense;
  final double savings;
  final double deduct;
}
