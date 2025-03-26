// ============================================
// transfer_screen.dart
// ============================================
// Allows users to send XMR to a recipient address.
// Uses walletsendfunds.dart for sending.
// Shows live balances via walletbalances.dart.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'walletsendfunds.dart';
import 'walletbalances.dart';

class TransferScreen extends StatefulWidget {
  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  List<BalanceItem> _balances = [];

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    final b = await WalletBalances().getTopBalances();
    setState(() => _balances = b.where((b) => b.currency.startsWith("XMR")).toList());
  }

  Future<void> _sendTransaction() async {
    final address = _addressCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final amount = double.tryParse(amountText);

    if (address.isEmpty || amount == null || amount <= 0) {
      _alert("Enter valid address and amount.");
      return;
    }

    final success = await WalletSendFunds.send(address, amount);
    if (success) {
      _alert("Transaction sent!");
      _addressCtrl.clear();
      _amountCtrl.clear();
      _loadBalances();
    } else {
      _alert("Transaction failed.");
    }
  }

  void _alert(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Transfer'), backgroundColor: Colors.black, centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Your XMR Balance",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          if (_balances.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(8),
                children: _balances.map((b) => ListTile(
                  title: Text(b.currency, style: TextStyle(color: Colors.white)),
                  trailing: Text(b.amount, style: TextStyle(color: Colors.white70)),
                )).toList(),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _addressCtrl,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter recipient XMR address",
                    hintStyle: TextStyle(color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.paste, color: Colors.white38),
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data != null) _addressCtrl.text = data.text ?? '';
                      },
                    ),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Amount in XMR",
                    hintStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.grey[850],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _sendTransaction,
                  child: Text("Send"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
