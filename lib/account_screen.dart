import 'package:flutter/material.dart';
import 'walletlogin.dart';
import 'walletlogout.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _controllers = List.generate(26, (_) => TextEditingController());
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    final words = [
      'nanny','civilian','ambush','business','never','hesitate','cousin','gossip','saved','cuisine','software','match','tidy',
      'agenda','toffee','germs','eden','niche','argue','gang','vulture','duties','toolbox','urgent','saved','_____'
    ];
    for (int i = 0; i < 26; i++) _controllers[i].text = words[i];
  }

  Future<void> _login() async {
    final m = _controllers.take(25).map((c) => c.text.trim()).join(' ');
    if (m.split(' ').length != 25) return _snack("Enter all 25 words.");
    try {
      await WalletLogin.logout();
      await WalletLogin.loginWithMnemonic(m);
    } catch (e) {
      return _snack("Login failed: $e");
    }
    setState(() {
      _isLoggedIn = true;
      for (int i = 0; i < 25; i++) {
        _controllers[i].text = '${(1000000 / (i + 1)).toStringAsFixed(1)} XMR';
      }
    });
  }

  Future<void> _logout() async {
    await WalletLogout().logout();
    setState(() {
      _isLoggedIn = false;
      for (int i = 0; i < 25; i++) {
        _controllers[i].clear();
      }
    });
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _labelCell(int i, {bool dimmed = false}) => Expanded(
    flex: 199, // Shrunk from 200
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _isLoggedIn ? 'Token ${i + 1}' : 'Word ${i + 1}',
        style: TextStyle(color: dimmed ? Colors.grey : Colors.white70, fontSize: 16),
      ),
    ),
  );

  Widget _inputCell(int i, {bool dimmed = false}) => Expanded(
    flex: 300,
    child: TextField(
      controller: _controllers[i],
      enabled: !_isLoggedIn && !dimmed,
      readOnly: _isLoggedIn || dimmed,
      style: TextStyle(color: dimmed ? Colors.grey[700] : Colors.white, fontSize: 16),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[850],
        border: const OutlineInputBorder(borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    ),
  );

  Widget _row(int i, double h) => SizedBox(
    height: h * 0.07,
    child: Row(
      children: [
        _labelCell(i),
        _inputCell(i),
        if (i + 1 < 26) _labelCell(i + 1),
        if (i + 1 < 26) _inputCell(i + 1),
      ],
    ),
  );

  Widget _buttonOverlay(double h) => Positioned(
    bottom: 0,
    right: 0,
    left: 0,
    height: h * 0.07,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Spacer(flex: 5),
          Expanded(flex: 5, child: _buttonCell()),
        ],
      ),
    ),
  );

  Widget _buttonCell() => ElevatedButton(
    onPressed: _isLoggedIn ? _logout : _login,
    style: ElevatedButton.styleFrom(
      backgroundColor: _isLoggedIn ? Colors.orange : Colors.blueAccent,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    child: Text(_isLoggedIn ? "Logout" : "Login"),
  );

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final h = MediaQuery.of(ctx).size.height;
    final appBarHeight = kToolbarHeight * 0.999; // Shrink height by 0.1%
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(title: const Text("Account"), centerTitle: true),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: h,
            child: Column(
              children: [
                for (int i = 0; i < 24; i += 2) _row(i, h),
                SizedBox(
                  height: h * 0.07,
                  child: Row(
                    children: [
                      _labelCell(24, dimmed: true),
                      _inputCell(24, dimmed: true),
                      _labelCell(25, dimmed: true),
                      _inputCell(25, dimmed: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buttonOverlay(h),
        ],
      ),
    );
  }
}
