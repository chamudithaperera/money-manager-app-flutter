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

final statsProvider = Provider<HomeStats>((ref) {
  final transactions = ref.watch(transactionsProvider).value ?? const [];
  double income = 0;
  double expenses = 0;
  double savings = 0;
  double savingDeduct = 0;

  for (final tx in transactions) {
    switch (tx.type) {
      case TransactionType.income:
        income += tx.amount;
        break;
      case TransactionType.expense:
        expenses += tx.amount;
        break;
      case TransactionType.savings:
        savings += tx.amount;
        break;
      case TransactionType.savingDeduct:
        savingDeduct += tx.amount;
        break;
    }
  }

  final netSavings = savings - savingDeduct;
  final balance = income - expenses - savings;

  return HomeStats(
    income: income,
    expenses: expenses,
    savings: netSavings,
    balance: balance,
  );
});

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  @override
  Future<List<Transaction>> build() async {
    try {
      final items = await _repository.getAll();
      return _sortByDate(items);
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
  });

  final double balance;
  final double income;
  final double expenses;
  final double savings;
}
