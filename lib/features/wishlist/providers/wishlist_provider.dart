import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist_item.dart';

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  @override
  List<WishlistItem> build() {
    return [
      WishlistItem(
        id: '1',
        name: 'New Laptop',
        description: 'MacBook Pro M3 for development',
        estimatedPrice: 2000.0,
        estimatedDate: DateTime.now().add(const Duration(days: 60)),
      ),
      WishlistItem(
        id: '2',
        name: 'Summer Vacation',
        description: 'Trip to Japan',
        estimatedPrice: 1500.0,
        estimatedDate: DateTime.now().add(const Duration(days: 120)),
      ),
      WishlistItem(
        id: '3',
        name: 'Emergency Fund',
        description: 'Save 3 months of expenses',
        estimatedPrice: 3000.0,
        estimatedDate: DateTime.now().add(const Duration(days: 365)),
      ),
    ];
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
