import '../../features/wishlist/models/wishlist_event.dart';
import '../../features/wishlist/models/wishlist_item.dart';
import '../local/app_database.dart';

class WishlistRepository {
  Future<List<WishlistEvent>> getAllEvents() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'wishlist_events',
      orderBy: 'created_at DESC, id DESC',
    );
    return result.map((map) => WishlistEvent.fromMap(map)).toList();
  }

  Future<int> insertEvent(WishlistEvent event) async {
    final db = await AppDatabase.instance.database;
    return db.insert('wishlist_events', event.toMap());
  }

  Future<int> updateEvent(WishlistEvent event) async {
    final db = await AppDatabase.instance.database;
    return db.update(
      'wishlist_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> deleteEvent(int id) async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'wishlist_items',
        where: 'event_id = ?',
        whereArgs: [id],
      );
      await txn.delete('wishlist_events', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<WishlistItem>> getAllItems() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'wishlist_items',
      orderBy:
          'event_id ASC, is_completed ASC, COALESCE(completed_date, estimated_date) ASC',
    );
    return result.map((map) => WishlistItem.fromMap(map)).toList();
  }

  Future<List<WishlistItem>> getItemsByEvent(int eventId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'wishlist_items',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'is_completed ASC, COALESCE(completed_date, estimated_date) ASC',
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
