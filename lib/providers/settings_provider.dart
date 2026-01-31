import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  const SettingsState({
    required this.displayName,
    required this.currencySymbol,
    this.profileImagePath,
  });

  final String displayName;
  final String currencySymbol;
  final String? profileImagePath;

  String get initials {
    if (displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  SettingsState copyWith({
    String? displayName,
    String? currencySymbol,
    String? profileImagePath,
  }) {
    return SettingsState(
      displayName: displayName ?? this.displayName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _keyDisplayName = 'user_display_name';
  static const _keyCurrency = 'user_currency_symbol';
  static const _keyProfileImage = 'user_profile_image';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyDisplayName) ?? 'Your Name';
    final currency = prefs.getString(_keyCurrency) ?? 'Rs';
    final imagePath = prefs.getString(_keyProfileImage);

    return SettingsState(
      displayName: name,
      currencySymbol: currency,
      profileImagePath: imagePath,
    );
  }

  Future<void> updateDisplayName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDisplayName, newName);
    state = AsyncValue.data(state.value!.copyWith(displayName: newName));
  }

  Future<void> updateCurrency(String newCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, newCurrency);
    state = AsyncValue.data(state.value!.copyWith(currencySymbol: newCurrency));
  }

  Future<void> updateProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfileImage, path);
    state = AsyncValue.data(state.value!.copyWith(profileImagePath: path));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
