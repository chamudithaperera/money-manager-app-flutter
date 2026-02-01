import '../../features/wishlist/models/wishlist_item.dart';
import '../local/app_database.dart';

class WishlistRepository {
  Future<List<WishlistItem>> getAllItems() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'wishlist_items',
      orderBy: 'estimated_date ASC',
    );
    return result.map((map) => WishlistItem.fromMap(map)).toList();
  }

  Future<int> insertItem(WishlistItem item) async {
    final db = await AppDatabase.instance.database;
    return db.insert('wishlist_items', item.toMap());
  }

  Future<int> updateItem(WishlistItem item) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'wishlist_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('wishlist_items', where: 'id = ?', whereArgs: [id]);
  }
}
