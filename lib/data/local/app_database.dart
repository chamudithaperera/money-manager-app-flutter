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
      version: 3, // Bumped for wishlist
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE wishlist_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            estimated_price REAL NOT NULL,
            estimated_date TEXT NOT NULL,
            is_completed INTEGER NOT NULL
          )
        ''');

        // Add indexes for faster date ordering and type filtering
        await db.execute(
          'CREATE INDEX idx_transactions_date ON transactions(date DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_type ON transactions(type)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add indexes to existing database
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type)',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS wishlist_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL,
              estimated_price REAL NOT NULL,
              estimated_date TEXT NOT NULL,
              is_completed INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
