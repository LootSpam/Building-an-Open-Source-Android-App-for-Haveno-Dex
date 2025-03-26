// ============================================
// walletsendfunds.dart
// ============================================
// Sends funds via Haveno walletService.send()
// Defaults to XMR, supports BTC and others
// Retries login on failure
// ============================================

import 'package:haveno/haveno.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';

class WalletSendFunds {
  static const _host = '127.0.0.1';
  static const _port = 9999;

  /// Send XMR to given address (default)
  static Future<bool> send(String address, double amount) async {
    return await sendWithCurrency(
      address: address,
      amount: amount,
      currency: 'XMR',
    );
  }

  /// Send funds with specified currency (e.g. BTC, XMR)
  static Future<bool> sendWithCurrency({
    required String address,
    required double amount,
    required String currency,
  }) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final service = WalletsService(client);
      final atomic = _toAtomic(amount, currency);

      final request = SendRequest(
        address: address,
        amount: atomic,
        assetCode: currency,
      );

      await service.send(request);
      print("✅ Sent $amount $currency to $address.");
      return true;
    } catch (e) {
      print("❌ send failed, retrying login...");
      return await _retryLoginAnd(() => sendWithCurrency(
        address: address,
        amount: amount,
        currency: currency,
      ));
    }
  }

  /// Convert float to atomic units based on currency
  static int _toAtomic(double amount, String currency) {
    switch (currency.toUpperCase()) {
      case 'XMR': return (amount * 1e12).round();
      case 'BTC': return (amount * 1e8).round();
      case 'ETH': return (amount * 1e18).round();
      default:
        print("⚠️ Unknown currency '$currency', using 1e6 scaling.");
        return (amount * 1e6).round();
    }
  }

  /// Retry fallback with logout/login
  static Future<T> _retryLoginAnd<T>(Future<T> Function() action) async {
    try {
      await WalletLogout().logout();
      await WalletLogin().loginWithMnemonic(WalletMnemonic.normalized);
      return await action();
    } catch (err) {
      print("❌ Final retry failed: $err");
      return false as T;
    }
  }
}
