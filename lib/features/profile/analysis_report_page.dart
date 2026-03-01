import 'package:flutter/material.dart';

import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../../shared/utils/downloads.dart';
import '../home/models/transaction.dart';
import '../wallets/providers/wallet_provider.dart';

class AnalysisReportPage extends ConsumerStatefulWidget {
  const AnalysisReportPage({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  ConsumerState<AnalysisReportPage> createState() => _AnalysisReportPageState();
}

class _AnalysisReportPageState extends ConsumerState<AnalysisReportPage> {
  _DateRangeFilter _dateRangeFilter = _DateRangeFilter.allTime;
  TransactionType? _typeFilter;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final currency =
        ref.watch(settingsProvider).asData?.value.currencySymbol ??
        AppConstants.currencySymbol;
    final filtered = _getFilteredTransactions();
    final summary = _buildSummary(filtered);
    final chartPoints = _buildChartPoints(filtered);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analysis & Reports'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilters(),
            const SizedBox(height: 16),
            _buildSummaryCards(summary, currency),
            const SizedBox(height: 16),
            _buildChartSection(chartPoints, currency),
            const SizedBox(height: 16),
            _buildFilteredPreview(filtered, currency),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isExporting
                  ? null
                  : () => _downloadPdfReport(filtered, currency),
              icon: _isExporting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Symbols.picture_as_pdf),
              label: Text(
                _isExporting ? 'Generating PDF...' : 'Download PDF Report',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
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
          Text('Filter Report', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 10),
          DropdownButtonFormField<_DateRangeFilter>(
            initialValue: _dateRangeFilter,
            dropdownColor: AppColors.surface,
            decoration: const InputDecoration(
              labelText: 'Date Range',
              border: OutlineInputBorder(),
            ),
            items: _DateRangeFilter.values.map((item) {
              return DropdownMenuItem(value: item, child: Text(item.label));
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _dateRangeFilter = value);
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _typeChip('All', null),
              _typeChip('Income', TransactionType.income),
              _typeChip('Expense', TransactionType.expense),
              _typeChip('Savings', TransactionType.savings),
              _typeChip('Deduct', TransactionType.savingDeduct),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, TransactionType? type) {
    final isActive = _typeFilter == type;
    return ChoiceChip(
      selected: isActive,
      onSelected: (_) => setState(() => _typeFilter = type),
      label: Text(label),
      labelStyle: AppTextStyles.chipLabel.copyWith(
        color: isActive ? Colors.black : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.backgroundElevated,
      side: BorderSide(
        color: isActive
            ? AppColors.primary
            : AppColors.border.withValues(alpha: 0.4),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildSummaryCards(_ReportSummary summary, String currency) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            'Income',
            summary.income,
            currency,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'Expense',
            summary.expense,
            currency,
            AppColors.expense,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryCard(
            'Savings',
            summary.netSavings,
            currency,
            AppColors.savings,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
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
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            '$currency${value.toStringAsFixed(0)}',
            style: AppTextStyles.summaryAmount.copyWith(
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<_ChartPoint> data, String currency) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
        ),
        child: Text(
          'No chart data for selected filters.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }

    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    final savingsSpots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i.toDouble();
      incomeSpots.add(FlSpot(x, point.income));
      expenseSpots.add(FlSpot(x, point.expense));
      savingsSpots.add(FlSpot(x, point.savings));
      maxY = [
        maxY,
        point.income,
        point.expense,
        point.savings,
      ].reduce((a, b) => a > b ? a : b).toDouble();
    }

    final double safeMaxY = maxY == 0 ? 100 : maxY * 1.2;
    final double interval = safeMaxY / 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtered Trend', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 4),
          Text(
            'Values in $currency',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.length - 1).toDouble(),
                minY: 0,
                maxY: safeMaxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  horizontalInterval: interval,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, _) {
                        return Text(
                          _compactAmount(value),
                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        if (data.length > 10 &&
                            index % (data.length ~/ 6) != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[index].label,
                            style: AppTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(incomeSpots, AppColors.primary),
                  _line(expenseSpots, AppColors.expense),
                  _line(savingsSpots, AppColors.savings),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _LegendItem(label: 'Income', color: AppColors.primary),
              _LegendItem(label: 'Expense', color: AppColors.expense),
              _LegendItem(label: 'Savings', color: AppColors.savings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredPreview(List<Transaction> filtered, String currency) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtered Details', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 4),
          Text(
            '${filtered.length} transaction(s) selected',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Text(
              'No matching transactions for these filters.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              children: filtered.take(8).map((tx) {
                final amountColor = switch (tx.type) {
                  TransactionType.income => AppColors.primary,
                  TransactionType.expense => AppColors.expense,
                  TransactionType.savings => AppColors.savings,
                  TransactionType.savingDeduct => Colors.orange,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title,
                              style: AppTextStyles.transactionTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('MMM d, yyyy').format(tx.date)} • ${tx.category}',
                              style: AppTextStyles.transactionSubtitle,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$currency${tx.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.transactionAmount.copyWith(
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (filtered.length > 8)
            Text(
              'PDF includes all ${filtered.length} rows.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      barWidth: 2,
      color: color,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }

  String _compactAmount(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  List<Transaction> _getFilteredTransactions() {
    final now = DateTime.now();
    final start = switch (_dateRangeFilter) {
      _DateRangeFilter.allTime => null,
      _DateRangeFilter.thisMonth => DateTime(now.year, now.month, 1),
      _DateRangeFilter.last3Months => DateTime(now.year, now.month - 2, 1),
      _DateRangeFilter.thisYear => DateTime(now.year, 1, 1),
    };

    final end = switch (_dateRangeFilter) {
      _DateRangeFilter.thisMonth => DateTime(now.year, now.month + 1, 1),
      _ => null,
    };

    final filtered = widget.transactions.where((tx) {
      if (_typeFilter != null && tx.type != _typeFilter) {
        return false;
      }

      if (start != null && tx.date.isBefore(start)) {
        return false;
      }

      if (end != null && !tx.date.isBefore(end)) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  _ReportSummary _buildSummary(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    double savings = 0;
    double savingDeduct = 0;

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expense += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount;
          break;
        case TransactionType.savingDeduct:
          savingDeduct += tx.amount;
          break;
      }
    }

    return _ReportSummary(
      income: income,
      expense: expense,
      savings: savings,
      savingDeduct: savingDeduct,
    );
  }

  List<_ChartPoint> _buildChartPoints(List<Transaction> transactions) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final labelFormatter = DateFormat('MMM d');

    final map = <String, _ReportSummary>{};
    for (final tx in transactions) {
      final key = dateFormatter.format(tx.date);
      map.putIfAbsent(
        key,
        () => const _ReportSummary(
          income: 0,
          expense: 0,
          savings: 0,
          savingDeduct: 0,
        ),
      );
      final current = map[key]!;
      map[key] = switch (tx.type) {
        TransactionType.income => current.copyWith(
          income: current.income + tx.amount,
        ),
        TransactionType.expense => current.copyWith(
          expense: current.expense + tx.amount,
        ),
        TransactionType.savings => current.copyWith(
          savings: current.savings + tx.amount,
        ),
        TransactionType.savingDeduct => current.copyWith(
          savingDeduct: current.savingDeduct + tx.amount,
        ),
      };
    }

    final sortedKeys = map.keys.toList()..sort();
    return sortedKeys.map((key) {
      final stats = map[key]!;
      final date = DateFormat('yyyy-MM-dd').parse(key);
      return _ChartPoint(
        label: labelFormatter.format(date),
        income: stats.income,
        expense: stats.expense,
        savings: stats.netSavings,
      );
    }).toList();
  }

  Future<void> _downloadPdfReport(
    List<Transaction> filtered,
    String currency,
  ) async {
    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filtered data to export.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final wallets = await ref.read(walletRepositoryProvider).getAll();
      final walletMap = {
        for (final wallet in wallets)
          if (wallet.id != null) wallet.id!: wallet.name,
      };

      final pdf = pw.Document();
      final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final summary = _buildSummary(filtered);
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return [
              pw.Text(
                'Money Manager Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Generated: $generatedAt'),
              pw.Text('Date filter: ${_dateRangeFilter.label}'),
              pw.Text(
                'Type filter: ${_typeFilter?.name.toUpperCase() ?? 'ALL'}',
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Summary',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Income: $currency${summary.income.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Expense: $currency${summary.expense.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Savings: $currency${summary.savings.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Deduct: $currency${summary.savingDeduct.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Net Savings: $currency${summary.netSavings.toStringAsFixed(2)}',
                    ),
                    pw.Text(
                      'Net Balance: $currency${summary.balance.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Filtered Details (${filtered.length} rows)',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'Date',
                  'Title',
                  'Category',
                  'Type',
                  'Wallet',
                  'Amount',
                ],
                data: filtered.map((tx) {
                  final walletName =
                      walletMap[tx.walletId] ?? 'Wallet #${tx.walletId}';
                  return [
                    dateFormat.format(tx.date),
                    tx.title,
                    tx.category,
                    tx.type.name,
                    walletName,
                    '$currency${tx.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300),
                  verticalInside: pw.BorderSide(color: PdfColors.grey300),
                  top: pw.BorderSide(color: PdfColors.grey400),
                  bottom: pw.BorderSide(color: PdfColors.grey400),
                  left: pw.BorderSide(color: PdfColors.grey400),
                  right: pw.BorderSide(color: PdfColors.grey400),
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final targetDir = await getMoneyManagerDownloadDirectory();
      final fileName =
          'money_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final filePath = p.join(targetDir.path, fileName);
      await File(filePath).writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF downloaded to: $filePath')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export PDF: $error')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
}

class _ChartPoint {
  const _ChartPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.savings,
  });

  final String label;
  final double income;
  final double expense;
  final double savings;
}

class _ReportSummary {
  const _ReportSummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingDeduct,
  });

  final double income;
  final double expense;
  final double savings;
  final double savingDeduct;

  double get netSavings => savings - savingDeduct;

  double get balance => income - expense - savings;

  _ReportSummary copyWith({
    double? income,
    double? expense,
    double? savings,
    double? savingDeduct,
  }) {
    return _ReportSummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      savings: savings ?? this.savings,
      savingDeduct: savingDeduct ?? this.savingDeduct,
    );
  }
}

enum _DateRangeFilter { allTime, thisMonth, last3Months, thisYear }

extension on _DateRangeFilter {
  String get label {
    return switch (this) {
      _DateRangeFilter.allTime => 'All Time',
      _DateRangeFilter.thisMonth => 'This Month',
      _DateRangeFilter.last3Months => 'Last 3 Months',
      _DateRangeFilter.thisYear => 'This Year',
    };
  }
}
