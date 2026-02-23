import 'package:flutter/foundation.dart';

@immutable
class WishlistItem {
  const WishlistItem({
    this.id,
    required this.name,
    required this.description,
    required this.estimatedPrice,
    required this.estimatedDate,
    this.isCompleted = false,
    this.realCost,
    this.completedDate,
  });

  final int? id;
  final String name;
  final String description;
  final double estimatedPrice;
  final DateTime estimatedDate;
  final bool isCompleted;
  final double? realCost;
  final DateTime? completedDate;

  WishlistItem copyWith({
    int? id,
    String? name,
    String? description,
    double? estimatedPrice,
    DateTime? estimatedDate,
    bool? isCompleted,
    double? realCost,
    DateTime? completedDate,
    bool clearCompletionData = false,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      estimatedDate: estimatedDate ?? this.estimatedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      realCost: clearCompletionData ? null : realCost ?? this.realCost,
      completedDate: clearCompletionData
          ? null
          : completedDate ?? this.completedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'estimated_price': estimatedPrice,
      'estimated_date': estimatedDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'real_cost': realCost,
      'completed_date': completedDate?.toIso8601String(),
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      estimatedPrice: (map['estimated_price'] as num).toDouble(),
      estimatedDate: DateTime.parse(map['estimated_date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
      realCost: (map['real_cost'] as num?)?.toDouble(),
      completedDate: map['completed_date'] == null
          ? null
          : DateTime.parse(map['completed_date'] as String),
    );
  }
}
