import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'money_manager.db');

    return openDatabase(
      dbPath,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createWalletsTable(db);
        await _createWalletTransfersTable(db);
        await _createTransactionsTable(db);
        await _createWishlistTable(db);

        await _createWalletDefaultIndex(db);
        await _createSavingWalletIndex(db);
        await _createTransactionWalletIndex(db);
        await _createWalletTransferIndexes(db);

        final walletIds = await _ensureBuiltInWallets(db);
        await _migrateLegacySavingsTransactions(db, walletIds.savingWalletId);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createWishlistTable(db);
        }

        if (oldVersion < 3) {
          await _createWalletsTable(db);
          await _createWalletTransfersTable(db);
          await _createWalletDefaultIndex(db);
          await _createSavingWalletIndex(db);

          final walletIds = await _ensureBuiltInWallets(db);
          await _ensureTransactionsWalletSchema(db, walletIds.defaultWalletId);

          await _createTransactionWalletIndex(db);
          await _createWalletTransferIndexes(db);
        }

        if (oldVersion < 4) {
          await _ensureWalletKindColumn(db);
          await _createSavingWalletIndex(db);

          final walletIds = await _ensureBuiltInWallets(db);
          await _migrateLegacySavingsTransactions(db, walletIds.savingWalletId);
        }

        await _ensureWishlistColumns(db);
      },
      onOpen: (db) async {
        await _ensureWishlistColumns(db);
        await _ensureWalletScaffold(db);
      },
    );
  }

  Future<void> _ensureWalletScaffold(Database db) async {
    await _createWalletsTable(db);
    await _ensureWalletKindColumn(db);

    await _createWalletTransfersTable(db);
    await _createWalletDefaultIndex(db);
    await _createSavingWalletIndex(db);

    final walletIds = await _ensureBuiltInWallets(db);
    await _ensureTransactionsWalletSchema(db, walletIds.defaultWalletId);

    await _createTransactionWalletIndex(db);
    await _createWalletTransferIndexes(db);

    await _migrateLegacySavingsTransactions(db, walletIds.savingWalletId);
  }

  Future<void> _createTransactionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        wallet_id INTEGER NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _createTransactionWalletIndex(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_wallet_id ON transactions(wallet_id)',
    );
  }

  Future<void> _createWalletsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        wallet_kind TEXT NOT NULL DEFAULT '${AppConstants.walletKindRegular}',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _ensureWalletKindColumn(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(wallets)');
    if (tableInfo.isEmpty) return;

    final columns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!columns.contains('wallet_kind')) {
      await db.execute(
        "ALTER TABLE wallets ADD COLUMN wallet_kind TEXT NOT NULL DEFAULT '${AppConstants.walletKindRegular}'",
      );
    }

    await db.rawUpdate(
      "UPDATE wallets SET wallet_kind = ? WHERE wallet_kind IS NULL OR TRIM(wallet_kind) = ''",
      [AppConstants.walletKindRegular],
    );
  }

  Future<void> _createWalletDefaultIndex(DatabaseExecutor db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_single_default ON wallets(is_default) WHERE is_default = 1',
    );
  }

  Future<void> _createSavingWalletIndex(DatabaseExecutor db) async {
    await db.execute(
      "CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_single_saving ON wallets(wallet_kind) WHERE wallet_kind = '${AppConstants.walletKindSaving}'",
    );
  }

  Future<void> _createWalletTransfersTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallet_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_wallet_id INTEGER NOT NULL,
        to_wallet_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (from_wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT,
        FOREIGN KEY (to_wallet_id) REFERENCES wallets(id) ON DELETE RESTRICT
      )
    ''');
  }

  Future<void> _createWalletTransferIndexes(DatabaseExecutor db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_wallet_transfers_from_wallet ON wallet_transfers(from_wallet_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_wallet_transfers_to_wallet ON wallet_transfers(to_wallet_id)',
    );
  }

  Future<void> _createWishlistTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wishlist_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        estimated_price REAL NOT NULL,
        estimated_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        real_cost REAL,
        completed_date TEXT
      )
    ''');
  }

  Future<_BuiltInWalletIds> _ensureBuiltInWallets(DatabaseExecutor db) async {
    await db.rawUpdate(
      'UPDATE wallets SET wallet_kind = ? WHERE wallet_kind IS NULL OR TRIM(wallet_kind) = ""',
      [AppConstants.walletKindRegular],
    );

    int savingWalletId;
    final savingRows = await db.rawQuery(
      'SELECT id FROM wallets WHERE wallet_kind = ? ORDER BY id ASC',
      [AppConstants.walletKindSaving],
    );

    if (savingRows.isEmpty) {
      final adoptedRows = await db.rawQuery(
        'SELECT id FROM wallets WHERE LOWER(name) = ? ORDER BY id ASC LIMIT 1',
        [AppConstants.savingWalletName.toLowerCase()],
      );

      if (adoptedRows.isNotEmpty) {
        savingWalletId = (adoptedRows.first['id'] as num).toInt();
        await db.rawUpdate('UPDATE wallets SET wallet_kind = ? WHERE id = ?', [
          AppConstants.walletKindSaving,
          savingWalletId,
        ]);
      } else {
        savingWalletId = await db.rawInsert(
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
        final duplicateIds = savingRows
            .skip(1)
            .map((row) => (row['id'] as num).toInt())
            .toList();

        for (final id in duplicateIds) {
          await db.rawUpdate(
            'UPDATE wallets SET wallet_kind = ? WHERE id = ?',
            [AppConstants.walletKindRegular, id],
          );
        }
      }
    }

    await db.rawUpdate(
      'UPDATE wallets SET name = ?, wallet_kind = ?, is_default = 0 WHERE id = ?',
      [
        AppConstants.savingWalletName,
        AppConstants.walletKindSaving,
        savingWalletId,
      ],
    );

    int defaultWalletId;
    final defaultRows = await db.rawQuery(
      'SELECT id FROM wallets WHERE is_default = 1 AND wallet_kind != ? ORDER BY id ASC LIMIT 1',
      [AppConstants.walletKindSaving],
    );

    if (defaultRows.isNotEmpty) {
      defaultWalletId = (defaultRows.first['id'] as num).toInt();
    } else {
      final regularRows = await db.rawQuery(
        'SELECT id FROM wallets WHERE wallet_kind != ? ORDER BY id ASC LIMIT 1',
        [AppConstants.walletKindSaving],
      );

      if (regularRows.isNotEmpty) {
        defaultWalletId = (regularRows.first['id'] as num).toInt();
      } else {
        defaultWalletId = await db.rawInsert(
          'INSERT INTO wallets (name, is_default, wallet_kind, created_at) VALUES (?, 1, ?, ?)',
          [
            AppConstants.defaultWalletName,
            AppConstants.walletKindRegular,
            DateTime.now().toIso8601String(),
          ],
        );
      }
    }

    await db.rawUpdate(
      'UPDATE wallets SET is_default = CASE WHEN id = ? THEN 1 ELSE 0 END',
      [defaultWalletId],
    );

    return _BuiltInWalletIds(
      defaultWalletId: defaultWalletId,
      savingWalletId: savingWalletId,
    );
  }

  Future<void> _ensureTransactionsWalletSchema(
    Database db,
    int defaultWalletId,
  ) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(transactions)');

    if (tableInfo.isEmpty) {
      await _createTransactionsTable(db);
      await db.rawUpdate(
        'UPDATE transactions SET wallet_id = ? WHERE wallet_id IS NULL',
        [defaultWalletId],
      );
      return;
    }

    final columns = tableInfo.map((row) => row['name'] as String).toSet();
    final hasWalletId = columns.contains('wallet_id');

    if (hasWalletId) {
      await db.rawUpdate(
        'UPDATE transactions SET wallet_id = ? WHERE wallet_id IS NULL',
        [defaultWalletId],
      );
      return;
    }

    await db.execute('ALTER TABLE transactions RENAME TO transactions_old');

    await _createTransactionsTable(db);

    await db.rawInsert(
      '''
      INSERT INTO transactions (id, title, category, type, amount, date, wallet_id)
      SELECT id, title, category, type, amount, date, ?
      FROM transactions_old
      ''',
      [defaultWalletId],
    );

    await db.execute('DROP TABLE transactions_old');
  }

  Future<void> _migrateLegacySavingsTransactions(
    DatabaseExecutor db,
    int savingWalletId,
  ) async {
    await db.rawUpdate(
      'UPDATE transactions SET wallet_id = ? WHERE type IN (?, ?)',
      [savingWalletId, 'savings', 'savingDeduct'],
    );

    await db.rawUpdate('UPDATE transactions SET type = ? WHERE type = ?', [
      'income',
      'savings',
    ]);

    await db.rawUpdate('UPDATE transactions SET type = ? WHERE type = ?', [
      'expense',
      'savingDeduct',
    ]);
  }

  Future<void> _ensureWishlistColumns(Database db) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(wishlist_items)');
    if (tableInfo.isEmpty) return;

    final columns = tableInfo.map((row) => row['name'] as String).toSet();

    if (!columns.contains('is_completed')) {
      await db.execute(
        'ALTER TABLE wishlist_items ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!columns.contains('real_cost')) {
      await db.execute('ALTER TABLE wishlist_items ADD COLUMN real_cost REAL');
    }
    if (!columns.contains('completed_date')) {
      await db.execute(
        'ALTER TABLE wishlist_items ADD COLUMN completed_date TEXT',
      );
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
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
