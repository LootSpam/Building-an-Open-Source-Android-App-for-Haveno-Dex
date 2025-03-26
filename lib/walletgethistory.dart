// ============================================
// walletgethistory.dart
// ============================================
// Handles only executed history retrieval for:
// - Finalized trades (TradeInfo)
// - Confirmed Monero wallet transactions (XmrTx)
// - Aggregate trade statistics (TradeStatistics)
// ============================================

import 'package:haveno/haveno.dart';

class WalletGetHistory {
  final HavenoClient _client;
  final TradeService _tradeService;
  final WalletsService _walletService;

  WalletGetHistory(String host, int port)
      : _client = HavenoClient(host: host, port: port),
        _tradeService = TradeService(HavenoClient(host: host, port: port)),
        _walletService = WalletsService(HavenoClient(host: host, port: port));

  /// Fetches all trades (unfiltered)
  /// Use client-side filtering to display completed only
  Future<List<TradeInfo>> getAllTrades() async {
    try {
      final reply = await _tradeService.getTrades(GetTradesRequest());
      return reply.trades;
    } catch (e) {
      print("❌ Error in getAllTrades: $e");
      return [];
    }
  }

  /// Fetches a specific trade by ID
  Future<TradeInfo?> getTradeById(String tradeId) async {
    try {
      final reply = await _tradeService.getTrade(GetTradeRequest(tradeId: tradeId));
      return reply.trade;
    } catch (e) {
      print("❌ Error in getTradeById: $e");
      return null;
    }
  }

  /// Returns aggregated trade statistics (volume, counts, etc)
  Future<GetTradeStatisticsReply?> getTradeStats() async {
    try {
      return await _tradeService.getTradeStatistics(GetTradeStatisticsRequest());
    } catch (e) {
      print("❌ Error in getTradeStats: $e");
      return null;
    }
  }

  /// Fetches wallet transfer history (XMR only)
  Future<List<XmrTx>> getXmrTransactions() async {
    try {
      final reply = await _walletService.getXmrTxs(GetXmrTxsRequest());
      return reply.txs;
    } catch (e) {
      print("❌ Error in getXmrTransactions: $e");
      return [];
    }
  }
}
