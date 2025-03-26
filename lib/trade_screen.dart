// ============================================
// trade_screen.dart
// ============================================
// Unified screen for posting offers and managing trades.
// Includes: offer creation, trade listing, confirmations,
// disputes, withdrawals, and full contract display.
// ============================================

import 'package:flutter/material.dart';
import 'package:haveno/haveno.dart';
import 'wallettrademessages.dart';
import 'walletoffers.dart';
import 'chat_screen.dart';

class TradeScreen extends StatefulWidget {
  @override
  _TradeScreenState createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  final _amountCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _selectedAsset = "BTC";
  String _direction = "BUY";
  bool _submitting = false;
  bool _loadingTrades = true;

  final _withdrawControllers = <String, TextEditingController>{};
  List<TradeInfo> _trades = [];

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    final list = await WalletOffers.loadTrades();
    setState(() {
      _trades = list;
      _loadingTrades = false;
    });
  }

  Future<void> _postOffer() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final price = _priceCtrl.text.trim();
    if (amount == null || price.isEmpty) return;

    setState(() => _submitting = true);
    final success = await WalletOffers.postOffer(
      direction: _direction,
      asset: _selectedAsset,
      amount: amount,
      price: price,
    );
    if (success) {
      _amountCtrl.clear();
      _priceCtrl.clear();
      _loadTrades();
    }
    setState(() => _submitting = false);
  }

  Widget _input(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _withdrawField(String tradeId) {
    _withdrawControllers.putIfAbsent(tradeId, () => TextEditingController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _input("Withdraw Address", _withdrawControllers[tradeId]!),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final address = _withdrawControllers[tradeId]!.text.trim();
            if (address.isEmpty) return;
            await WalletOffers.withdrawFunds(tradeId, address);
            _withdrawControllers[tradeId]!.clear();
            _loadTrades();
          },
          child: Text("Withdraw Funds"),
        ),
      ],
    );
  }

  Widget _contractDisplay(TradeInfo t) {
    return t.hasContractAsJson()
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.white24),
              Text("Contract JSON", style: TextStyle(color: Colors.white70)),
              SizedBox(height: 6),
              SelectableText(t.contractAsJson,
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          )
        : SizedBox.shrink();
  }

  Widget _tradeCard(TradeInfo t) {
    final tradeId = t.tradeId;
    return Card(
      color: Colors.grey[900],
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trade ID: $tradeId", style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text("Asset: ${t.offer.asset}", style: TextStyle(color: Colors.white)),
            Text("Price: ${t.price}", style: TextStyle(color: Colors.white70)),
            Text("Role: ${t.role}", style: TextStyle(color: Colors.white38)),
            Text("Completed: ${t.isCompleted ? "Yes" : "No"}",
                style: TextStyle(color: Colors.white38)),
            Text("Payment Sent: ${t.isPaymentSent ? "Yes" : "No"}",
                style: TextStyle(color: Colors.white38)),
            Text("Payment Received: ${t.isPaymentReceived ? "Yes" : "No"}",
                style: TextStyle(color: Colors.white38)),
            if (t.disputeState.isNotEmpty)
              Text("Dispute State: ${t.disputeState}", style: TextStyle(color: Colors.redAccent)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ElevatedButton(
                  onPressed: () => WalletTradeMessages.confirmPaymentSent(tradeId),
                  child: Text("Confirm Sent"),
                ),
                ElevatedButton(
                  onPressed: () => WalletTradeMessages.confirmPaymentReceived(tradeId),
                  child: Text("Confirm Received"),
                ),
                ElevatedButton(
                  onPressed: () => WalletOffers.openDispute(tradeId),
                  child: Text("Dispute"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(initialTradeId: tradeId),
                    ));
                  },
                  child: Text("Chat"),
                ),
              ],
            ),
            SizedBox(height: 12),
            _withdrawField(tradeId),
            _contractDisplay(t),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text("Trade"), backgroundColor: Colors.black),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Post Offer", style: TextStyle(color: Colors.white70)),
            ToggleButtons(
              isSelected: [_direction == "BUY", _direction == "SELL"],
              onPressed: (i) => setState(() => _direction = i == 0 ? "BUY" : "SELL"),
              children: [Text("Buy XMR"), Text("Sell XMR")],
              color: Colors.white54,
              selectedColor: Colors.white,
              fillColor: Colors.blueAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            SizedBox(height: 12),
            _input("Amount of XMR", _amountCtrl),
            SizedBox(height: 10),
            _input("Price per XMR in $_selectedAsset", _priceCtrl),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedAsset,
              dropdownColor: Colors.black,
              style: TextStyle(color: Colors.white),
              isExpanded: true,
              items: ["BTC", "USD", "EUR"].map((a) =>
                DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) => setState(() => _selectedAsset = v ?? "BTC"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitting ? null : _postOffer,
              child: Text(_submitting ? "Posting..." : "Post Offer"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            Divider(height: 30, color: Colors.white24),
            Text("Live Trades", style: TextStyle(color: Colors.white70)),
            if (_loadingTrades)
              Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_trades.isEmpty)
              Padding(padding: EdgeInsets.all(16), child: Text("No active trades.", style: TextStyle(color: Colors.white38)))
            else
              ..._trades.map(_tradeCard),
          ],
        ),
      ),
    );
  }
}
