import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DependenciesWatchdog {
  static void start(String binPath) {
    debugPrint("🛡️ Watchdog started... polling every 10s");

    Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        debugPrint("🔍 Checking daemon status via haveno.pid...");
        final isDaemonRunning = await _checkDaemon(binPath);
        if (isDaemonRunning) {
          debugPrint("✅ Haveno Daemon is marked as running (process alive).");
        } else {
          debugPrint("⚠️ Daemon process not found — restarting Haveno Daemon...");
          await _restartDaemon(binPath);
        }
      } catch (e) {
        debugPrint("❌ Watchdog fatal error: $e");
      }
    });
  }

static Future<bool> _checkDaemon(String binPath) async {
  final marker = File("$binPath/haveno.pid");
  if (!await marker.exists()) {
    debugPrint("❌ haveno.pid not found.");
    return false;
  }

  final content = await marker.readAsString();
  final pid = int.tryParse(content.trim());
  if (pid == null) {
    debugPrint("❌ haveno.pid content is not a valid PID: '$content'");
    return false;
  }

  final result = await Process.run("$binPath/busybox", ["ps", "-ef"], environment: {"PATH": "$binPath"});
  final lines = result.stdout.toString().split('\n');

  for (final line in lines) {
    final tokens = line.trim().split(RegExp(r'\s+'));
    if (tokens.isNotEmpty && int.tryParse(tokens[0]) == pid) {
      debugPrint("🔍 PID $pid is still running. Line: $line");
      return true;
    }
  }

  debugPrint("⚠️ PID $pid not found in process list.");
  return false;
}

  static Future<void> _restartDaemon(String binPath) async {
    final proot = "$binPath/proot";
    final rootfs = "$binPath/rootfs";
    final busybox = "$binPath/busybox";
    final java = "$binPath/java/bin/java";
    final jar = "$binPath/daemon/daemon.jar";
    final marker = File("$binPath/haveno.pid");

    if (!await File(proot).exists()) throw Exception("❌ Missing: proot");
    if (!await File(java).exists()) throw Exception("❌ Missing: java");
    if (!await File(jar).exists()) throw Exception("❌ Missing: daemon.jar");

    final env = {
      "PROOT_TMP_DIR": "$binPath/tmp",
      "LD_LIBRARY_PATH": "/java/lib:/java/lib/server:/lib",
      "JAVA_HOME": "/java",
      "PATH": "/bin:/usr/bin:/host",
    };

    final args = [
      "-0",
      "-r", binPath,
      "--bind=$rootfs/lib:/lib",
      "--bind=$rootfs/usr/lib:/usr/lib",
      "--bind=$rootfs/tmp:/tmp",
      "--bind=$binPath/uname:/bin/uname",
      "--bind=$binPath/daemon:/daemon",
      "--bind=$busybox:/busybox",
      "--bind=/dev/null:/dev/null",
      "-w", "/tmp",
      "/java/bin/java",
      "-cp", "/daemon/daemon.jar",
      "haveno.core.app.HavenoHeadlessAppMain",
      "--apiPassword=hopen",
      "--useDevMode=true",
      "--useDevModeHeader=true",
      "--useDevPrivilegeKeys=true",
      "--ignoreDevMsg=true",
      "--logLevel=DEBUG",
      "--appName=HOpenCrypto",
      "--userDataDir=/host/tmp",
      "--appDataDir=/host/tmp"
    ];

    debugPrint("🚨 Relaunching Haveno Daemon with:");
    debugPrint("   $proot ${args.join(" ")}");

    final process = await Process.start(
      proot,
      args,
      workingDirectory: binPath,
      environment: env,
    );

    process.stdout.transform(SystemEncoding().decoder).listen(
      (line) => debugPrint("📤 [daemon stdout] $line"),
    );

    process.stderr.transform(SystemEncoding().decoder).listen((line) {
      if (line.contains("Resource not found: path = bin/monerod")) {
        debugPrint("⚠️ Skipping missing monerod — not required for this build");
        return;
      }
      debugPrint("⚠️ [daemon stderr] $line");
    });

    await marker.writeAsString(process.pid.toString());
    debugPrint("🔁 Watchdog restarted Haveno Daemon with PID ${process.pid} at ${DateTime.now()}.");

    final psCheck = await Process.run(
      "$binPath/busybox",
      ["ps", "-ef"],
      workingDirectory: binPath,
    );
    debugPrint("📋 [Watchdog] ps -ef:\n${psCheck.stdout}");
    debugPrint("📋 [Watchdog] ps stderr:\n${psCheck.stderr}");

    final netstat = await Process.run(
      "$binPath/busybox",
      ["netstat", "-tlnp"],
      environment: {"PATH": "$binPath"},
    );
    debugPrint("📡 [Watchdog] Netstat:\n${netstat.stdout}");
  }
}
