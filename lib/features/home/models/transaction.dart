import 'package:flutter/foundation.dart';

enum TransactionType { income, expense, savings }

@immutable
class Transaction {
  const Transaction({
    this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
  });

  final int? id;
  final String title;
  final String category;
  final TransactionType type;
  final double amount;
  final DateTime date;

  Transaction copyWith({
    int? id,
    String? title,
    String? category,
    TransactionType? type,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'title': title,
      'category': category,
      'type': type.name,
      'amount': amount,
      'date': date.toIso8601String(),
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String,
      type: TransactionType.values.byName(map['type'] as String),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
