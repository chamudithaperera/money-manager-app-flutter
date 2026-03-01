import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/wallet_transfer_repository.dart';
import '../../../providers/database_provider.dart';
import '../models/wallet_transfer.dart';

final walletTransferRepositoryProvider = Provider<WalletTransferRepository>((
  ref,
) {
  return WalletTransferRepository(ref.watch(databaseProvider));
});

class WalletTransferNotifier extends AsyncNotifier<List<WalletTransfer>> {
  WalletTransferRepository get _repository =>
      ref.read(walletTransferRepositoryProvider);

  @override
  Future<List<WalletTransfer>> build() async {
    return _repository.getAll();
  }

  Future<void> createTransfer(WalletTransfer transfer) async {
    await _repository.createTransfer(transfer);
    await _refresh();
  }

  Future<void> deleteTransfer(int id) async {
    await _repository.deleteTransfer(id);
    await _refresh();
  }

  Future<void> _refresh() async {
    final items = await _repository.getAll();
    state = AsyncValue.data(items);
  }
}

final walletTransfersProvider =
    AsyncNotifierProvider<WalletTransferNotifier, List<WalletTransfer>>(
      WalletTransferNotifier.new,
    );
