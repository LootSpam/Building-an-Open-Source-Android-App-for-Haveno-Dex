// ============================================
// settings_screen.dart
// ============================================
// Minimal app preferences UI.
// Includes Tor toggle, node mode, 2FA toggle, dark mode toggle.
// All logic is local.
// ============================================

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isTorEnabled = false;
  bool isTwoFactorAuthEnabled = false;
  bool isDarkMode = false;
  String connectionStatus = "Not Connected";
  String moneroNode = "auto";

  void toggleTor(bool value) {
    setState(() {
      isTorEnabled = value;
      connectionStatus = isTorEnabled ? "Connecting..." : "Not Connected";
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        connectionStatus = isTorEnabled ? "Connected to Tor" : "Not Connected";
      });
    });
  }

  void toggleDarkMode(bool value) {
    setState(() => isDarkMode = value);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Dark mode is a visual preference only (not persistent yet)."),
    ));
  }

  void toggleTwoFactorAuth(bool value) {
    setState(() => isTwoFactorAuthEnabled = value);
  }

  void checkTorStatus() {
    setState(() => connectionStatus = "Checking...");
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        connectionStatus = isTorEnabled ? "Connected to Tor" : "Not Connected";
      });
    });
  }

  void updateMoneroNode(String node) {
    setState(() => moneroNode = node);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          Text("Privacy & Security",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          SwitchListTile(
            title: Text("Enable Tor", style: TextStyle(color: Colors.white)),
            value: isTorEnabled,
            onChanged: toggleTor,
          ),

          ListTile(
            title: Text("Check Tor Connection", style: TextStyle(color: Colors.white)),
            trailing: ElevatedButton(
              onPressed: checkTorStatus,
              child: Text("Check"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text("Status: $connectionStatus", style: TextStyle(color: Colors.white70)),
          ),

          Divider(color: Colors.white24),

          Text("Monero Node Configuration",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          ListTile(
            title: Text("Node Mode", style: TextStyle(color: Colors.white)),
            trailing: DropdownButton<String>(
              dropdownColor: Colors.black,
              value: moneroNode,
              onChanged: (String? newValue) {
                if (newValue != null) updateMoneroNode(newValue);
              },
              items: ['auto', 'custom'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),

          Divider(color: Colors.white24),

          Text("Wallet Settings",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          SwitchListTile(
            title: Text("Enable 2FA (UI-only)", style: TextStyle(color: Colors.white)),
            value: isTwoFactorAuthEnabled,
            onChanged: toggleTwoFactorAuth,
          ),

          Divider(color: Colors.white24),

          Text("Preferences",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          SwitchListTile(
            title: Text("Enable Dark Mode (Preview)", style: TextStyle(color: Colors.white)),
            value: isDarkMode,
            onChanged: toggleDarkMode,
          ),
        ],
      ),
    );
  }
}
