/// App-wide constants for My Money Manager.
abstract final class AppConstants {
  AppConstants._();

  /// Currency symbol (e.g. Rs for Sri Lankan Rupees).
  static const String currencySymbol = 'Rs';

  /// Default wallet name used when no custom wallets exist.
  static const String defaultWalletName = 'Wallet 01';

  /// Built-in saving wallet name.
  static const String savingWalletName = 'Saving Wallet';

  /// Wallet kind value for regular wallets.
  static const String walletKindRegular = 'regular';

  /// Wallet kind value for built-in saving wallet.
  static const String walletKindSaving = 'saving';

  /// User display name shown in the app.
  static const String userDisplayName = 'Chamuditha Perera';

  /// User initials for profile avatar (e.g. CP).
  static const String userInitials = 'CP';
}
