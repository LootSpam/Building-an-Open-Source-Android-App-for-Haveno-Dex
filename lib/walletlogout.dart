// ============================================
// walletlogout.dart
// ============================================
// Resets mnemonic to default and simulates Haveno logout.
// Haveno client logic has been removed since 'haveno.dart' is not used.
// ============================================

import 'walletlogin.dart';

class WalletLogout {
  /// Logs out the user by resetting their saved mnemonic.
  /// Optionally could integrate Haveno daemon's logout method later.
  Future<void> logout() async {
    try {
      await WalletLogin.resetMnemonicToDefault();
      print("🔒 Wallet mnemonic reset to default.");
    } catch (e) {
      print("❌ Logout error: $e");
    }
  }
}
