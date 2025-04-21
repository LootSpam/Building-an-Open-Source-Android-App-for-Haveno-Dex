// ──────────────────────────────────────────────────────
// UI Section
// ──────────────────────────────────────────────
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dependenciesextractor_stage2.dart';

class DependenciesExtractor extends StatefulWidget {
  final String basePath;
  final String binPath;
  const DependenciesExtractor({Key? key, required this.basePath, required this.binPath}) : super(key: key);

  @override
  State<DependenciesExtractor> createState() => _DependenciesExtractorState();
}

class _DependenciesExtractorState extends State<DependenciesExtractor> {
  String _status = "Extracting files...";
  double _progress = 0.0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    debugPrint("*****Start of: dependenciesextractor.dart*****");
    _startExtraction();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
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
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("HOpenCrypto Extraction", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _progress, color: Colors.tealAccent, backgroundColor: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ──────────────────────────────────────────────────
// Extraction Section
// ──────────────────────────────────────────────────
Future<void> _startExtraction() async {
  try {
    final base = widget.basePath;
    final bin = widget.binPath;

    //─────────────────────────────────────────────
    // Define daemon path
    //─────────────────────────────────────────────
    final daemonSrc = File("$base/daemon.jar");
    final daemonDst = "$bin/daemon/daemon.jar";

    //─────────────────────────────────────────────
    // Windows-specific shortcut logic
    //─────────────────────────────────────────────
    if (Platform.isWindows) {
      final dirsToCreate = [
        Directory("$bin/tmp"),
        Directory("$bin/daemon"),
        Directory("$bin/rootfs"),
        Directory("$bin/java_tmp"),
        Directory("$bin/java"),
      ];
      for (final dir in dirsToCreate) {
        if (!await dir.exists()) await dir.create(recursive: true);
      }

      if (await daemonSrc.exists()) {
        await daemonSrc.copy(daemonDst);
        debugPrint("🧪 Copied daemon.jar to $daemonDst");
      } else {
        debugPrint("❌ daemon.jar missing at source path: $base/daemon.jar");
        setState(() {
          _status = "❌ daemon.jar not found — please re-download.";
          _progress = 0.0;
        });
        return;
      }

      _status = "Extraction skipped (Windows)";
      _progress = 1.0;
      if (!_disposed && mounted) setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DependenciesExtractorStage2(
            basePath: base,
            binPath: bin,
            javaTmpDir: Directory("$bin/java_tmp"),
          ),
        ),
      );
      return;
    }

    //─────────────────────────────────────────────
    // Paths and extraction targets
    //─────────────────────────────────────────────
    final busyboxDst = "$bin/busybox";
    final prootDst = "$bin/proot";

    final chunks = {
      "rootfs.tar.gz": "$bin/rootfs",
      "java.tar.gz": "$bin/java_tmp",
      "tor.tar.xz": "$bin/tor_tmp"
    };

    final dirsToCreate = [
      Directory("$bin/tmp"),
      Directory("$bin/daemon"),
      Directory("$bin/rootfs"),
      Directory("$bin/java_tmp"),
      Directory("$bin/java"),
      Directory("$bin/tor_tmp"),
      Directory("$bin/tor"),
      Directory("$bin/host_tmp"),
    ];

for (final dir in dirsToCreate) {
  final exists = await dir.exists();
  if (!exists) {
    await dir.create(recursive: true);
    debugPrint("📂 Created: ${dir.path}");
    await Process.run("chmod", ["-R", "777", dir.path]);
    debugPrint("🔐 chmod 777 applied: ${dir.path}");
  } else {
    debugPrint("📁 Exists: ${dir.path}");
  }
}

    //─────────────────────────────────────────────
    // BusyBox bootstrapping
    //─────────────────────────────────────────────
    if (!await File(busyboxDst).exists()) {
      await _extractBusyboxFromAssets(busyboxDst);
    }

    //─────────────────────────────────────────────
    // Iterate and extract .tar.gz/.xz chunks
    //─────────────────────────────────────────────
    for (final entry in chunks.entries) {
      final archiveName = entry.key;
      final archivePath = "$base/$archiveName";
      final extractTo = entry.value;

      if (!await File(archivePath).exists()) {
        throw Exception("Missing archive: $archivePath");
      }

      bool alreadyExtracted = false;
      if (archiveName == "rootfs.tar.gz") {
        alreadyExtracted = await File("$bin/rootfs/usr/lib/ld-linux-armhf.so.3").exists();
      } else if (archiveName == "java.tar.gz") {
        alreadyExtracted = await Directory("$bin/java_tmp").exists() &&
                 await Directory("$bin/java_tmp").list().any((_) => true);
      } else if (archiveName == "tor.tar.xz") {
        alreadyExtracted = await Directory("$bin/tor_tmp").exists() &&
                 await Directory("$bin/tor_tmp").list().any((_) => true);
      }

      if (alreadyExtracted) {
        debugPrint("✅ $archiveName already extracted. Skipping.");
        continue;
      }

      _status = "Extracting $archiveName...";
      if (!_disposed && mounted) setState(() {});

      final env = Map<String, String>.from(Platform.environment);
      env['PROOT_TMP_DIR'] = "$bin/tmp";



final process = await Process.start(
  prootDst,
  [
    "-0",
    "-r", "/",
    "--bind=$bin:/host",
    "--cwd=/host",
    "/host/busybox", "tar",
    "--no-same-owner",
    archiveName.endsWith(".xz") ? "-xJf" : "-xzf", archivePath,
    "-C", extractTo
  ],
  environment: env,
);



      await process.stdout.transform(SystemEncoding().decoder).forEach(debugPrint);
      await process.stderr.transform(SystemEncoding().decoder).forEach(debugPrint);

      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        final libExists = await Directory("$extractTo/lib").exists();
        if (!libExists) {
          throw Exception("Proot+BusyBox failed to extract $archiveName (code $exitCode)");
        }
      }

      await Process.run("chmod", ["-R", "777", extractTo]);
    }

    //─────────────────────────────────────────────
    // Copy daemon.jar (final stage)
    //─────────────────────────────────────────────

if (await daemonSrc.exists()) {
  final dstFile = File(daemonDst);
  if (!await dstFile.exists()) {
    await daemonSrc.copy(daemonDst);
    debugPrint("📦 Copied daemon.jar to $daemonDst");
  } else {
    debugPrint("✅ daemon.jar already present. Skipping copy.");
  }
}

// ──────────────────────────────────────────────────
// Java Flattening
// ──────────────────────────────────────────────────
final javaBinary = File("$bin/java/bin/java");
if (await javaBinary.exists()) {
  debugPrint("📦 Java already flattened → ${javaBinary.path}");
} else {
  final javaTarget = Directory("$bin/java");
  final javaTmp = Directory("$bin/java_tmp");

  if (await javaTarget.exists() && await javaTmp.exists()) {
    final isEmpty = !(await javaTarget.list().any((_) => true));
    if (isEmpty) {
      final subdirs = await javaTmp.list().where((e) => e is Directory).toList();
      if (subdirs.isNotEmpty) {
        final extracted = subdirs.first as Directory;
        debugPrint("📦 Flattening Java from ${extracted.path} → ${javaTarget.path}");
        await _copyDirectory(extracted, javaTarget);
        await Process.run("chmod", ["-R", "755", javaTarget.path]);
        debugPrint("✅ chmod 755 applied to java folder after flattening");
      } else {
        debugPrint("⚠️ java_tmp has no subdirs.");
      }
    }
  }
}
// ──────────────────────────────────────────────────
// Tor Flattening
// ──────────────────────────────────────────────────

final torTarget = Directory("$bin/tor");
final torTmp = Directory("$bin/tor_tmp");

if (await torTarget.exists() && await torTmp.exists()) {
  final isEmpty = !(await torTarget.list().any((_) => true));
  if (!isEmpty) {
    debugPrint("ℹ️ Tor directory already populated. Skipping flattening.");
  } else {
    final subdirs = await torTmp.list().where((e) => e is Directory).toList();
    if (subdirs.isNotEmpty) {
      final extracted = subdirs.first as Directory;
      debugPrint("📦 Flattening Tor from ${extracted.path} → ${torTarget.path}");
      await _copyDirectory(extracted, torTarget);

      final torLauncher = File("$bin/tor/start-tor-browser.desktop");
      if (await torLauncher.exists()) {
        final size = await torLauncher.length();
        debugPrint("✅ Flatten success: launcher found → $size bytes");
      } else {
        debugPrint("⚠️ Flatten done but launcher not found");
      }
    } else {
      debugPrint("⚠️ tor_tmp has no subdirs.");
    }
  }
}

// ──────────────────────────────────────────────────
// Tor Directory Listing
// ──────────────────────────────────────────────────

debugPrint("🔍 Listing top-level contents of Tor directory:");
await for (final entity in torTarget.list(recursive: false)) {
  final type = entity is Directory ? "📁" : "📄";
  final size = entity is File ? await entity.length() : 0;
  debugPrint("$type ${entity.path} ${entity is File ? "→ $size bytes" : ""}");
}

// ──────────────────────────────────────────────────
// proot_bin Directory Listing
// ──────────────────────────────────────────────────

debugPrint("🔍 Listing top-level contents of proot_bin:");
await for (final entity in Directory(bin).list(recursive: false)) {
  final type = entity is Directory ? "📁" : "📄";
  final size = entity is File ? await entity.length() : 0;
  debugPrint("$type ${entity.path} ${entity is File ? "→ $size bytes" : ""}");
}

final javaExec = File("$bin/java/bin/java");
if (await javaExec.exists()) {
  await Process.run("chmod", ["+x", javaExec.path]);
  debugPrint("✅ Forced chmod +x on java binary (final sanity)");
}

final ls = await Process.run("ls", ["-l", javaExec.path]);
debugPrint("🧾 java perms after chmod: ${ls.stdout.trim()}");


      _status = "Extraction complete.";
      _progress = 1.0;
      if (!_disposed && mounted) setState(() {});

      if (!_disposed && mounted) {
        await Future.delayed(const Duration(milliseconds: 250));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DependenciesExtractorStage2(
              basePath: base,
              binPath: bin,
              javaTmpDir: Directory("$bin/java_tmp"),
            ),
          ),
        );
      }
    } catch (e) {
      if (!_disposed && mounted) {
        setState(() => _status = "❌ Extraction failed: $e");
      }
    }
  }

  Future<void> _extractBusyboxFromAssets(String path) async {
    final bytes = await rootBundle.load('assets/proot_bin/busybox');
    final file = File(path);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    await Process.run("chmod", ["+x", path]);
    final testExec = await Process.run(path, ["--help"]);
    if (testExec.exitCode != 0) throw Exception("busybox not executable!");
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    final srcPath = source.absolute.path;
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relativePath = entity.path.substring(srcPath.length + 1);
      final newPath = "${destination.path}/$relativePath";

      if (entity is File) {
        final newFile = File(newPath);
        await newFile.create(recursive: true);
        await entity.copy(newFile.path);
      } else if (entity is Directory) {
        final newDir = Directory(newPath);
        await newDir.create(recursive: true);
      }
    }
  }
}