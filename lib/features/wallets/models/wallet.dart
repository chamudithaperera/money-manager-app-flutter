import 'package:flutter/foundation.dart';

@immutable
class Wallet {
  const Wallet({
    this.id,
    required this.name,
    required this.isDefault,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final bool isDefault;
  final DateTime createdAt;

  Wallet copyWith({
    int? id,
    String? name,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  factory Wallet.fromMap(Map<String, Object?> map) {
    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      isDefault: (map['is_default'] as num).toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
