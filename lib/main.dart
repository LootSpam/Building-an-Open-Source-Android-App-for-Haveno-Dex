import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dependenciesdownloader.dart';
import 'account_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOpenCrypto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          color: Colors.black,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const DependenciesDownloader(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget buildButton(BuildContext context, String title, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: SizedBox.expand(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, color: Colors.white),
            label: Text(title, textAlign: TextAlign.center),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              side: const BorderSide(color: Colors.white, width: 1),
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
      appBar: AppBar(title: const Text('HOpenCrypto'), centerTitle: true),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildButton(
            context,
            "ACCOUNT / WALLET / LOGIN",
            Icons.account_circle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          buildButton(context, "CHAT/DISPUTES", Icons.chat_bubble_outline),
          buildButton(context, "TRADE CURRENCY PAIR", Icons.swap_horiz),
          buildButton(context, "TRANSFER / RECEIVE", Icons.send),
          buildButton(context, "BUY / SELL TO FIAT", Icons.attach_money),
          buildButton(context, "HISTORY", Icons.history),
          buildButton(context, "SETTINGS", Icons.settings),
          const QuitButton(),
        ],
      ),
    );
  }
}

class QuitButton extends StatefulWidget {
  const QuitButton({super.key});
  @override
  _QuitButtonState createState() => _QuitButtonState();
}

class _QuitButtonState extends State<QuitButton> {
  bool waitingForSecondTap = false;

  void attemptQuit() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // ✅ Desktop: exit the Flutter app only
      debugPrint("🚪 Exiting Flutter desktop app via exit(0)");
      exit(0);
    } else {
      // ✅ Android/iOS: require double-tap
      if (waitingForSecondTap) {
        debugPrint("🚪 Quitting on second tap (mobile)");
        SystemNavigator.pop(); // Best effort on Android
      } else {
        setState(() => waitingForSecondTap = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => waitingForSecondTap = false);
        });
      }
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
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        side: const BorderSide(color: Colors.white, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}
