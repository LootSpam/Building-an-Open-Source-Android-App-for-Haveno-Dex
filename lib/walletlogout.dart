// ============================================
// walletlogout.dart
// ============================================
// Calls Haveno's closeAccount and resets mnemonic to default.
// ============================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haveno/haveno.dart';

class WalletLogout {
  final _storage = const FlutterSecureStorage();
  final String _mnemonicKey = "user_wallet_mnemonic";
  final String _defaultMnemonic =
      "avoid violin chat cover jacket talk quote aware verb milk example talk win output pudding trick";

  Future<void> logout({String host = "127.0.0.1", int port = 9999}) async {
    try {
      final client = HavenoClient(host: host, port: port);
      final accountService = AccountService(client);
      await accountService.closeAccount();
      await _storage.write(key: _mnemonicKey, value: _defaultMnemonic);
      print("🔒 Wallet closed and mnemonic reset.");
    } catch (e) {
      print("❌ Haveno logout error: $e");
    }
  }
}