// ============================================
// account_screen.dart (formerly login_screen.dart)
// ============================================
// UI for managing wallet account interactions.
// No logic handled here – delegates to individual wallet function files.
//
// Includes:
// - 16-word mnemonic viewer/editor
// - Displays top 16 currency balances after login
// - Buttons for Login/Restore, Generate New Wallet, and Logout
// - Confirmation dialog before generating a new wallet
// ============================================

import 'package:flutter/material.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';
import 'walletgeneratenew.dart';
import 'walletbalances.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  final List<TextEditingController> _controllers =
      List.generate(16, (_) => TextEditingController());

  bool _isLoggedIn = false;
  List<String> _labels = List.generate(16, (i) => "Word ${i + 1}");

  @override
  void initState() {
    super.initState();
    _loadMnemonic();
  }

  Future<void> _loadMnemonic() async {
    await WalletMnemonic.initialize();
    final words = WalletMnemonic.normalized.split(' ');
    setState(() {
      _isLoggedIn = false;
      for (int i = 0; i < 16; i++) {
        _controllers[i].text = i < words.length ? words[i] : '';
        _labels[i] = "Word ${i + 1}";
      }
    });
  }

  Future<void> _saveMnemonic() async {
    final words = _controllers.map((c) => c.text.trim()).toList();
    if (words.any((w) => w.isEmpty)) {
      _snack("Please fill in all 16 words before saving!");
      return;
    }
    await WalletMnemonic.save(words.join(' '));
    _snack("Mnemonic saved securely!");
  }

  Future<void> _login() async {
    final mnemonic = _controllers.map((c) => c.text.trim()).join(' ');
    if (mnemonic.split(' ').length != 16) {
      _snack("Please fill in all 16 words to login!");
      return;
    }
    await WalletLogin().logout();
    await WalletLogin().loginWithMnemonic(mnemonic);
    await _updateBalances();
  }

  Future<void> _logout() async {
    await WalletLogout().logout();
    _snack("Wallet logged out.");
    await _loadMnemonic();
  }

  Future<void> _updateBalances() async {
    final balances = await WalletBalances().getTopValuedBalances();
    setState(() {
      _isLoggedIn = true;
      for (int i = 0; i < 16; i++) {
        _controllers[i].text = i < balances.length ? balances[i].amount : "";
        _labels[i] = i < balances.length ? balances[i].currency : "";
      }
    });
  }

  Future<void> _confirmGenerateNewWallet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirm New Wallet"),
        content: Text(
          "Are you sure you want to create a new wallet?\n\nYour current wallet will be erased and replaced. Save your mnemonic before proceeding.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Yes")),
        ],
      ),
    );
    if (confirmed == true) await _generateNewWallet();
  }

  Future<void> _generateNewWallet() async {
    await WalletGenerateNew("127.0.0.1", 9999).generateNewWallet();
    _snack("New wallet generated.");
    await _loadMnemonic();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _button(String label, VoidCallback onTap, {Color color = Colors.blueAccent}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(label),
      ),
    );
  }

  Widget _buildField(int i) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_labels[i], style: TextStyle(color: Colors.white54, fontSize: 12)),
        SizedBox(height: 4),
        TextField(
          controller: _controllers[i],
          readOnly: _isLoggedIn,
          enabled: !_isLoggedIn,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wallet / Account Manager")),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16,
              itemBuilder: (_, i) => _buildField(i),
            ),
            SizedBox(height: 24),
            if (!_isLoggedIn) _button("Login / Restore", _login),
            if (!_isLoggedIn) _button("Save Mnemonic", _saveMnemonic, color: Colors.greenAccent),
            if (!_isLoggedIn)
              _button("Generate New Wallet", _confirmGenerateNewWallet, color: Colors.redAccent),
            if (_isLoggedIn) _button("Show Balances", _updateBalances, color: Colors.purple),
            _button("Logout", _logout, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }
}
