import 'package:flutter/foundation.dart';

@immutable
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.description,
    required this.estimatedPrice,
    required this.estimatedDate,
    this.isCompleted = false,
  });

  final String id;
  final String name;
  final String description;
  final double estimatedPrice;
  final DateTime estimatedDate;
  final bool isCompleted;

  WishlistItem copyWith({
    String? id,
    String? name,
    String? description,
    double? estimatedPrice,
    DateTime? estimatedDate,
    bool? isCompleted,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      estimatedDate: estimatedDate ?? this.estimatedDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
