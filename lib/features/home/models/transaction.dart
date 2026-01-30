import 'package:flutter/foundation.dart';

enum TransactionType { income, expense, savings }

@immutable
class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
  });

  final String id;
  final String title;
  final String category;
  final TransactionType type;
  final double amount;
  final DateTime date;
}
