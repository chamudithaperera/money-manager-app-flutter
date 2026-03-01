import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';

enum WalletKind { regular, saving }

@immutable
class Wallet {
  const Wallet({
    this.id,
    required this.name,
    required this.isDefault,
    required this.walletKind,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final bool isDefault;
  final WalletKind walletKind;
  final DateTime createdAt;

  bool get isSavingWallet => walletKind == WalletKind.saving;

  Wallet copyWith({
    int? id,
    String? name,
    bool? isDefault,
    WalletKind? walletKind,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      walletKind: walletKind ?? this.walletKind,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap({bool includeId = true}) {
    final map = <String, Object?>{
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'wallet_kind': _walletKindToStorage(walletKind),
      'created_at': createdAt.toIso8601String(),
    };

    if (includeId) {
      map['id'] = id;
    }

    return map;
  }

  factory Wallet.fromMap(Map<String, Object?> map) {
    final kindRaw = map['wallet_kind'] as String?;
    final kind = _walletKindFromStorage(kindRaw);

    return Wallet(
      id: map['id'] as int?,
      name: map['name'] as String,
      isDefault: (map['is_default'] as num).toInt() == 1,
      walletKind: kind,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static WalletKind _walletKindFromStorage(String? kind) {
    if (kind == AppConstants.walletKindSaving) {
      return WalletKind.saving;
    }
    return WalletKind.regular;
  }

  static String _walletKindToStorage(WalletKind kind) {
    switch (kind) {
      case WalletKind.regular:
        return AppConstants.walletKindRegular;
      case WalletKind.saving:
        return AppConstants.walletKindSaving;
    }
  }
}
