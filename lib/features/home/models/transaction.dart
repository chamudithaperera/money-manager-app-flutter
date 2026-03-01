import 'package:flutter/foundation.dart';

enum TransactionType { income, expense }

@immutable
class Transaction {
  const Transaction({
    this.id,
    required this.walletId,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
  });

  final int? id;
  final int walletId;
  final String title;
  final String category;
  final TransactionType type;
  final double amount;
  final DateTime date;

  Transaction copyWith({
    int? id,
    int? walletId,
    String? title,
    String? category,
    TransactionType? type,
    double? amount,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'wallet_id': walletId,
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
    final rawType = map['type'] as String;
    final type = switch (rawType) {
      'income' => TransactionType.income,
      'expense' => TransactionType.expense,
      'savings' => TransactionType.income,
      'savingDeduct' => TransactionType.expense,
      _ => TransactionType.expense,
    };

    return Transaction(
      id: map['id'] as int?,
      walletId: (map['wallet_id'] as num).toInt(),
      title: map['title'] as String,
      category: map['category'] as String,
      type: type,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
