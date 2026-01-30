import '../../features/home/models/transaction.dart';
import '../local/app_database.dart';

class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Future<List<Transaction>> getAll() async {
    final database = await _db.database;
    final rows = await database.query('transactions', orderBy: 'date DESC');
    return rows.map((row) => Transaction.fromMap(row)).toList();
  }

  Future<Transaction> add(Transaction transaction) async {
    final database = await _db.database;
    final id = await database.insert(
      'transactions',
      transaction.toMap(includeId: false),
    );
    return transaction.copyWith(id: id);
  }

  Future<void> update(Transaction transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw StateError('Cannot update a transaction without an id.');
    }
    final database = await _db.database;
    await database.update(
      'transactions',
      transaction.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final database = await _db.database;
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
