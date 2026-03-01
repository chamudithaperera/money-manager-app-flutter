import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../features/wallets/models/wallet.dart';
import '../local/app_database.dart';

class WalletRepository {
  WalletRepository(this._db);

  final AppDatabase _db;

  Future<List<Wallet>> getAll() async {
    final database = await _db.database;

    await database.transaction((txn) async {
      await _ensureBuiltInWalletsInternal(txn);
    });

    final rows = await database.rawQuery('''
      SELECT id, name, is_default, wallet_kind, created_at
      FROM wallets
      ORDER BY
        is_default DESC,
        CASE WHEN wallet_kind = '${AppConstants.walletKindSaving}' THEN 1 ELSE 0 END ASC,
        id ASC
    ''');

    return rows.map((row) => Wallet.fromMap(row)).toList();
  }

  Future<Wallet> create(String name, {bool isDefault = false}) async {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError('Wallet name cannot be empty.');
    }
    if (_isSavingWalletName(safeName)) {
      throw ArgumentError('The saving wallet name is reserved.');
    }

    final database = await _db.database;

    return database.transaction((txn) async {
      final id = await txn.rawInsert(
        'INSERT INTO wallets (name, is_default, wallet_kind, created_at) VALUES (?, 0, ?, ?)',
        [
          safeName,
          AppConstants.walletKindRegular,
          DateTime.now().toIso8601String(),
        ],
      );

      if (isDefault) {
        await _setDefaultRegularWallet(txn, id);
      }

      await _ensureBuiltInWalletsInternal(txn);

      final rows = await txn.rawQuery(
        'SELECT id, name, is_default, wallet_kind, created_at FROM wallets WHERE id = ? LIMIT 1',
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
    if (_isSavingWalletName(safeName)) {
      throw ArgumentError('The saving wallet name is reserved.');
    }

    final database = await _db.database;
    await database.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT wallet_kind FROM wallets WHERE id = ? LIMIT 1',
        [walletId],
      );

      if (rows.isEmpty) return;

      final walletKind = rows.first['wallet_kind'] as String?;
      if (walletKind == AppConstants.walletKindSaving) {
        throw StateError('Saving wallet cannot be renamed.');
      }

      await txn.update(
        'wallets',
        {'name': safeName},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    });
  }

  Future<void> deleteWithReassign(int walletId) async {
    final database = await _db.database;

    await database.transaction((txn) async {
      final targetRows = await txn.rawQuery(
        'SELECT id, is_default, wallet_kind FROM wallets WHERE id = ? LIMIT 1',
        [walletId],
      );
      if (targetRows.isEmpty) return;

      final targetKind = targetRows.first['wallet_kind'] as String?;
      if (targetKind == AppConstants.walletKindSaving) {
        throw StateError('Saving wallet cannot be deleted.');
      }

      final targetIsDefault =
          (targetRows.first['is_default'] as num).toInt() == 1;
      final walletIds = await _ensureBuiltInWalletsInternal(txn);
      int reassignWalletId;

      if (targetIsDefault || walletIds.defaultWalletId == walletId) {
        final candidateRows = await txn.rawQuery(
          'SELECT id FROM wallets WHERE id != ? AND wallet_kind = ? ORDER BY id ASC LIMIT 1',
          [walletId, AppConstants.walletKindRegular],
        );

        if (candidateRows.isNotEmpty) {
          reassignWalletId = (candidateRows.first['id'] as num).toInt();
        } else {
          reassignWalletId = await txn.rawInsert(
            'INSERT INTO wallets (name, is_default, wallet_kind, created_at) VALUES (?, 1, ?, ?)',
            [
              AppConstants.defaultWalletName,
              AppConstants.walletKindRegular,
              DateTime.now().toIso8601String(),
            ],
          );
        }

        await _setDefaultRegularWallet(txn, reassignWalletId);
      } else {
        reassignWalletId = walletIds.defaultWalletId;
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

      await _ensureBuiltInWalletsInternal(txn);
    });
  }

  Future<Wallet> ensureDefaultWallet() async {
    final database = await _db.database;

    return database.transaction((txn) async {
      final walletIds = await _ensureBuiltInWalletsInternal(txn);
      final rows = await txn.rawQuery(
        'SELECT id, name, is_default, wallet_kind, created_at FROM wallets WHERE id = ? LIMIT 1',
        [walletIds.defaultWalletId],
      );
      return Wallet.fromMap(rows.first);
    });
  }

  Future<_BuiltInWalletIds> _ensureBuiltInWalletsInternal(
    DatabaseExecutor executor,
  ) async {
    await executor.rawUpdate(
      'UPDATE wallets SET wallet_kind = ? WHERE wallet_kind IS NULL OR TRIM(wallet_kind) = ""',
      [AppConstants.walletKindRegular],
    );

    int savingWalletId;
    final savingRows = await executor.rawQuery(
      'SELECT id FROM wallets WHERE wallet_kind = ? ORDER BY id ASC',
      [AppConstants.walletKindSaving],
    );

    if (savingRows.isEmpty) {
      final adoptedRows = await executor.rawQuery(
        'SELECT id FROM wallets WHERE LOWER(name) = ? ORDER BY id ASC LIMIT 1',
        [AppConstants.savingWalletName.toLowerCase()],
      );

      if (adoptedRows.isNotEmpty) {
        savingWalletId = (adoptedRows.first['id'] as num).toInt();
        await executor.rawUpdate(
          'UPDATE wallets SET wallet_kind = ? WHERE id = ?',
          [AppConstants.walletKindSaving, savingWalletId],
        );
      } else {
        savingWalletId = await executor.rawInsert(
          'INSERT INTO wallets (name, is_default, wallet_kind, created_at) VALUES (?, 0, ?, ?)',
          [
            AppConstants.savingWalletName,
            AppConstants.walletKindSaving,
            DateTime.now().toIso8601String(),
          ],
        );
      }
    } else {
      savingWalletId = (savingRows.first['id'] as num).toInt();
      if (savingRows.length > 1) {
        for (final row in savingRows.skip(1)) {
          final duplicateId = (row['id'] as num).toInt();
          await executor.rawUpdate(
            'UPDATE wallets SET wallet_kind = ? WHERE id = ?',
            [AppConstants.walletKindRegular, duplicateId],
          );
        }
      }
    }

    await executor.rawUpdate(
      'UPDATE wallets SET name = ?, wallet_kind = ?, is_default = 0 WHERE id = ?',
      [
        AppConstants.savingWalletName,
        AppConstants.walletKindSaving,
        savingWalletId,
      ],
    );

    int defaultWalletId;
    final defaultRows = await executor.rawQuery(
      'SELECT id FROM wallets WHERE is_default = 1 AND wallet_kind = ? ORDER BY id ASC LIMIT 1',
      [AppConstants.walletKindRegular],
    );

    if (defaultRows.isNotEmpty) {
      defaultWalletId = (defaultRows.first['id'] as num).toInt();
    } else {
      final regularRows = await executor.rawQuery(
        'SELECT id FROM wallets WHERE wallet_kind = ? ORDER BY id ASC LIMIT 1',
        [AppConstants.walletKindRegular],
      );

      if (regularRows.isNotEmpty) {
        defaultWalletId = (regularRows.first['id'] as num).toInt();
      } else {
        defaultWalletId = await executor.rawInsert(
          'INSERT INTO wallets (name, is_default, wallet_kind, created_at) VALUES (?, 1, ?, ?)',
          [
            AppConstants.defaultWalletName,
            AppConstants.walletKindRegular,
            DateTime.now().toIso8601String(),
          ],
        );
      }
    }

    await _setDefaultRegularWallet(executor, defaultWalletId);

    return _BuiltInWalletIds(
      defaultWalletId: defaultWalletId,
      savingWalletId: savingWalletId,
    );
  }

  Future<void> _setDefaultRegularWallet(
    DatabaseExecutor executor,
    int walletId,
  ) async {
    await executor.rawUpdate(
      'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
      [walletId],
    );
  }

  bool _isSavingWalletName(String name) {
    return name.trim().toLowerCase() ==
        AppConstants.savingWalletName.toLowerCase();
  }
}

class _BuiltInWalletIds {
  const _BuiltInWalletIds({
    required this.defaultWalletId,
    required this.savingWalletId,
  });

  final int defaultWalletId;
  final int savingWalletId;
}
