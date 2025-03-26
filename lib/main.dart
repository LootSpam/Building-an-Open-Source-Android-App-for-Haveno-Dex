import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

// Core Screens
import 'buysellfiat_screen.dart';
import 'transfer_screen.dart';
import 'chat_screen.dart';
import 'account_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'trade_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = FlutterSecureStorage();
  final defaultMnemonic = 'avoid violin chat cover jacket talk quote aware verb milk example talk win output pudding trick';

  String? mnemonic = await storage.read(key: "user_wallet_mnemonic");
  if (mnemonic == null) {
    mnemonic = defaultMnemonic;
    await storage.write(key: "user_wallet_mnemonic", value: mnemonic);
    print("🔑 Default mnemonic initialized.");
  }

  print("🚀 App Starting...");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOpenCrypto',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          color: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  Widget buildButton(BuildContext context, String title, IconData icon, Widget destination) {
    return Expanded(
      child: SizedBox.expand(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
            },
            icon: Icon(icon, color: Colors.white),
            label: Text(title, textAlign: TextAlign.center),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              side: BorderSide(color: Colors.white, width: 1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HOpenCrypto'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildButton(context, "ACCOUNT / WALLET / LOGIN", Icons.account_circle, AccountScreen()),
          buildButton(context, "CHAT/DISPUTES", Icons.chat_bubble_outline, ChatScreen()),
          buildButton(context, "TRADE CURRENCY PAIR", Icons.swap_horiz, TradeScreen()),
          buildButton(context, "TRANSFER / RECEIVE", Icons.send, TransferScreen()),
          buildButton(context, "BUY / SELL TO FIAT", Icons.attach_money, BuySellFiatScreen()),
          buildButton(context, "HISTORY", Icons.history, HistoryScreen()),
          buildButton(context, "SETTINGS", Icons.settings, SettingsScreen()),
          QuitButton(),
        ],
      ),
    );
  }
}

class QuitButton extends StatefulWidget {
  @override
  _QuitButtonState createState() => _QuitButtonState();
}

class _QuitButtonState extends State<QuitButton> {
  bool waitingForSecondTap = false;

  void attemptQuit() {
    if (waitingForSecondTap) {
      SystemNavigator.pop();
    } else {
      setState(() {
        waitingForSecondTap = true;
      });
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          waitingForSecondTap = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: attemptQuit,
      child: Text(waitingForSecondTap ? "Tap again to quit" : "QUIT"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        side: BorderSide(color: Colors.white, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
