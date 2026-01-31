import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/repositories/transaction_repository.dart';
import '../features/home/models/transaction.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final transactionsProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );

// Using keepAlive to cache the calculations and avoid recomputing on every rebuild
final statsProvider = Provider<HomeStats>((ref) {
  // Cache this provider to avoid unnecessary recalculations
  ref.keepAlive();

  final transactions = ref.watch(transactionsProvider).value ?? const [];

  // Early return for empty transactions
  if (transactions.isEmpty) {
    return const HomeStats(
      income: 0,
      expenses: 0,
      savings: 0,
      balance: 0,
      savingDeducts: 0,
      balanceChange: 0,
    );
  }

  double income = 0;
  double expenses = 0;
  double savings = 0;
  double savingDeducts = 0;
  double lastMonthIncome = 0;
  double lastMonthExpenses = 0;
  double lastMonthSavings = 0;

  final now = DateTime.now();
  final firstDayOfThisMonth = DateTime(now.year, now.month, 1);

  // Single pass through transactions for better performance
  for (final tx in transactions) {
    final amount = tx.amount;

    // Current totals
    switch (tx.type) {
      case TransactionType.income:
        income += amount;
        break;
      case TransactionType.expense:
        expenses += amount;
        break;
      case TransactionType.savings:
        savings += amount;
        break;
      case TransactionType.savingDeduct:
        savingDeducts += amount;
        break;
    }

    // Previous month totals (optimization: single date comparison)
    if (tx.date.isBefore(firstDayOfThisMonth)) {
      switch (tx.type) {
        case TransactionType.income:
          lastMonthIncome += amount;
          break;
        case TransactionType.expense:
          lastMonthExpenses += amount;
          break;
        case TransactionType.savings:
          lastMonthSavings += amount;
          break;
        default:
          break;
      }
    }
  }

  final netSavings = savings - savingDeducts;
  final currentBalance = income - expenses - savings;
  final lastMonthBalance =
      lastMonthIncome - lastMonthExpenses - lastMonthSavings;

  // Optimized percentage calculation
  final percentageChange = lastMonthBalance == 0
      ? (currentBalance > 0 ? 100.0 : 0.0)
      : ((currentBalance - lastMonthBalance) / lastMonthBalance.abs()) * 100;

  return HomeStats(
    income: income,
    expenses: expenses,
    savings: netSavings,
    balance: currentBalance,
    savingDeducts: savingDeducts,
    balanceChange: percentageChange,
  );
});

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  @override
  Future<List<Transaction>> build() async {
    try {
      return await _repository.getAll();
    } catch (e, st) {
      debugPrint('TransactionNotifier.build failed: $e');
      debugPrintStack(stackTrace: st);
      return [];
    }
  }

  Future<void> add(Transaction transaction) async {
    final current = state.value ?? [];
    final created = await _repository.add(transaction);
    state = AsyncValue.data(_sortByDate([created, ...current]));
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _repository.update(transaction);
    final current = state.value ?? [];
    final updated = current
        .map((item) => item.id == transaction.id ? transaction : item)
        .toList();
    state = AsyncValue.data(_sortByDate(updated));
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.delete(id);
    final current = state.value ?? [];
    final updated = current.where((item) => item.id != id).toList();
    state = AsyncValue.data(_sortByDate(updated));
  }

  List<Transaction> _sortByDate(List<Transaction> list) {
    final sorted = [...list];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }
}

class HomeStats {
  const HomeStats({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.savings,
    required this.savingDeducts,
    required this.balanceChange,
  });

  final double balance;
  final double income;
  final double expenses;
  final double savings;
  final double savingDeducts;
  final double balanceChange;
}
