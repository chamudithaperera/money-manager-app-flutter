import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
    bool clearProfileImage = false,
  }) {
    return SettingsState(
      displayName: displayName ?? this.displayName,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      profileImagePath: clearProfileImage
          ? null
          : profileImagePath ?? this.profileImagePath,
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
    String? imagePath = prefs.getString(_keyProfileImage);
    final documents = await getApplicationDocumentsDirectory();

    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        if (!p.isWithin(documents.path, imagePath)) {
          final migrated = await _persistProfileImage(
            sourcePath: imagePath,
            documentsDir: documents,
          );
          imagePath = migrated;
          await prefs.setString(_keyProfileImage, imagePath);
        }
      } else {
        await prefs.remove(_keyProfileImage);
        imagePath = null;
      }
    }

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
    final documents = await getApplicationDocumentsDirectory();
    final storedPath = await _persistProfileImage(
      sourcePath: path,
      documentsDir: documents,
    );

    final previous = state.value?.profileImagePath;
    await _tryDeleteOldProfileImage(previous, documents.path);

    await prefs.setString(_keyProfileImage, storedPath);
    state = AsyncValue.data(
      state.value!.copyWith(profileImagePath: storedPath),
    );
  }

  Future<void> clearProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfileImage);
    await _tryDeleteOldProfileImage(
      state.value?.profileImagePath,
      (await getApplicationDocumentsDirectory()).path,
    );
    state = AsyncValue.data(state.value!.copyWith(clearProfileImage: true));
  }

  Future<String> _persistProfileImage({
    required String sourcePath,
    required Directory documentsDir,
  }) async {
    final profileDir = Directory(p.join(documentsDir.path, 'profile'));
    await profileDir.create(recursive: true);

    final extension = p.extension(sourcePath);
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final fileName =
        'profile_${DateTime.now().millisecondsSinceEpoch}$safeExtension';
    final targetPath = p.join(profileDir.path, fileName);

    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  Future<void> _tryDeleteOldProfileImage(
    String? previousPath,
    String documentsPath,
  ) async {
    if (previousPath == null) return;
    if (!p.isWithin(documentsPath, previousPath)) return;
    final previousFile = File(previousPath);
    if (await previousFile.exists()) {
      await previousFile.delete();
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
