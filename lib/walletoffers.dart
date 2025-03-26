// ============================================
// walletoffers.dart
// ============================================
// Handles offer creation, trade listing,
// cancellation, withdrawal, and disputes.
// Used by trade_screen.dart
// ============================================

import 'package:haveno/haveno.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';

class WalletOffers {
  static const _host = "127.0.0.1";
  static const _port = 9999;

  /// Post an XMR trade offer to Haveno
  static Future<bool> postOffer({
    required String direction,
    required String asset,
    required double amount,
    required String price,
  }) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final service = OffersService(client);
      final atomic = (amount * 1e12).toInt();

      await service.postOffer(PostOfferRequest(
        direction: direction == "BUY" ? TradeDirection.BUY : TradeDirection.SELL,
        amount: atomic,
        asset: asset,
        price: price,
        paymentAccountId: "default",
        minAmount: atomic,
        maxAmount: atomic,
      ));

      return true;
    } catch (e) {
      print("❌ postOffer failed, retrying...");
      return await _retryLoginAnd(() => postOffer(
        direction: direction,
        asset: asset,
        amount: amount,
        price: price,
      ));
    }
  }

  /// Return a list of current trades (from getTrades)
  static Future<List<TradeInfo>> loadTrades() async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final reply = await client.tradeService.getTrades(GetTradesRequest());
      return reply.trades;
    } catch (e) {
      print("❌ loadTrades failed, retrying...");
      return await _retryLoginAnd(loadTrades);
    }
  }

  /// Withdraw funds from a trade to a given address
  static Future<void> withdrawFunds(String tradeId, String address) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.withdrawFunds(
        WithdrawFundsRequest(tradeId: tradeId, address: address),
      );
    } catch (e) {
      print("❌ withdrawFunds failed, retrying...");
      await _retryLoginAnd(() => withdrawFunds(tradeId, address));
    }
  }

  /// Open a dispute for a trade
  static Future<void> openDispute(String tradeId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.openDispute(OpenDisputeRequest(tradeId: tradeId));
    } catch (e) {
      print("❌ openDispute failed, retrying...");
      await _retryLoginAnd(() => openDispute(tradeId));
    }
  }

  /// Cancel an offer by offer ID
  static Future<bool> cancelOffer(String offerId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final service = OffersService(client);
      await service.cancelOffer(CancelOfferRequest(offerId: offerId));
      return true;
    } catch (e) {
      print("❌ cancelOffer failed, retrying...");
      try {
        await _retryLoginAnd(() async {
          final client = HavenoClient(host: _host, port: _port);
          final service = OffersService(client);
          await service.cancelOffer(CancelOfferRequest(offerId: offerId));
        });
        return true;
      } catch (finalErr) {
        print("❌ Final cancelOffer failed: $finalErr");
        return false;
      }
    }
  }

  /// Retry wrapper for login-required gRPC actions
  static Future<T> _retryLoginAnd<T>(Future<T> Function() action) async {
    try {
      await WalletLogout().logout();
      await WalletLogin().loginWithMnemonic(WalletMnemonic.normalized);
      return await action();
    } catch (finalErr) {
      print("❌ Retried action failed: $finalErr");
      rethrow;
    }
  }
}
