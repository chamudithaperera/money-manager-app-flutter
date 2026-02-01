import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist_item.dart';

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  @override
  List<WishlistItem> build() {
    return [];
  }

  void add(WishlistItem item) {
    state = [...state, item];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void toggleComplete(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
  }

  void update(WishlistItem updatedItem) {
    state = state.map((item) {
      if (item.id == updatedItem.id) {
        return updatedItem;
      }
      return item;
    }).toList();
  }
}

final wishlistProvider = NotifierProvider<WishlistNotifier, List<WishlistItem>>(
  WishlistNotifier.new,
);
