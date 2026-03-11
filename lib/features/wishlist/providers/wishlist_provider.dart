import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/wishlist_repository.dart';
import '../models/wishlist_event.dart';
import '../models/wishlist_item.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository();
});

@immutable
class WishlistEventData {
  const WishlistEventData({required this.event, required this.items});

  final WishlistEvent event;
  final List<WishlistItem> items;

  double get totalPrice => items.fold<double>(
    0,
    (sum, item) => sum + (item.realCost ?? item.estimatedPrice),
  );

  int get pendingCount => items.where((item) => !item.isCompleted).length;

  int get completedCount => items.where((item) => item.isCompleted).length;

  WishlistEventData copyWith({
    WishlistEvent? event,
    List<WishlistItem>? items,
  }) {
    return WishlistEventData(
      event: event ?? this.event,
      items: items ?? this.items,
    );
  }
}

WishlistEventData? findWishlistEventById(
  List<WishlistEventData> events,
  int eventId,
) {
  for (final event in events) {
    if (event.event.id == eventId) {
      return event;
    }
  }
  return null;
}

class WishlistNotifier extends AsyncNotifier<List<WishlistEventData>> {
  late final WishlistRepository _repository;

  @override
  Future<List<WishlistEventData>> build() async {
    _repository = ref.watch(wishlistRepositoryProvider);
    return _loadState();
  }

  Future<int?> addEvent(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;

    final event = WishlistEvent(name: trimmedName, createdAt: DateTime.now());
    final id = await _repository.insertEvent(event);
    final created = event.copyWith(id: id);
    final previousState = await _currentState();

    state = AsyncValue.data([
      WishlistEventData(event: created, items: const []),
      ...previousState,
    ]);
    return id;
  }

  Future<void> updateEventName({
    required int eventId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final previousState = await _currentState();
    final eventIndex = previousState.indexWhere(
      (entry) => entry.event.id == eventId,
    );
    if (eventIndex == -1) return;

    final existing = previousState[eventIndex];
    final updatedEvent = existing.event.copyWith(name: trimmedName);
    await _repository.updateEvent(updatedEvent);

    final nextState = [...previousState];
    nextState[eventIndex] = existing.copyWith(event: updatedEvent);
    state = AsyncValue.data(nextState);
  }

  Future<void> removeEvent(int eventId) async {
    await _repository.deleteEvent(eventId);
    final previousState = await _currentState();
    state = AsyncValue.data(
      previousState.where((entry) => entry.event.id != eventId).toList(),
    );
  }

  Future<void> addItem(WishlistItem item) async {
    final id = await _repository.insertItem(item);
    final newItem = item.copyWith(id: id);
    final previousState = await _currentState();
    state = AsyncValue.data(_upsertItem(previousState, newItem));
  }

  Future<void> removeItem(int id) async {
    await _repository.deleteItem(id);
    final previousState = await _currentState();

    state = AsyncValue.data(
      previousState.map((entry) {
        return entry.copyWith(
          items: entry.items.where((item) => item.id != id).toList(),
        );
      }).toList(),
    );
  }

  Future<void> markCompleted({
    required int id,
    required double realCost,
    required DateTime completedDate,
  }) async {
    final previousState = await _currentState();
    final item = _findItemById(previousState, id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      isCompleted: true,
      realCost: realCost,
      completedDate: completedDate,
    );
    await _repository.updateItem(updatedItem);
    state = AsyncValue.data(_upsertItem(previousState, updatedItem));
  }

  Future<void> markPending(int id) async {
    final previousState = await _currentState();
    final item = _findItemById(previousState, id);
    if (item == null) return;

    final updatedItem = item.copyWith(
      isCompleted: false,
      clearCompletionData: true,
    );
    await _repository.updateItem(updatedItem);
    state = AsyncValue.data(_upsertItem(previousState, updatedItem));
  }

  Future<void> updateItem(WishlistItem updatedItem) async {
    await _repository.updateItem(updatedItem);
    final previousState = await _currentState();
    state = AsyncValue.data(_upsertItem(previousState, updatedItem));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadState());
  }

  Future<List<WishlistEventData>> _loadState() async {
    final events = await _repository.getAllEvents();
    final items = await _repository.getAllItems();
    final groupedItems = <int, List<WishlistItem>>{};

    for (final item in items) {
      groupedItems.putIfAbsent(item.eventId, () => []).add(item);
    }

    return events.map((event) {
      final id = event.id;
      final eventItems = id == null
          ? const <WishlistItem>[]
          : List<WishlistItem>.from(groupedItems[id] ?? const <WishlistItem>[]);
      return WishlistEventData(event: event, items: _sortItems(eventItems));
    }).toList();
  }

  Future<List<WishlistEventData>> _currentState() async {
    final current = state.value;
    if (current != null) return current;
    return future;
  }

  WishlistItem? _findItemById(List<WishlistEventData> stateData, int itemId) {
    for (final event in stateData) {
      for (final item in event.items) {
        if (item.id == itemId) return item;
      }
    }
    return null;
  }

  List<WishlistEventData> _upsertItem(
    List<WishlistEventData> stateData,
    WishlistItem updatedItem,
  ) {
    final nextState = stateData.map((entry) {
      return entry.copyWith(items: [...entry.items]);
    }).toList();

    int sourceEventIndex = -1;
    int sourceItemIndex = -1;

    for (var i = 0; i < nextState.length; i++) {
      final itemIndex = nextState[i].items.indexWhere(
        (item) => item.id == updatedItem.id,
      );
      if (itemIndex != -1) {
        sourceEventIndex = i;
        sourceItemIndex = itemIndex;
        break;
      }
    }

    if (sourceEventIndex != -1) {
      final existingItems = [...nextState[sourceEventIndex].items];
      existingItems.removeAt(sourceItemIndex);
      nextState[sourceEventIndex] = nextState[sourceEventIndex].copyWith(
        items: _sortItems(existingItems),
      );
    }

    final targetEventIndex = nextState.indexWhere(
      (entry) => entry.event.id == updatedItem.eventId,
    );
    if (targetEventIndex == -1) {
      return nextState;
    }

    final targetItems = [...nextState[targetEventIndex].items, updatedItem];
    nextState[targetEventIndex] = nextState[targetEventIndex].copyWith(
      items: _sortItems(targetItems),
    );

    return nextState;
  }

  List<WishlistItem> _sortItems(List<WishlistItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      if (a.isCompleted) {
        final aDate = a.completedDate ?? a.estimatedDate;
        final bDate = b.completedDate ?? b.estimatedDate;
        return bDate.compareTo(aDate);
      }

      return a.estimatedDate.compareTo(b.estimatedDate);
    });
    return sorted;
  }
}

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistEventData>>(
      WishlistNotifier.new,
    );
