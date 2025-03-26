// ============================================
// chat_screen.dart
// ============================================
// UI for live trade/dispute chat
// Powered by wallettrademessages.dart
// ============================================

import 'package:flutter/material.dart';
import 'wallettrademessages.dart';
import 'walletlogin.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedTradeId;
  String? _selectedDisputeId;

  List<String> _recentTrades = [];
  List<String> _recentDisputes = [];
  List<Map<String, String>> _messages = [];

  bool _loading = true;
  bool _isDispute = false;

  final _host = '127.0.0.1';
  final _port = 9999;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    _recentTrades = await WalletTradeMessages.getRecentChatTradeIds(limit: 20);
    _recentDisputes = await WalletTradeMessages.getRecentDisputeIds(limit: 20);
    setState(() => _loading = false);
  }

  Future<void> _loadMessages(String id, bool isDispute) async {
    setState(() {
      _loading = true;
      _isDispute = isDispute;
      _selectedTradeId = isDispute ? null : id;
      _selectedDisputeId = isDispute ? id : null;
    });

    final msgs = await WalletTradeMessages.getMessagesForId(id, isDispute: isDispute);
    setState(() {
      _messages = msgs;
      _loading = false;
    });

    Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) return;
    if (_isDispute && _selectedDisputeId == null) return;
    if (!_isDispute && _selectedTradeId == null) return;

    bool success = false;

    try {
      success = _isDispute
          ? await WalletTradeMessages.sendDisputeMessage(_selectedDisputeId!, msg)
          : await WalletTradeMessages.sendTradeMessage(_selectedTradeId!, msg);
    } catch (_) {
      await WalletLogin(host: _host, port: _port).logout();
      await WalletLogin(host: _host, port: _port).loginWithMnemonic(WalletMnemonic.normalized);
      success = _isDispute
          ? await WalletTradeMessages.sendDisputeMessage(_selectedDisputeId!, msg)
          : await WalletTradeMessages.sendTradeMessage(_selectedTradeId!, msg);
    }

    if (success) {
      _messageController.clear();
      await _loadMessages(_isDispute ? _selectedDisputeId! : _selectedTradeId!, _isDispute);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['user'] == "You";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message['user']!, style: TextStyle(fontSize: 12, color: Colors.white)),
            SizedBox(height: 4),
            Text(message['message']!, style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> ids, bool isDisputeList) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        DropdownButton<String>(
          value: isDisputeList ? _selectedDisputeId : _selectedTradeId,
          dropdownColor: Colors.black87,
          isExpanded: true,
          hint: Text("Select ID", style: TextStyle(color: Colors.white38)),
          style: TextStyle(color: Colors.white),
          items: ids.map((id) {
            return DropdownMenuItem(
              value: id,
              child: Text("${isDisputeList ? 'Dispute' : 'Trade'} #$id"),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) _loadMessages(val, isDisputeList);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Center'),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildDropdown("Recent Trades", _recentTrades, false),
                      SizedBox(height: 12),
                      _buildDropdown("Recent Disputes", _recentDisputes, true),
                    ],
                  ),
                ),
                Divider(color: Colors.white12),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(child: Text("No messages.", style: TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                        ),
                ),
                Divider(height: 1, color: Colors.white12),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle: TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[850],
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        child: Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
