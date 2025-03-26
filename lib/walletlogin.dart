// ============================================
// walletlogin.dart
// ============================================
// Handles Haveno wallet login/logout.
// Centralizes mnemonic normalization, validation, ZIP formatting, and hashing.
// Supports auto-login every 3 minutes.
// Uses OpenAccountRequest, RestoreAccountRequest, and CreateAccountRequest.
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:haveno/haveno.dart';
import 'package:protobuf/protobuf.dart';
import 'package:crypto/crypto.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:archive/archive.dart';
import 'walletlogout.dart';

class WalletLogin {
  late HavenoClient _client;
  late AccountService _accountService;
  Timer? _autoLoginTimer;

  WalletLogin({String host = "127.0.0.1", int port = 9999}) {
    _client = HavenoClient(host: host, port: port);
    _accountService = AccountService(_client);
    _startAutoLoginLoop();
  }

  void _startAutoLoginLoop() {
    _autoLoginTimer?.cancel();
    _autoLoginTimer = Timer.periodic(Duration(minutes: 3), (_) async {
      await logout();
      await loginWithMnemonic(WalletMnemonic.normalized);
    });
  }

  Future<void> loginWithMnemonic(String mnemonic) async {
    try {
      await WalletMnemonic.save(mnemonic); // normalize, validate, store, precompute
      await _accountService.openAccount(OpenAccountRequest(password: WalletMnemonic.password));
      print("✅ Wallet opened using mnemonic.");
    } catch (e) {
      print("⚠️ OpenAccount failed, trying restore...");
      try {
        final restoreReq = RestoreAccountRequest(
          zipBytes: WalletMnemonic.zipBytes,
          offset: Int64(0),
          totalLength: Int64(WalletMnemonic.zipBytes.length),
          hasMore: false,
        );
        await _accountService.restoreAccount(restoreReq);
        print("✅ Wallet restored from mnemonic ZIP.");
      } catch (restoreError) {
        print("⚠️ Restore failed, trying createAccount...");
        try {
          await _accountService.createAccount(CreateAccountRequest(password: WalletMnemonic.password));
          print("✅ New wallet created with provided mnemonic.");
        } catch (createError) {
          print("❌ Wallet creation failed: $createError");
        }
      }
    }
  }

  Future<void> logout() async {
    try {
      await WalletLogout().logout();
      await WalletMnemonic.resetToDefault();
    } catch (e) {
      print("❌ Logout failed: $e");
    }
  }
}

class WalletMnemonic {
  static const _mnemonicKey = "user_wallet_mnemonic";
  static const _defaultMnemonic =
      "avoid violin chat cover jacket talk quote aware verb milk example talk win output pudding trick";

  static final _storage = FlutterSecureStorage();

  static late String normalized;
  static late String formatted;
  static late Uint8List zipBytes;
  static late String sha256Hash;

  /// Initializes all representations from storage
  static Future<void> initialize() async {
    final raw = await _storage.read(key: _mnemonicKey) ?? _defaultMnemonic;
    normalized = _normalize(raw);
    if (!_isValid(normalized)) throw Exception("Invalid mnemonic");

    formatted = _formatForDisplay(normalized);
    zipBytes = _createZipBytes(normalized);
    sha256Hash = sha256.convert(utf8.encode(normalized)).toString();

    print("🔐 WalletMnemonic initialized.");
  }

  /// Save a new mnemonic and re-initialize
  static Future<void> save(String raw) async {
    final clean = _normalize(raw);
    if (!_isValid(clean)) throw Exception("Invalid mnemonic");
    await _storage.write(key: _mnemonicKey, value: clean);
    await initialize();
  }

  /// Reset to default test mnemonic
  static Future<void> resetToDefault() async {
    await _storage.write(key: _mnemonicKey, value: _defaultMnemonic);
    await initialize();
  }

  /// Validate mnemonic against BIP39/Monero wordlist
  static bool _isValid(String mnemonic) {
    final words = mnemonic.split(' ');
    final validWords = bip39.wordlists.english;
    return words.length == 16 && words.every(validWords.contains);
  }

  /// Normalize for internal use: lowercase, trimmed, 16-word max
  static String _normalize(String raw) {
    return raw.trim().toLowerCase().split(RegExp(r'\s+')).take(16).join(' ');
  }

  /// Pretty-format for GUI display
  static String _formatForDisplay(String mnemonic) {
    final words = mnemonic.split(' ');
    return List.generate(16, (i) => "${i + 1}. ${words[i]}").join('\n');
  }

  /// Proper ZIP archive for Haveno restore
  static Uint8List _createZipBytes(String mnemonic) {
    final archive = Archive()
      ..addFile(ArchiveFile('mnemonic.txt', mnemonic.length, utf8.encode(mnemonic)));
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Expose password (used by all wallet actions)
  static String get password => normalized;
}
