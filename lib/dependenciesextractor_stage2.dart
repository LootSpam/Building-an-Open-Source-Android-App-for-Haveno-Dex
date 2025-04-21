// ─────────────────────────────────────────────────────────────
// Imports and UI logic
// ─────────────────────────────────────────────────────────────
import 'dart:async'; // For async delays and Future operations
import 'dart:io'; // File and directory handling
import 'package:flutter/material.dart'; // Flutter UI framework
import 'dependenciesrun.dart'; // Next screen after extraction

class DependenciesExtractorStage2 extends StatefulWidget {
  final String basePath;
  final String binPath;
  final Directory javaTmpDir;

  DependenciesExtractorStage2({
    Key? key,
    required this.basePath,
    required this.binPath,
    required this.javaTmpDir,
  }) : super(key: key);

  @override
  State<DependenciesExtractorStage2> createState() => _DependenciesExtractorStage2State();
}

class _DependenciesExtractorStage2State extends State<DependenciesExtractorStage2> {
  String _status = "Finalizing setup...";
  
  bool _done = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    debugPrint("*****Start of: dependenciesextractor_stage2.dart*****");
    _startFinalization();
  }

  // ─────────────────────────────────────────────────────────────
  // Dependency Check
  // ─────────────────────────────────────────────────────────────
Future<void> _startFinalization() async {
  final bin = widget.binPath;

  // ─────────────────────────────────────────────
  // ✅ WINDOWS: Only check daemon.jar
  // ─────────────────────────────────────────────
  if (Platform.isWindows) {
    final daemonJar = File("$bin/daemon/daemon.jar");
    final exists = await daemonJar.exists();

    if (exists) {
      debugPrint("✅ daemon.jar found. Skipping further checks on Windows.");
      setState(() {
        _done = true;
        _status = "✅ Ready. Launching daemon...";
      });
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DependenciesRun()),
      );
    } else {
      debugPrint("❌ daemon.jar missing.");
      setState(() {
        _error = true;
        _status = "❌ daemon.jar not found in $bin.";
      });
    }
    return;
  }

  // ─────────────────────────────────────────────
  // ✅ ANDROID: Full updated validation
  // ─────────────────────────────────────────────

final filesToCheck = {
  "proot": "$bin/proot",
  "busybox": "$bin/busybox",
  "daemon": "$bin/daemon/daemon.jar",
  "java tar": "$bin/java.tar.gz",
  "rootfs tar": "$bin/rootfs.tar.gz",
};

  for (final entry in filesToCheck.entries) {
    await _logFile(entry.key, entry.value);
  }

final dirsToCheck = {
  "Java folder": "$bin/java",
  "Java_tmp folder": "${widget.javaTmpDir.path}",
  "RootFS folder": "$bin/rootfs",
  "Tor Browser folder": "$bin/tor/Browser",
};
for (final entry in dirsToCheck.entries) {
  await _logDirectory(entry.key, entry.value);
}

  final javaBinaryPath = "$bin/java/bin/java";
  final rootfsSoPath = "$bin/rootfs/usr/lib/ld-linux-armhf.so.3";

  await _logFile("Java binary", javaBinaryPath);
  await _logFile("RootFS linker", rootfsSoPath);





// ─────────────────────────────────────────────
// Java_tmp Folder Top-Level Listing
// ─────────────────────────────────────────────

debugPrint("🔍 Listing top-level contents of Java directory:");
final javaTop = Directory("$bin/java_tmp/jdk-21.0.6-full/bin");
if (await javaTop.exists()) {
  await for (final entity in javaTop.list(recursive: false)) {
    final type = entity is Directory ? "📁" : "📄";
    final size = entity is File ? await entity.length() : 0;
    debugPrint("$type ${entity.path} ${entity is File ? "→ $size bytes" : ""}");
  }
} else {
  debugPrint("❌ Java directory does not exist.");
}

// ─────────────────────────────────────────────
// Java /bin Directory Listing
// ─────────────────────────────────────────────

debugPrint("🔍 Listing contents of Java /bin directory:");
final javaBinDir = Directory("$bin/java/bin");
if (await javaBinDir.exists()) {
  await for (final entity in javaBinDir.list(recursive: false)) {
    final type = entity is Directory ? "📁" : "📄";
    final size = entity is File ? await entity.length() : 0;
    debugPrint("$type ${entity.path} ${entity is File ? "→ $size bytes" : ""}");
  }
} else {
  debugPrint("❌ java/bin directory does not exist.");
}

// ─────────────────────────────────────────────
// 🔬 Full Java Binary Diagnostic Block
// ─────────────────────────────────────────────
try {
  final busyboxPath = "$bin/busybox";
  final javaPath = javaBinaryPath;

  debugPrint("🧪 Java Diagnostics: Starting checks on $javaPath");

  // Check if it's a symlink
  final linkCheck = await Process.run(busyboxPath, ["ls", "-l", javaPath]);
  debugPrint("🔍 ls -l java → ${linkCheck.stdout}");

  // Resolve symlink if applicable
  final resolved = await Process.run(busyboxPath, ["readlink", "-f", javaPath]);
  debugPrint("🔗 java resolved path → ${resolved.stdout.trim()}");

  // Check the ELF interpreter
  final readelf = await Process.run(busyboxPath, ["readelf", "-l", javaPath]);
  final interp = readelf.stdout.toString().split('\n').firstWhere(
    (line) => line.contains("interpreter"),
    orElse: () => "❓ interpreter not found",
  );
  debugPrint("📎 ELF interpreter → $interp");

  // Check if it's executable
  final testExec = await Process.run(javaPath, ["-version"]);
  debugPrint("🚀 java -version stdout → ${testExec.stdout}");
  debugPrint("⚠️ java -version stderr → ${testExec.stderr}");
  debugPrint("📤 Exit code: ${testExec.exitCode}");

  // ldd output
  final ldd = await Process.run(busyboxPath, ["ldd", javaPath]);
  debugPrint("🔗 ldd output:\n${ldd.stdout}");
  if ((ldd.stderr ?? "").toString().trim().isNotEmpty) {
    debugPrint("⚠️ ldd stderr:\n${ldd.stderr}");
  }

} catch (e) {
  debugPrint("❌ Java diagnostic block failed: $e");
}






  final javaBinary = File(javaBinaryPath);
  final javaExists = await javaBinary.exists();

  if (javaExists) {
    setState(() {
      _done = true;
      _status = "✅ Java is present.";
    });
    await Future.delayed(const Duration(milliseconds: 300));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DependenciesRun()),
    );
  } else {
    setState(() {
      _error = true;
      _status = "❌ Java is missing or not properly extracted.";
    });
  }
}

  // ─────────────────────────────────────────────────────────────
  // Miscellaneous Utilities
  // ─────────────────────────────────────────────────────────────
  Future<void> _logFile(String label, String path) async { // Logs file existence and size
    final file = File(path);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    debugPrint("📦 $label → $path → ${exists ? "$size bytes" : "MISSING"}");
  }

Future<void> _logDirectory(String label, String path) async {
  final dir = Directory(path);
  final exists = await dir.exists();
  int fileCount = 0;

  if (exists) {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) fileCount++;
    }
  }

  debugPrint("📁 $label: $path → ${exists ? "$fileCount files" : "MISSING"}");
}

  // ─────────────────────────────────────────────────────────────
  // UI Section
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) { // Builds the UI for the finalization screen
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "HOpenCrypto Extraction",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _status,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (!_done && !_error)
                  const LinearProgressIndicator(color: Colors.tealAccent, backgroundColor: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
