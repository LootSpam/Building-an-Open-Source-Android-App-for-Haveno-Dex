import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:haveno/haveno.dart';
import 'walletgethistory.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final WalletGetHistory _walletHistory = WalletGetHistory("127.0.0.1", 9999);
  List<TradeInfo> _trades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final rawTrades = await _walletHistory.getAllTrades();
      rawTrades.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _trades = rawTrades;
        _loading = false;
      });
    } catch (e) {
      print("❌ Failed to load trade history, retrying after login...");
      await WalletLogout().logout();
      await WalletLogin().loginWithMnemonic(WalletMnemonic.normalized);
      try {
        final retried = await _walletHistory.getAllTrades();
        retried.sort((a, b) => b.date.compareTo(a.date));
        setState(() {
          _trades = retried;
          _loading = false;
        });
      } catch (finalErr) {
        print("❌ Final trade history fetch failed: $finalErr");
        setState(() => _loading = false);
      }
    }
  }

  double _toXmrAmount(BigInt atomic) => atomic.toDouble() / 1e12;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Trade History'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _trades.isEmpty
              ? Center(
                  child: Text(
                    "No trades found.",
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: _trades.length,
                  padding: EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final trade = _trades[index];
                    return _buildTradeCard(index + 1, trade);
                  },
                ),
    );
  }

  Widget _buildTradeCard(int index, TradeInfo trade) {
    final isBuyer = trade.role.toLowerCase() == "buyer";
    final date = DateTime.fromMillisecondsSinceEpoch(trade.date.toInt());
    final formattedDate = DateFormat('MMM d, yyyy').format(date);
    final status = trade.isCompleted ? "Completed" : "Pending";
    final statusColor = trade.isCompleted ? Colors.green : Colors.yellow;
    final tradeId = trade.shortId.isNotEmpty ? trade.shortId : trade.tradeId;
    final peer = (trade.tradePeerNodeAddress ?? "").isNotEmpty
        ? trade.tradePeerNodeAddress
        : "Unknown";

    final receivedAsset = trade.offer.asset;
    final receivedAmount = isBuyer
        ? _toXmrAmount(trade.amount)
        : (double.tryParse(trade.price) ?? 0) * _toXmrAmount(trade.amount);

    final sentAsset = isBuyer ? "XMR" : trade.offer.asset;
    final sentAmount = isBuyer
        ? (double.tryParse(trade.price) ?? 0) * _toXmrAmount(trade.amount)
        : _toXmrAmount(trade.amount);

    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trade #$index — $formattedDate — $status",
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildHistoryRow("You Sent", sentAmount, sentAsset, peer, isSent: true),
            SizedBox(height: 6),
            _buildHistoryRow("You Received", receivedAmount, receivedAsset, peer, isSent: false),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryRow(String label, double amount, String asset, String peer,
      {required bool isSent}) {
    final icon = isSent ? Icons.arrow_upward : Icons.arrow_downward;
    final color = isSent ? Colors.redAccent : Colors.greenAccent;
    final direction = isSent ? "to" : "from";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            SizedBox(width: 8),
            Text("$label: ", style: TextStyle(color: Colors.white70)),
            Text("${amount.toStringAsFixed(4)} $asset",
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: peer));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Copied wallet ID")),
            );
          },
          child: Row(
            children: [
              Icon(Icons.copy, size: 16, color: Colors.white30),
              SizedBox(width: 4),
              Text("$direction wallet",
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
