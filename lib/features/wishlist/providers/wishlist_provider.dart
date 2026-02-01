import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../models/wishlist_item.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository();
});

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  late final WishlistRepository _repository;

  @override
  Future<List<WishlistItem>> build() async {
    _repository = ref.watch(wishlistRepositoryProvider);
    return _repository.getAllItems();
  }

  Future<void> add(WishlistItem item) async {
    final id = await _repository.insertItem(item);
    final newItem = item.copyWith(id: id);
    final previousState = await future;
    state = AsyncValue.data([...previousState, newItem]);
  }

  Future<void> remove(int id) async {
    await _repository.deleteItem(id);
    final previousState = await future;
    state = AsyncValue.data(
      previousState.where((item) => item.id != id).toList(),
    );
  }

  Future<void> toggleComplete(int id) async {
    final previousState = await future;
    final itemIndex = previousState.indexWhere((i) => i.id == id);
    if (itemIndex != -1) {
      final item = previousState[itemIndex];
      final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
      await _repository.updateItem(updatedItem);

      // Update local state
      final newState = [...previousState];
      newState[itemIndex] = updatedItem;
      state = AsyncValue.data(newState);
    }
  }

  Future<void> updateItem(WishlistItem updatedItem) async {
    await _repository.updateItem(updatedItem);
    final previousState = await future;
    state = AsyncValue.data(
      previousState.map((item) {
        if (item.id == updatedItem.id) {
          return updatedItem;
        }
        return item;
      }).toList(),
    );
  }
}

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(
      WishlistNotifier.new,
    );
