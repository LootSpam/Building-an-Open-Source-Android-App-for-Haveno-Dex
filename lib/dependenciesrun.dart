// ─────────────────────────────────────────────────────────────
// 🏗️ Imports and Main Entry
// ─────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';
import 'dependencieswatchdog.dart';

// ─────────────────────────────────────────────────────────────
// 🚀 Stateful Widget Entry
// ─────────────────────────────────────────────────────────────
class DependenciesRun extends StatefulWidget {
  const DependenciesRun({super.key});
  @override
  State<DependenciesRun> createState() => _DependenciesRunState();
}

// ─────────────────────────────────────────────────────────────
// 🔧 State and Boot Control
// ─────────────────────────────────────────────────────────────
class _DependenciesRunState extends State<DependenciesRun> {
  final _components = ["Proot", "Linux Sandbox", "Java", "Haveno Daemon"];
  final Map<String, bool> _status = {
    for (var c in ["Proot", "Linux Sandbox", "Java", "Haveno Daemon"]) c: false
  };
  int _countdown = 3;
  bool _bootFailed = false;

  @override
  void initState() {
    debugPrint("*****Start of: dependenciesrun.dart*****");
    super.initState();
    Platform.isWindows ? _startBootWindows() : _startBootAndroid();
  }

  Future<void> _ensureUnameBinary() async {
    final bin = await getApplicationSupportDirectory();
    final binPath = "${bin.path}/proot_bin";
    final uname = File("$binPath/uname");
    final busybox = File("$binPath/busybox");

    if (await uname.exists()) await uname.delete();
    await busybox.copy(uname.path);
    await Process.run("chmod", ["+x", uname.path]);
    debugPrint("🔧 Copied busybox → uname binary and set executable");

    final fakeUname = File("$binPath/rootfs/usr/bin/uname");
    await fakeUname.create(recursive: true);
    await fakeUname.writeAsString("#!/bin/sh\necho 'Linux'\n");
    await Process.run("chmod", ["+x", fakeUname.path]);
    debugPrint("🔧 Injected fake uname script inside rootfs to bypass Tor detection");
  }

  Future<void> _step(String name, Future<void> Function() action) async {
    debugPrint("⏳ Starting $name...");
    await action();
    debugPrint("✅ $name step completed.");
    setState(() => _status[name] = true);
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _startBootAndroid() async {
    final bin = await getApplicationSupportDirectory();
    final binPath = "${bin.path}/proot_bin";
    debugPrint("🧪 Pre-launch: Starting Haveno Daemon early for ping check...");
    await _ensureUnameBinary();

    try {
      final test = await Process.run("$binPath/uname", []);
      debugPrint("🧪 uname test stdout: \${test.stdout}");
      debugPrint("⚠️ uname test stderr: \${test.stderr}");
    } catch (e) {
      debugPrint("❌ uname test failed: $e");
    }

    DependenciesWatchdog.start(binPath);

    try {
      await _step("Proot", () async {
        final proot = File("$binPath/proot");
        final exists = await proot.exists();
        final size = exists ? await proot.length() : 0;
        debugPrint("📦 proot → exists=$exists, size=$size bytes, path=\${proot.path}");
        if (!exists || size == 0) throw Exception("❌ Proot binary missing or empty");
      });

      await _step("Linux Sandbox", () async {
        final shell = File("$binPath/rootfs/bin/sh");
        final linker = File("$binPath/rootfs/usr/lib/ld-linux-armhf.so.3");
        final shellExists = await shell.exists();
        final linkerExists = await linker.exists();
        debugPrint("📄 /bin/sh exists=$shellExists @ \${shell.path}");
        debugPrint("📄 ld-linux-armhf.so.3 exists=$linkerExists @ \${linker.path}");
        if (!shellExists || !linkerExists) throw Exception("❌ Shell or linker missing");
      });

      await _step("Java", () async {
        final javaBin = File("$binPath/java/bin/java");
        final exists = await javaBin.exists();
        final size = exists ? await javaBin.length() : 0;
        debugPrint("📦 Java → exists=$exists, size=$size bytes, path=\${javaBin.path}");
        if (!exists || size == 0) throw Exception("❌ Java binary missing or empty");
      });

      _status["Haveno Daemon"] = true;
      _startCountdown();
    } catch (e) {
      debugPrint("❌ Boot error (Android): $e");
      setState(() {
        debugPrint("🛑 Boot sequence marked as failed.");
        _bootFailed = true;
      });
    }
  }

  Future<void> _startBootWindows() async {
    try {
      final bin = await getApplicationSupportDirectory();
      final binPath = "${bin.path}/proot_bin";
      await _ensureUnameBinary();

      final test = await Process.run("$binPath/uname", []);
      debugPrint("🧪 uname test stdout (Windows): \${test.stdout}");
      debugPrint("⚠️ uname test stderr (Windows): \${test.stderr}");

      await _step("Java", () async {
        final daemonJar = File("$binPath/daemon/daemon.jar");
        final exists = await daemonJar.exists();
        final size = exists ? await daemonJar.length() : 0;
        debugPrint("📦 daemon.jar (for Windows) → exists=$exists, size=$size bytes, path=\${daemonJar.path}");
        if (!exists || size == 0) throw Exception("❌ daemon.jar missing or empty on Windows");
        debugPrint("ℹ️ Assuming system Java is available on PATH.");
      });

      _status["Haveno Daemon"] = true;
      _startCountdown();
    } catch (e) {
      debugPrint("❌ Boot error (Windows): $e");
      setState(() => _bootFailed = true);
    }
  }

  Widget _buildStatusRow(String name) {
    final ready = _status[name] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Icon(ready ? Icons.check_circle : Icons.radio_button_unchecked,
            color: ready ? Colors.greenAccent : Colors.redAccent, size: 24),
        const SizedBox(width: 12),
        Text(ready ? "$name loaded" : "Starting $name...",
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Launching HOpenCrypto",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              ..._components.map(_buildStatusRow).toList(),
              const SizedBox(height: 30),
              if (_status.values.every((v) => v))
                Center(
                    child: Text("Opening app in $_countdown...",
                        style: const TextStyle(color: Colors.white70, fontSize: 16)))
              else if (_bootFailed)
                Center(
                  child: Column(children: [
                    const Text("❌ Boot failed.", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                    TextButton(
                        onPressed: Platform.isWindows ? _startBootWindows : _startBootAndroid,
                        child: const Text("Retry", style: TextStyle(color: Colors.tealAccent))),
                  ]),
                )
            ],
          ),
        ),
      ),
    );
  }
}