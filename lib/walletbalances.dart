// ============================================
// walletbalances.dart
// ============================================
// Fetches BTC and XMR balances using Haveno's WalletsService.
// Returns the top 16 balance rows as formatted BalanceItem objects.
// Also includes market price formatter for fiat screen.
// ============================================

import 'package:haveno/haveno.dart';

class BalanceItem {
  final String currency;
  final String amount;

  BalanceItem({required this.currency, required this.amount});
}

class WalletBalances {
  final String host;
  final int port;

  late final HavenoClient _client;
  late final WalletsService _walletService;

  WalletBalances({this.host = '127.0.0.1', this.port = 9999}) {
    _client = HavenoClient(host: host, port: port);
    _walletService = WalletsService(_client);
  }

  /// Fetches and formats the top 16 wallet balances from Haveno.
  Future<List<BalanceItem>> getTopBalances() async {
    try {
      final balances = await _walletService.getBalances();
      if (balances == null) {
        print("❌ No balance info returned by Haveno.");
        return [];
      }

      List<BalanceItem> result = [];

      if (balances.hasXmr()) {
        final xmr = balances.xmr;
        result.addAll([
          BalanceItem(currency: 'XMR - Total', amount: _format(xmr.balance)),
          BalanceItem(currency: 'XMR - Available', amount: _format(xmr.availableBalance)),
          BalanceItem(currency: 'XMR - Pending', amount: _format(xmr.pendingBalance)),
          BalanceItem(currency: 'XMR - Reserved (Offer)', amount: _format(xmr.reservedOfferBalance)),
          BalanceItem(currency: 'XMR - Reserved (Trade)', amount: _format(xmr.reservedTradeBalance)),
        ]);
      }

      if (balances.hasBtc()) {
        final btc = balances.btc;
        result.addAll([
          BalanceItem(currency: 'BTC - Available', amount: _format(btc.availableBalance)),
          BalanceItem(currency: 'BTC - Reserved', amount: _format(btc.reservedBalance)),
          BalanceItem(currency: 'BTC - Locked', amount: _format(btc.lockedBalance)),
          BalanceItem(currency: 'BTC - Total Available', amount: _format(btc.totalAvailableBalance)),
        ]);
      }

      return result.take(16).toList();
    } catch (e) {
      print("❌ Error during balance fetch: $e");
      return [];
    }
  }

  /// Fetches balances and sorts them by estimated value using market prices.
  Future<List<BalanceItem>> getTopValuedBalances() async {
    final balances = await getTopBalances();
    final prices = await WalletBalances.getPriceMap();

    balances.sort((a, b) {
      final aCoin = a.currency.split(' ').first;
      final bCoin = b.currency.split(' ').first;

      final aValue = (double.tryParse(a.amount) ?? 0) * (prices[aCoin] ?? 0);
      final bValue = (double.tryParse(b.amount) ?? 0) * (prices[bCoin] ?? 0);

      return bValue.compareTo(aValue); // highest first
    });

    return balances.take(16).toList();
  }

  /// Returns map like { "XMR": 1.0, "BTC": 214.53, "USD": 114.22 }
  static Future<Map<String, double>> getPriceMap() async {
    final Map<String, double> priceMap = { "XMR": 1.0 };

    try {
      final client = HavenoClient(host: '127.0.0.1', port: 9999);
      final priceService = PriceService(client);
      final reply = await priceService.getMarketPrices(MarketPricesRequest());

      for (final p in reply.prices) {
        if (p.baseCurrency == "XMR") {
          final quote = p.quoteCurrency.trim();
          final parsed = double.tryParse(p.price);
          if (quote.isNotEmpty && parsed != null) {
            priceMap[quote] = parsed;
          }
        }
      }
    } catch (e) {
      print("❌ Failed to fetch price map: $e");
    }

    return priceMap;
  }

  /// Formats XMR market prices into user-readable string
  static Future<String> getFormattedPrices() async {
    final prices = await getPriceMap();
    if (prices.length <= 1) return "⚠️ Price data unavailable";

    final buffer = StringBuffer("1 XMR ≈\n");
    prices.forEach((symbol, value) {
      if (symbol != "XMR") buffer.writeln("• $symbol: $value");
    });

    return buffer.toString().trim();
  }

  String _format(dynamic raw) {
    try {
      return raw?.toString() ?? "0";
    } catch (_) {
      return "0";
    }
  }
}
