import '../../core/constants/app_constants.dart';
import '../../features/wallets/models/wallet.dart';
import '../local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;

  Future<List<Wallet>> getAll() async {
    final database = await _db.database;
    await _ensureDefaultWalletInternal(database);

    final rows = await database.query(
      'wallets',
      orderBy: 'is_default DESC, id ASC',
    );

    return rows.map((row) => Wallet.fromMap(row)).toList();
  }

  Future<Wallet> create(String name, {bool isDefault = false}) async {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError('Wallet name cannot be empty.');
    }

    final database = await _db.database;

    return database.transaction((txn) async {
      if (isDefault) {
        await txn.rawUpdate('UPDATE wallets SET is_default = 0');
      }

      final id = await txn.rawInsert(
        'INSERT INTO wallets (name, is_default, created_at) VALUES (?, ?, ?)',
        [safeName, isDefault ? 1 : 0, DateTime.now().toIso8601String()],
      );

      await _ensureDefaultWalletInternal(txn);

      final rows = await txn.rawQuery(
        'SELECT id, name, is_default, created_at FROM wallets WHERE id = ? LIMIT 1',
        [id],
      );

      return Wallet.fromMap(rows.first);
    });
  }

  Future<void> rename(int walletId, String name) async {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError('Wallet name cannot be empty.');
    }

    final database = await _db.database;
    await database.update(
      'wallets',
      {'name': safeName},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  Future<void> deleteWithReassign(int walletId) async {
    final database = await _db.database;

    await database.transaction((txn) async {
      final targetRows = await txn.rawQuery(
        'SELECT id, is_default FROM wallets WHERE id = ? LIMIT 1',
        [walletId],
      );
      if (targetRows.isEmpty) return;

      final targetIsDefault =
          (targetRows.first['is_default'] as num).toInt() == 1;
      final currentDefaultId = await _ensureDefaultWalletInternal(txn);
      int reassignWalletId;

      if (targetIsDefault || currentDefaultId == walletId) {
        final candidateRows = await txn.rawQuery(
          'SELECT id FROM wallets WHERE id != ? ORDER BY id ASC LIMIT 1',
          [walletId],
        );

        if (candidateRows.isNotEmpty) {
          reassignWalletId = (candidateRows.first['id'] as num).toInt();
          await txn.rawUpdate(
            'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
            [reassignWalletId],
          );
        } else {
          reassignWalletId = await txn.rawInsert(
            'INSERT INTO wallets (name, is_default, created_at) VALUES (?, 1, ?)',
            [AppConstants.defaultWalletName, DateTime.now().toIso8601String()],
          );
          await txn.rawUpdate(
            'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
            [reassignWalletId],
          );
        }
      } else {
        reassignWalletId = currentDefaultId;
      }

      if (reassignWalletId == walletId) {
        reassignWalletId = await txn.rawInsert(
          'INSERT INTO wallets (name, is_default, created_at) VALUES (?, 1, ?)',
          [AppConstants.defaultWalletName, DateTime.now().toIso8601String()],
        );
        await txn.rawUpdate(
          'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
          [reassignWalletId],
        );
      }

      await txn.rawUpdate(
        'UPDATE transactions SET wallet_id = ? WHERE wallet_id = ?',
        [reassignWalletId, walletId],
      );

      await txn.rawUpdate(
        'UPDATE wallet_transfers SET from_wallet_id = ? WHERE from_wallet_id = ?',
        [reassignWalletId, walletId],
      );

      await txn.rawUpdate(
        'UPDATE wallet_transfers SET to_wallet_id = ? WHERE to_wallet_id = ?',
        [reassignWalletId, walletId],
      );

      await txn.rawDelete(
        'DELETE FROM wallet_transfers WHERE from_wallet_id = to_wallet_id',
      );

      await txn.rawDelete('DELETE FROM wallets WHERE id = ?', [walletId]);

      await _ensureDefaultWalletInternal(txn);
    });
  }

  Future<Wallet> ensureDefaultWallet() async {
    final database = await _db.database;

    return database.transaction((txn) async {
      final id = await _ensureDefaultWalletInternal(txn);
      final rows = await txn.rawQuery(
        'SELECT id, name, is_default, created_at FROM wallets WHERE id = ? LIMIT 1',
        [id],
      );
      return Wallet.fromMap(rows.first);
    });
  }

  Future<int> _ensureDefaultWalletInternal(DatabaseExecutor executor) async {
    final defaultRows = await executor.rawQuery(
      'SELECT id FROM wallets WHERE is_default = 1 ORDER BY id ASC LIMIT 1',
    );

    if (defaultRows.isNotEmpty) {
      final defaultId = (defaultRows.first['id'] as num).toInt();
      await executor.rawUpdate(
        'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
        [defaultId],
      );
      return defaultId;
    }

    final firstWalletRows = await executor.rawQuery(
      'SELECT id FROM wallets ORDER BY id ASC LIMIT 1',
    );

    if (firstWalletRows.isNotEmpty) {
      final firstId = (firstWalletRows.first['id'] as num).toInt();
      await executor.rawUpdate(
        'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
        [firstId],
      );
      return firstId;
    }

    return executor.rawInsert(
      'INSERT INTO wallets (name, is_default, created_at) VALUES (?, 1, ?)',
      [AppConstants.defaultWalletName, DateTime.now().toIso8601String()],
    );
  }
}
