import 'package:flutter/foundation.dart';

@immutable
class WishlistEvent {
  const WishlistEvent({this.id, required this.name, required this.createdAt});

  final int? id;
  final String name;
  final DateTime createdAt;

  WishlistEvent copyWith({int? id, String? name, DateTime? createdAt}) {
    return WishlistEvent(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WishlistEvent.fromMap(Map<String, dynamic> map) {
    return WishlistEvent(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
