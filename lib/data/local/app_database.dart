import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await _createTransactionsTable(db);
        await _createWishlistTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createWishlistTable(db);
        }
        await _ensureWishlistColumns(db);
      },
      onOpen: _ensureWishlistColumns,
    );
  }

  Future<void> _createTransactionsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
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
