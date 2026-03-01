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
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createWalletsTable(db);
        await _createWalletTransfersTable(db);
        await _createTransactionsTable(db);
        await _createWishlistTable(db);

        await _createWalletDefaultIndex(db);
        await _createTransactionWalletIndex(db);
        await _createWalletTransferIndexes(db);

        await _ensureDefaultWallet(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createWishlistTable(db);
        }

        if (oldVersion < 3) {
          await _createWalletsTable(db);
          await _createWalletTransfersTable(db);
          await _createWalletDefaultIndex(db);

          final defaultWalletId = await _ensureDefaultWallet(db);
          await _ensureTransactionsWalletSchema(db, defaultWalletId);

          await _createTransactionWalletIndex(db);
          await _createWalletTransferIndexes(db);
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
    await _createWalletTransfersTable(db);
    await _createWalletDefaultIndex(db);

    final defaultWalletId = await _ensureDefaultWallet(db);
    await _ensureTransactionsWalletSchema(db, defaultWalletId);

    await _createTransactionWalletIndex(db);
    await _createWalletTransferIndexes(db);
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
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createWalletDefaultIndex(DatabaseExecutor db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_single_default ON wallets(is_default) WHERE is_default = 1',
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

  Future<int> _ensureDefaultWallet(DatabaseExecutor db) async {
    final defaultRows = await db.query(
      'wallets',
      columns: ['id'],
      where: 'is_default = 1',
      limit: 1,
    );

    if (defaultRows.isNotEmpty) {
      return defaultRows.first['id'] as int;
    }

    final firstWalletRows = await db.query(
      'wallets',
      columns: ['id'],
      orderBy: 'id ASC',
      limit: 1,
    );

    if (firstWalletRows.isNotEmpty) {
      final firstId = firstWalletRows.first['id'] as int;
      await db.update(
        'wallets',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [firstId],
      );
      return firstId;
    }

    return db.insert('wallets', {
      'name': AppConstants.defaultWalletName,
      'is_default': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
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
