import 'package:flutter/foundation.dart';

@immutable
class WalletTransfer {
  const WalletTransfer({
    this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note,
  });

  final int? id;
  final int fromWalletId;
  final int toWalletId;
  final double amount;
  final DateTime date;
  final String? note;

  WalletTransfer copyWith({
    int? id,
    int? fromWalletId,
    int? toWalletId,
    double? amount,
    DateTime? date,
    String? note,
    bool clearNote = false,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: clearNote ? null : note ?? this.note,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  factory WalletTransfer.fromMap(Map<String, Object?> map) {
    return WalletTransfer(
      id: map['id'] as int?,
      fromWalletId: (map['from_wallet_id'] as num).toInt(),
      toWalletId: (map['to_wallet_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
    );
  }
}
