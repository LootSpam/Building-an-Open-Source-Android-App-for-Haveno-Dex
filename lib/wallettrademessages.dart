// ============================================
// wallettrademessages.dart
// ============================================
// Combines trade/dispute chat send/receive logic,
// plus confirmPaymentSent / confirmPaymentReceived
// ============================================

import 'package:haveno/haveno.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';

class WalletTradeMessages {
  static const _host = "127.0.0.1";
  static const _port = 9999;

  static Future<bool> sendTradeMessage(String tradeId, String message) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.sendChatMessage(
        SendChatMessageRequest(tradeId: tradeId, message: message),
      );
      return true;
    } catch (_) {
      await WalletLogout().logout();
      await WalletLogin().loginWithMnemonic(WalletMnemonic.normalized);
      try {
        final client = HavenoClient(host: _host, port: _port);
        await client.tradeService.sendChatMessage(
          SendChatMessageRequest(tradeId: tradeId, message: message),
        );
        return true;
      } catch (e) {
        print("❌ sendTradeMessage failed: $e");
        return false;
      }
    }
  }

  static Future<bool> sendDisputeMessage(String disputeId, String message) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.sendDisputeChatMessage(
        SendDisputeChatMessageRequest(disputeId: disputeId, message: message),
      );
      return true;
    } catch (_) {
      await WalletLogout().logout();
      await WalletLogin().loginWithMnemonic(WalletMnemonic.normalized);
      try {
        final client = HavenoClient(host: _host, port: _port);
        await client.tradeService.sendDisputeChatMessage(
          SendDisputeChatMessageRequest(disputeId: disputeId, message: message),
        );
        return true;
      } catch (e) {
        print("❌ sendDisputeMessage failed: $e");
        return false;
      }
    }
  }

  static Future<void> confirmPaymentSent(String tradeId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.confirmPaymentSent(
        ConfirmPaymentSentRequest(tradeId: tradeId),
      );
    } catch (e) {
      print("❌ confirmPaymentSent failed: $e");
    }
  }

  static Future<void> confirmPaymentReceived(String tradeId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      await client.tradeService.confirmPaymentReceived(
        ConfirmPaymentReceivedRequest(tradeId: tradeId),
      );
    } catch (e) {
      print("❌ confirmPaymentReceived failed: $e");
    }
  }

  static Future<List<Map<String, String>>> getMessagesForId(String id,
      {required bool isDispute}) async {
    try {
      return isDispute
          ? await getMessagesForDispute(id)
          : await getMessagesForTrade(id);
    } catch (e) {
      print("❌ getMessagesForId failed: $e");
      return [];
    }
  }

  static Future<List<Map<String, String>>> getMessagesForTrade(String tradeId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final reply = await client.tradeService.getChatMessages(
        GetChatMessagesRequest(tradeId: tradeId),
      );
      return reply.messages
          .map((m) => {
                "user": m.isMe ? "You" : "Peer",
                "message": m.message.trim(),
              })
          .toList();
    } catch (e) {
      print("❌ getMessagesForTrade error: $e");
      return [];
    }
  }

  static Future<List<Map<String, String>>> getMessagesForDispute(String disputeId) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final reply = await client.tradeService.getDisputeMessages(
        GetDisputeMessagesRequest(disputeId: disputeId),
      );
      return reply.messages
          .map((m) => {
                "user": m.isMe ? "You" : "Other",
                "message": m.message.trim(),
              })
          .toList();
    } catch (e) {
      print("❌ getMessagesForDispute error: $e");
      return [];
    }
  }

  static Future<List<String>> getRecentChatTradeIds({int limit = 20}) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final reply = await client.tradeService.getTrades(GetTradesRequest());
      final ids = reply.trades
          .where((t) => t.hasMessages)
          .map((t) => t.tradeId)
          .take(limit)
          .toList();
      return ids;
    } catch (e) {
      print("❌ getRecentChatTradeIds error: $e");
      return [];
    }
  }

  static Future<List<String>> getRecentDisputeIds({int limit = 20}) async {
    try {
      final client = HavenoClient(host: _host, port: _port);
      final reply = await client.tradeService.getTrades(GetTradesRequest());
      final ids = reply.trades
          .where((t) => t.disputeState.isNotEmpty)
          .map((t) => t.tradeId)
          .take(limit)
          .toList();
      return ids;
    } catch (e) {
      print("❌ getRecentDisputeIds error: $e");
      return [];
    }
  }
}
