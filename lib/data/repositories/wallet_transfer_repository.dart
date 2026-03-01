import '../../features/wallets/models/wallet_transfer.dart';
import '../local/app_database.dart';

class WalletTransferRepository {
  WalletTransferRepository(this._db);

  final AppDatabase _db;

  Future<List<WalletTransfer>> getAll() async {
    final database = await _db.database;
    final rows = await database.query(
      'wallet_transfers',
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((row) => WalletTransfer.fromMap(row)).toList();
  }

  Future<List<WalletTransfer>> getByWallet(int walletId) async {
    final database = await _db.database;
    final rows = await database.query(
      'wallet_transfers',
      where: 'from_wallet_id = ? OR to_wallet_id = ?',
      whereArgs: [walletId, walletId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map((row) => WalletTransfer.fromMap(row)).toList();
  }

  Future<WalletTransfer> createTransfer(WalletTransfer transfer) async {
    if (transfer.amount <= 0) {
      throw ArgumentError('Transfer amount should be greater than zero.');
    }

    if (transfer.fromWalletId == transfer.toWalletId) {
      throw ArgumentError('Source and destination wallets must be different.');
    }

    final database = await _db.database;

    return database.transaction((txn) async {
      final walletCountRows = await txn.rawQuery(
        'SELECT COUNT(*) AS count FROM wallets WHERE id IN (?, ?)',
        [transfer.fromWalletId, transfer.toWalletId],
      );

      final walletCount = (walletCountRows.first['count'] as num).toInt();
      if (walletCount != 2) {
        throw StateError('Transfer wallets were not found.');
      }

      final id = await txn.insert(
        'wallet_transfers',
        transfer.toMap(includeId: false),
      );

      return transfer.copyWith(id: id);
    });
  }

  Future<void> deleteTransfer(int id) async {
    final database = await _db.database;
    await database.delete('wallet_transfers', where: 'id = ?', whereArgs: [id]);
  }
}
