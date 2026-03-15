import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
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
    final savingWalletBalance = ref.watch(savingsBalanceProvider);
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
            _buildSummaryCards(summary, savingWalletBalance, currency),
            const SizedBox(height: 16),
            _buildChartSection(chartPoints, currency),
            const SizedBox(height: 16),
            _buildFilteredPreview(filtered, currency),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isExporting
                  ? null
                  : () => _downloadPdfReport(
                      filtered,
                      currency,
                      savingWalletBalance,
                    ),
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

  Widget _buildSummaryCards(
    _ReportSummary summary,
    double savingWalletBalance,
    String currency,
  ) {
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
            'Saving Wallet',
            savingWalletBalance,
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
    final netSpots = <FlSpot>[];
    double maxY = 0;

    for (var i = 0; i < data.length; i++) {
      final point = data[i];
      final x = i.toDouble();
      incomeSpots.add(FlSpot(x, point.income));
      expenseSpots.add(FlSpot(x, point.expense));
      netSpots.add(FlSpot(x, point.net));
      maxY = [
        maxY,
        point.income,
        point.expense,
        point.net.abs(),
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
                  _line(netSpots, AppColors.savings),
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
              _LegendItem(label: 'Net', color: AppColors.savings),
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

    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expense += tx.amount;
          break;
      }
    }

    return _ReportSummary(income: income, expense: expense);
  }

  List<_ChartPoint> _buildChartPoints(List<Transaction> transactions) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final labelFormatter = DateFormat('MMM d');

    final map = <String, _ReportSummary>{};
    for (final tx in transactions) {
      final key = dateFormatter.format(tx.date);
      map.putIfAbsent(key, () => const _ReportSummary(income: 0, expense: 0));
      final current = map[key]!;
      map[key] = switch (tx.type) {
        TransactionType.income => current.copyWith(
          income: current.income + tx.amount,
        ),
        TransactionType.expense => current.copyWith(
          expense: current.expense + tx.amount,
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
        net: stats.balance,
      );
    }).toList();
  }

  Future<_PdfFontBundle> _loadPdfFontBundle() async {
    final base = pw.Font.ttf(
      await rootBundle.load(_PdfReportFonts.notoSansRegular),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load(_PdfReportFonts.notoSansBold),
    );
    final sinhalaRegular = pw.Font.ttf(
      await rootBundle.load(_PdfReportFonts.notoSansSinhalaRegular),
    );
    final sinhalaBold = pw.Font.ttf(
      await rootBundle.load(_PdfReportFonts.notoSansSinhalaBold),
    );
    final symbols = pw.Font.ttf(
      await rootBundle.load(_PdfReportFonts.notoSansSymbols),
    );

    return _PdfFontBundle(
      base: base,
      bold: bold,
      fallback: [sinhalaRegular, sinhalaBold, symbols],
    );
  }

  pw.TextStyle _pdfTextStyle({
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? _PdfReportPalette.textPrimary,
    );
  }

  String _formatPdfAmount(String currency, double value) {
    return '$currency${value.toStringAsFixed(2)}';
  }

  String _truncatePdfText(String value, int maxChars) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return '-';
    }
    if (compact.length <= maxChars) {
      return compact;
    }
    if (maxChars <= 3) {
      return compact.substring(0, maxChars);
    }
    return '${compact.substring(0, maxChars - 3)}...';
  }

  List<_CategoryBreakdown> _buildCategoryBreakdown(List<Transaction> filtered) {
    final map = <String, _ReportSummary>{};

    for (final tx in filtered) {
      final category = tx.category.trim().isEmpty
          ? 'Uncategorized'
          : tx.category.trim();
      map.putIfAbsent(
        category,
        () => const _ReportSummary(income: 0, expense: 0),
      );
      final current = map[category]!;
      map[category] = switch (tx.type) {
        TransactionType.income => current.copyWith(
          income: current.income + tx.amount,
        ),
        TransactionType.expense => current.copyWith(
          expense: current.expense + tx.amount,
        ),
      };
    }

    final rows = map.entries
        .map(
          (entry) => _CategoryBreakdown(
            category: entry.key,
            income: entry.value.income,
            expense: entry.value.expense,
          ),
        )
        .toList();

    rows.sort((a, b) => b.totalFlow.compareTo(a.totalFlow));
    return rows;
  }

  pw.Widget _buildPdfHeader({
    required String generatedAt,
    required String dateFilter,
    required String typeFilter,
    required int rowCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _PdfReportPalette.headerSoft,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _PdfReportPalette.brandSoftBorder),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Money Manager Report',
                style: _pdfTextStyle(size: 21, bold: true),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: _PdfReportPalette.brand,
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(
                  'EXECUTIVE VIEW',
                  style: _pdfTextStyle(
                    size: 8,
                    bold: true,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated on $generatedAt',
            style: _pdfTextStyle(
              size: 10,
              color: _PdfReportPalette.textSecondary,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPdfFilterChip('Date: $dateFilter'),
              _buildPdfFilterChip('Type: $typeFilter'),
              _buildPdfFilterChip('Rows: $rowCount'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFilterChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _PdfReportPalette.border),
      ),
      child: pw.Text(
        label,
        style: _pdfTextStyle(size: 9, color: _PdfReportPalette.textSecondary),
      ),
    );
  }

  pw.Widget _buildPdfSummaryCards({
    required _ReportSummary summary,
    required double savingWalletBalance,
    required String currency,
  }) {
    final metrics = [
      _PdfMetric(
        label: 'Income',
        value: summary.income,
        tone: _PdfReportPalette.brand,
        tint: _PdfReportPalette.brandSoft,
      ),
      _PdfMetric(
        label: 'Expense',
        value: summary.expense,
        tone: _PdfReportPalette.expense,
        tint: _PdfReportPalette.expenseSoft,
      ),
      _PdfMetric(
        label: 'Saving Wallet',
        value: savingWalletBalance,
        tone: _PdfReportPalette.savings,
        tint: _PdfReportPalette.savingsSoft,
      ),
      _PdfMetric(
        label: 'Net Balance',
        value: summary.balance,
        tone: summary.balance >= 0
            ? _PdfReportPalette.netPositive
            : _PdfReportPalette.netNegative,
        tint: summary.balance >= 0
            ? _PdfReportPalette.netPositiveSoft
            : _PdfReportPalette.netNegativeSoft,
      ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Executive Snapshot',
          style: _pdfTextStyle(size: 12, bold: true),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: metrics
              .map(
                (metric) =>
                    _buildPdfMetricCard(metric: metric, currency: currency),
              )
              .toList(),
        ),
      ],
    );
  }

  pw.Widget _buildPdfMetricCard({
    required _PdfMetric metric,
    required String currency,
  }) {
    return pw.Container(
      width: 118,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: pw.BoxDecoration(
        color: metric.tint,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: metric.tone),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            metric.label,
            style: _pdfTextStyle(
              size: 9,
              color: _PdfReportPalette.textSecondary,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _formatPdfAmount(currency, metric.value),
            style: _pdfTextStyle(size: 12, bold: true, color: metric.tone),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfCategoryBreakdown({
    required List<_CategoryBreakdown> categories,
    required String currency,
  }) {
    final totalFlow = categories.fold<double>(
      0,
      (sum, item) => sum + item.totalFlow,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Breakdown',
          style: _pdfTextStyle(size: 12, bold: true),
        ),
        pw.SizedBox(height: 6),
        if (categories.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _PdfReportPalette.rowAlternate,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _PdfReportPalette.border),
            ),
            child: pw.Text(
              'No category data available for the selected filters.',
              style: _pdfTextStyle(
                size: 9,
                color: _PdfReportPalette.textSecondary,
              ),
            ),
          )
        else
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(2.3),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.5),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(0.9),
            },
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _PdfReportPalette.border),
              verticalInside: pw.BorderSide(color: _PdfReportPalette.border),
              top: pw.BorderSide(color: _PdfReportPalette.border),
              bottom: pw.BorderSide(color: _PdfReportPalette.border),
              left: pw.BorderSide(color: _PdfReportPalette.border),
              right: pw.BorderSide(color: _PdfReportPalette.border),
            ),
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: _PdfReportPalette.tableHeader,
                ),
                children: [
                  _buildPdfHeaderCell('Category'),
                  _buildPdfHeaderCell('Income'),
                  _buildPdfHeaderCell('Expense'),
                  _buildPdfHeaderCell('Net'),
                  _buildPdfHeaderCell('Share'),
                ],
              ),
              ...List.generate(categories.length, (index) {
                final item = categories[index];
                final share = totalFlow <= 0
                    ? 0
                    : (item.totalFlow / totalFlow * 100);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: index.isEven
                        ? PdfColors.white
                        : _PdfReportPalette.rowAlternate,
                  ),
                  children: [
                    _buildPdfBodyCell(_truncatePdfText(item.category, 28)),
                    _buildPdfBodyCell(
                      _formatPdfAmount(currency, item.income),
                      alignment: pw.Alignment.centerRight,
                      color: _PdfReportPalette.brand,
                    ),
                    _buildPdfBodyCell(
                      _formatPdfAmount(currency, item.expense),
                      alignment: pw.Alignment.centerRight,
                      color: _PdfReportPalette.expense,
                    ),
                    _buildPdfBodyCell(
                      _formatPdfAmount(currency, item.net),
                      alignment: pw.Alignment.centerRight,
                      color: item.net >= 0
                          ? _PdfReportPalette.netPositive
                          : _PdfReportPalette.netNegative,
                    ),
                    _buildPdfBodyCell(
                      '${share.toStringAsFixed(1)}%',
                      alignment: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildPdfTransactionsTable({
    required List<Transaction> filtered,
    required Map<int, String> walletMap,
    required String currency,
    required DateFormat dateFormat,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Filtered Transactions (${filtered.length} rows)',
          style: _pdfTextStyle(size: 12, bold: true),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(1.8),
            1: pw.FlexColumnWidth(2.2),
            2: pw.FlexColumnWidth(1.8),
            3: pw.FlexColumnWidth(1.1),
            4: pw.FlexColumnWidth(1.9),
            5: pw.FlexColumnWidth(1.6),
          },
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _PdfReportPalette.border),
            verticalInside: pw.BorderSide(color: _PdfReportPalette.border),
            top: pw.BorderSide(color: _PdfReportPalette.border),
            bottom: pw.BorderSide(color: _PdfReportPalette.border),
            left: pw.BorderSide(color: _PdfReportPalette.border),
            right: pw.BorderSide(color: _PdfReportPalette.border),
          ),
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: _PdfReportPalette.tableHeader,
              ),
              children: [
                _buildPdfHeaderCell('Date'),
                _buildPdfHeaderCell('Title'),
                _buildPdfHeaderCell('Category'),
                _buildPdfHeaderCell('Type'),
                _buildPdfHeaderCell('Wallet'),
                _buildPdfHeaderCell(
                  'Amount',
                  alignment: pw.Alignment.centerRight,
                ),
              ],
            ),
            ...List.generate(filtered.length, (index) {
              final tx = filtered[index];
              final walletName =
                  walletMap[tx.walletId] ?? 'Wallet #${tx.walletId}';
              final amountPrefix = tx.type == TransactionType.income
                  ? '+'
                  : '-';
              final amountColor = tx.type == TransactionType.income
                  ? _PdfReportPalette.brand
                  : _PdfReportPalette.expense;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index.isEven
                      ? PdfColors.white
                      : _PdfReportPalette.rowAlternate,
                ),
                children: [
                  _buildPdfBodyCell(dateFormat.format(tx.date)),
                  _buildPdfBodyCell(_truncatePdfText(tx.title, 26)),
                  _buildPdfBodyCell(_truncatePdfText(tx.category, 20)),
                  _buildPdfBodyCell(tx.type.name.toUpperCase()),
                  _buildPdfBodyCell(_truncatePdfText(walletName, 22)),
                  _buildPdfBodyCell(
                    '$amountPrefix${_formatPdfAmount(currency, tx.amount)}',
                    alignment: pw.Alignment.centerRight,
                    color: amountColor,
                    bold: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfHeaderCell(String text, {pw.Alignment? alignment}) {
    return pw.Container(
      alignment: alignment ?? pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: pw.Text(text, style: _pdfTextStyle(size: 9.5, bold: true)),
    );
  }

  pw.Widget _buildPdfBodyCell(
    String text, {
    pw.Alignment? alignment,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Container(
      alignment: alignment ?? pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: pw.Text(
        text,
        style: _pdfTextStyle(size: 9, bold: bold, color: color),
      ),
    );
  }

  Future<void> _downloadPdfReport(
    List<Transaction> filtered,
    String currency,
    double savingWalletBalance,
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

      final fonts = await _loadPdfFontBundle();
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fonts.base,
          bold: fonts.bold,
          fontFallback: fonts.fallback,
        ),
      );
      final generatedAt = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final summary = _buildSummary(filtered);
      final categories = _buildCategoryBreakdown(filtered);
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          // Allow large exports in debug mode (default is 20 pages).
          maxPages: 500,
          margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 24),
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 8),
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: _pdfTextStyle(
                  size: 8,
                  color: _PdfReportPalette.textSecondary,
                ),
              ),
            );
          },
          build: (context) {
            return [
              _buildPdfHeader(
                generatedAt: generatedAt,
                dateFilter: _dateRangeFilter.label,
                typeFilter: _typeFilter?.name.toUpperCase() ?? 'ALL',
                rowCount: filtered.length,
              ),
              pw.SizedBox(height: 12),
              _buildPdfSummaryCards(
                summary: summary,
                savingWalletBalance: savingWalletBalance,
                currency: currency,
              ),
              pw.SizedBox(height: 12),
              _buildPdfCategoryBreakdown(
                categories: categories,
                currency: currency,
              ),
              pw.SizedBox(height: 12),
              _buildPdfTransactionsTable(
                filtered: filtered,
                walletMap: walletMap,
                currency: currency,
                dateFormat: dateFormat,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'End of report',
                style: _pdfTextStyle(
                  size: 8,
                  color: _PdfReportPalette.textSecondary,
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
    } on pw.TooManyPagesException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report is too large to render at once. Please narrow the filters and try again.',
          ),
        ),
      );
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
    required this.net,
  });

  final String label;
  final double income;
  final double expense;
  final double net;
}

class _ReportSummary {
  const _ReportSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  double get balance => income - expense;

  _ReportSummary copyWith({double? income, double? expense}) {
    return _ReportSummary(
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}

class _PdfMetric {
  const _PdfMetric({
    required this.label,
    required this.value,
    required this.tone,
    required this.tint,
  });

  final String label;
  final double value;
  final PdfColor tone;
  final PdfColor tint;
}

class _CategoryBreakdown {
  const _CategoryBreakdown({
    required this.category,
    required this.income,
    required this.expense,
  });

  final String category;
  final double income;
  final double expense;

  double get net => income - expense;
  double get totalFlow => income + expense;
}

class _PdfFontBundle {
  const _PdfFontBundle({
    required this.base,
    required this.bold,
    required this.fallback,
  });

  final pw.Font base;
  final pw.Font bold;
  final List<pw.Font> fallback;
}

abstract final class _PdfReportFonts {
  static const String notoSansRegular = 'assets/fonts/NotoSans-Regular.ttf';
  static const String notoSansBold = 'assets/fonts/NotoSans-Bold.ttf';
  static const String notoSansSinhalaRegular =
      'assets/fonts/NotoSansSinhala-Regular.ttf';
  static const String notoSansSinhalaBold =
      'assets/fonts/NotoSansSinhala-Bold.ttf';
  static const String notoSansSymbols =
      'assets/fonts/NotoSansSymbols2-Regular.ttf';
}

abstract final class _PdfReportPalette {
  static final PdfColor brand = PdfColor.fromInt(0xFF28C76F);
  static final PdfColor brandSoft = PdfColor.fromInt(0xFFEAF8F0);
  static final PdfColor brandSoftBorder = PdfColor.fromInt(0xFFC7EDD6);
  static final PdfColor expense = PdfColor.fromInt(0xFFEA5455);
  static final PdfColor expenseSoft = PdfColor.fromInt(0xFFFDECEC);
  static final PdfColor savings = PdfColor.fromInt(0xFF8B5CF6);
  static final PdfColor savingsSoft = PdfColor.fromInt(0xFFF1ECFF);
  static final PdfColor netPositive = PdfColor.fromInt(0xFF0F766E);
  static final PdfColor netPositiveSoft = PdfColor.fromInt(0xFFE6F9F7);
  static final PdfColor netNegative = PdfColor.fromInt(0xFFB91C1C);
  static final PdfColor netNegativeSoft = PdfColor.fromInt(0xFFFEECEC);
  static final PdfColor headerSoft = PdfColor.fromInt(0xFFF7FBF8);
  static final PdfColor textPrimary = PdfColor.fromInt(0xFF111827);
  static final PdfColor textSecondary = PdfColor.fromInt(0xFF6B7280);
  static final PdfColor border = PdfColor.fromInt(0xFFE5E7EB);
  static final PdfColor tableHeader = PdfColor.fromInt(0xFFF3F4F6);
  static final PdfColor rowAlternate = PdfColor.fromInt(0xFFF9FAFB);
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
