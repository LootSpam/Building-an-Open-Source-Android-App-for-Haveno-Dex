// ============================================
// walletrestore.dart
// ============================================
// Restores a Haveno wallet from a saved mnemonic.
// Uses Haveno's RestoreAccountRequest with zipBytes.
// Delegates login to walletlogin.dart afterward.
// ============================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haveno/haveno.dart';
import 'walletlogin.dart';

class WalletRestore {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _mnemonicKey = "user_wallet_mnemonic";

  final String host;
  final int port;

  late final HavenoClient _client;
  late final WalletService _walletService;

  WalletRestore(this.host, this.port) {
    _client = HavenoClient(host: host, port: port);
    _walletService = WalletService(_client);
  }

  Future<bool> restoreWallet() async {
    try {
      // Ensure mnemonic is initialized and properly formatted
      await WalletMnemonic.initialize();

      if (WalletMnemonic.normalized.isEmpty) {
        print("❌ Wallet mnemonic is missing or invalid.");
        return false;
      }

      final zipBytes = WalletMnemonic.zipBytes;

      final request = RestoreAccountRequest(
        zipBytes: zipBytes,
        offset: Int64(0),
        totalLength: Int64(zipBytes.length),
        hasMore: false,
      );

      await _walletService.restoreAccount(request);
      print("✅ Wallet successfully restored via Haveno.");

      await WalletLogin(host, port).loginWithMnemonic(WalletMnemonic.normalized);
      return true;
    } catch (e) {
      print("❌ Failed to restore wallet: $e");
      return false;
    }
  }
}
