import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../../../features/home/models/transaction.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/transaction_providers.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import 'wallet_transfer_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(databaseProvider));
});

class WalletNotifier extends AsyncNotifier<List<Wallet>> {
  WalletRepository get _repository => ref.read(walletRepositoryProvider);

  @override
  Future<List<Wallet>> build() async {
    await _repository.ensureDefaultWallet();
    return _repository.getAll();
  }

  Future<void> createWallet(String name) async {
    await _repository.create(name);
    await _refresh();
  }

  Future<void> renameWallet({
    required int walletId,
    required String name,
  }) async {
    await _repository.rename(walletId, name);
    await _refresh();
  }

  Future<void> deleteWallet(int walletId) async {
    await _repository.deleteWithReassign(walletId);
    await _refresh();
    ref.invalidate(transactionsProvider);
    ref.invalidate(walletTransfersProvider);
  }

  Future<void> ensureDefaultWallet() async {
    await _repository.ensureDefaultWallet();
    await _refresh();
  }

  Future<void> _refresh() async {
    final items = await _repository.getAll();
    state = AsyncValue.data(items);
  }
}

final walletsProvider = AsyncNotifierProvider<WalletNotifier, List<Wallet>>(
  WalletNotifier.new,
);

final walletNameMapProvider = Provider<Map<int, String>>((ref) {
  final wallets = ref.watch(walletsProvider).value ?? const [];
  return {
    for (final wallet in wallets)
      if (wallet.id != null) wallet.id!: wallet.name,
  };
});

final defaultWalletProvider = Provider<Wallet?>((ref) {
  final wallets = ref.watch(walletsProvider).value ?? const [];
  if (wallets.isEmpty) return null;

  final maybeDefault = wallets.where((wallet) => wallet.isDefault);
  if (maybeDefault.isNotEmpty) {
    return maybeDefault.first;
  }

  return wallets.first;
});

class WalletSummary {
  const WalletSummary({
    required this.wallet,
    required this.income,
    required this.expense,
    required this.savings,
    required this.savingDeduct,
    required this.transferIn,
    required this.transferOut,
    required this.balance,
  });

  final Wallet wallet;
  final double income;
  final double expense;
  final double savings;
  final double savingDeduct;
  final double transferIn;
  final double transferOut;
  final double balance;

  double get netSavings => savings - savingDeduct;
}

final walletSummariesProvider = Provider<List<WalletSummary>>((ref) {
  final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
  final transactions =
      ref.watch(transactionsProvider).value ?? const <Transaction>[];
  final transfers =
      ref.watch(walletTransfersProvider).value ?? const <WalletTransfer>[];

  if (wallets.isEmpty) {
    return const [];
  }

  final accByWalletId = {
    for (final wallet in wallets)
      if (wallet.id != null) wallet.id!: _WalletAccumulator(),
  };

  for (final tx in transactions) {
    final acc = accByWalletId[tx.walletId];
    if (acc == null) continue;

    switch (tx.type) {
      case TransactionType.income:
        acc.income += tx.amount;
        break;
      case TransactionType.expense:
        acc.expense += tx.amount;
        break;
      case TransactionType.savings:
        acc.savings += tx.amount;
        break;
      case TransactionType.savingDeduct:
        acc.savingDeduct += tx.amount;
        break;
    }
  }

  for (final transfer in transfers) {
    final fromAcc = accByWalletId[transfer.fromWalletId];
    final toAcc = accByWalletId[transfer.toWalletId];

    if (fromAcc != null) {
      fromAcc.transferOut += transfer.amount;
    }

    if (toAcc != null) {
      toAcc.transferIn += transfer.amount;
    }
  }

  return wallets.where((wallet) => wallet.id != null).map((wallet) {
    final acc = accByWalletId[wallet.id!]!;
    final balance =
        acc.income -
        acc.expense -
        acc.savings +
        acc.transferIn -
        acc.transferOut;

    return WalletSummary(
      wallet: wallet,
      income: acc.income,
      expense: acc.expense,
      savings: acc.savings,
      savingDeduct: acc.savingDeduct,
      transferIn: acc.transferIn,
      transferOut: acc.transferOut,
      balance: balance,
    );
  }).toList();
});

final totalWalletBalanceProvider = Provider<double>((ref) {
  final summaries = ref.watch(walletSummariesProvider);
  return summaries.fold(0.0, (sum, item) => sum + item.balance);
});

class _WalletAccumulator {
  _WalletAccumulator();

  double income = 0;
  double expense = 0;
  double savings = 0;
  double savingDeduct = 0;
  double transferIn = 0;
  double transferOut = 0;
}
