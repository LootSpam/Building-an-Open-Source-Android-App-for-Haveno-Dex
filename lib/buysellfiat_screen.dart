// ============================================
// buysellfiat_screen.dart
// ============================================
// UI for viewing exchange rates and fiat order book.
// Hooks into Haveno PriceService for live market prices.
// TODO: Add order book + fiat offer support
// ============================================

import 'package:flutter/material.dart';
import 'walletbalances.dart'; // 🔄 Updated import

class BuySellFiatScreen extends StatefulWidget {
  @override
  _BuySellFiatScreenState createState() => _BuySellFiatScreenState();
}

class _BuySellFiatScreenState extends State<BuySellFiatScreen> {
  String exchangeRates = "Loading...";
  String orderBook = "Coming soon...";

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final data = await WalletBalances.getFormattedPrices(); // 🔄 Updated call
    setState(() => exchangeRates = data);
  }

  Widget buildSectionHeader(String title, {IconData icon = Icons.info}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(String content) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.0),
        child: Text(
          content,
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget buildButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 16),
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Buy / Sell to Fiat'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildSectionHeader("Live Exchange Rates", icon: Icons.currency_exchange),
            buildCard(exchangeRates),
            SizedBox(height: 20),
            buildSectionHeader("Order Book", icon: Icons.list_alt),
            buildCard(orderBook),
            SizedBox(height: 20),
            buildButton("Buy Crypto with Fiat", Icons.shopping_cart, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("💸 Fiat Buy — Coming soon")),
              );
            }, Colors.green),
            SizedBox(height: 10),
            buildButton("Sell Crypto for Fiat", Icons.swap_horiz, () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("💰 Fiat Sell — Coming soon")),
              );
            }, Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
