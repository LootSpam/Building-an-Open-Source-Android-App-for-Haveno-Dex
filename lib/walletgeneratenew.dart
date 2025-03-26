// ============================================
// walletgeneratenew.dart
// ============================================
// Generates a Haveno wallet via CreateAccountRequest
// and auto-logs in using walletlogin.dart
// ============================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haveno/haveno.dart';
import 'walletlogin.dart';

class WalletGenerateNew {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _mnemonicKey = "user_wallet_mnemonic";

  final String host;
  final int port;

  late final HavenoClient _client;
  late final WalletService _walletService;

  WalletGenerateNew(this.host, this.port) {
    _client = HavenoClient(host: host, port: port);
    _walletService = WalletService(_client);
  }

  /// Creates a new wallet account on Haveno and logs in.
  Future<String> generateNewWallet({String password = 'default'}) async {
    try {
      final request = CreateAccountRequest(password: password);
      final response = await _walletService.createAccount(request);
      final mnemonic = response.mnemonic;

      if (mnemonic.isEmpty) {
        print("❌ Haveno returned empty mnemonic.");
        return "";
      }

      await WalletMnemonic.save(mnemonic);
      print("✅ New mnemonic saved and initialized.");

      await WalletLogin(host, port).loginWithMnemonic(WalletMnemonic.normalized);
      return mnemonic;
    } catch (e) {
      print("❌ Error generating wallet: $e");
      return "";
    }
  }
}
