import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:bip39/bip39.dart' as bip39;

/// WalletLogin manages 16-word bip39 mnemonics for login/logout flows.
/// It handles normalization, validation, reading, and overwriting on disk.
/// This is a minimal Haveno-compliant implementation designed for headless use.
class WalletLogin {
  static const _defaultMnemonic =
      'avoid violin chat cover jacket talk quote aware verb milk example talk win output pudding trick';

  /// Writes a valid mnemonic to persistent storage.
  /// Throws [Exception] if the mnemonic is invalid.
  static Future<void> loginWithMnemonic(String mnemonic) async {
    final clean = _normalize(mnemonic);
    if (!isValid(clean)) throw Exception('Invalid mnemonic');
    await (await _file()).writeAsString(clean, flush: true);
  }

  /// Clears current mnemonic and restores default.
  static Future<void> logout() async => resetMnemonicToDefault();

  /// Resets saved mnemonic to the built-in default string.
  static Future<void> resetMnemonicToDefault() async =>
      (await _file()).writeAsString(_defaultMnemonic, flush: true);

  /// Reads the mnemonic directly from storage.
  static Future<String> readMnemonic() async => (await _file()).readAsString();

  /// Checks if a mnemonic is valid (with normalization).
  static bool isValid(String raw) {
    final normalized = _normalize(raw);
    return bip39.validateMnemonic(normalized);
  }

  /// Applies trimming, lowercasing, and takes only the first 16 words.
  static String _normalize(String raw) =>
      raw.toLowerCase().trim().split(RegExp(r'\s+')).take(16).join(' ');

  /// Points to the local mnemonic file.
  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/mnemonic.txt');
  }

  /// Public getter for the hardcoded fallback mnemonic.
  static String get defaultMnemonic => _defaultMnemonic;
} 
