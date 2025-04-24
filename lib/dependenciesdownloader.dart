import 'dart:async'; // Async utilities for Future/await
import 'dart:io'; // File I/O and process execution
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:http/http.dart' as http; // HTTP client for downloads
import 'package:path_provider/path_provider.dart'; // To get device storage paths
import 'package:permission_handler/permission_handler.dart'; // To request storage permissions
import 'package:device_info_plus/device_info_plus.dart'; // To detect Android SDK version
import 'dependenciesextractor.dart'; // Navigates to extractor screen after download
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DependenciesDownloader extends StatefulWidget {
  const DependenciesDownloader({Key? key}) : super(key: key);
@override
State<DependenciesDownloader> createState() => _DependenciesDownloaderState();
}

class _DependenciesDownloaderState extends State<DependenciesDownloader> {
  final _urls = [
    Uri.parse("https://skirsten.github.io/proot-portable-android-binaries/armv7/proot"),
    Uri.parse("https://download.bell-sw.com/java/17.0.15+10/bellsoft-jdk17.0.15+10-linux-arm32-vfp-hflt.tar.gz"),
    Uri.parse("https://cdimage.ubuntu.com/ubuntu-base/releases/jammy/release/ubuntu-base-22.04.5-base-armhf.tar.gz"),
    Uri.parse("https://www.nosignup.trade/monerodaemon/daemon.jar"),
    Uri.parse("https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv7l"),
    Uri.parse("https://sourceforge.net/projects/tor-browser-ports/files/13.0.9/tor-browser-linux-armhf-13.0.9.tar.xz"),
  ];

  final _filenames = [
    "proot",
    "java.tar.gz",
    "rootfs.tar.gz",
    "daemon.jar",
    "busybox",
    "tor.tar.xz",
  ];

  bool _hasPermissions = false, _isDownloading = false, _disposed = false;
  String _status = "Initializing...", _currentFile = "", _basePath = "", _binPath = "";
  double _progress = 0.0;

@override
void initState() {
  super.initState();
  debugPrint("*****Start of: dependenciesdownloader.dart*****");
  _isDownloading = true; // Temporarily disable the button
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await _checkPermissionsAndInit();
    if (mounted && !_disposed) {
      setState(() {
        _isDownloading = false; // Re-enable button only if truly needed
      });
    }
  });
}

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

Future<void> _checkPermissionsAndInit() async {  //Note: This method is British innit?
  try {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      bool granted = false;

      if (sdk >= 30) {
        final permissions = await [
          Permission.storage,
          Permission.manageExternalStorage,
          Permission.ignoreBatteryOptimizations,
          Permission.accessNotificationPolicy,
        ].request();

        granted = permissions.values.every((p) => p.isGranted);

        if (!granted && permissions.values.any((p) => p.isPermanentlyDenied)) {
          debugPrint("❌ One or more permissions permanently denied (API >= 30). Opening settings...");
          await openAppSettings();
          return;
        }
      } else {
        final storage = await Permission.storage.request();
        final battery = await Permission.ignoreBatteryOptimizations.request();
        final notification = await Permission.accessNotificationPolicy.request();

        granted = [storage, battery, notification].every((p) => p.isGranted);

        if (!granted && [storage, battery, notification].any((p) => p.isPermanentlyDenied)) {
          debugPrint("❌ One or more permissions permanently denied (API < 30). Opening settings...");
          await openAppSettings();
          return;
        }
      }

      if (!granted) {
        debugPrint("❌ Permission check failed — one or more permissions were denied.");
        setState(() => _status = "❌ Required permissions denied. Please allow and restart.");
        return;
      }
    } else {
      debugPrint("ℹ️ Skipping permission check — not on Android.");
    }

    final bin = await getApplicationSupportDirectory();
    _basePath = "${bin.path}/proot_bin";
    _binPath = _basePath;

    debugPrint("📁 basePath: $_basePath");
    debugPrint("📁 binPath: $_binPath");

    await Directory(_binPath).create(recursive: true);
    await Directory("$_binPath/tmp").create(recursive: true);

    bool allExist = true;
    for (final f in _filenames) {
      final file = File("$_binPath/$f");
      final exists = file.existsSync();
      final size = exists ? file.lengthSync() : 0;

      debugPrint("📦 Check: $f → exists=$exists, size=$size");
      debugPrint("📁 Path: ${file.path}");

      if (!exists || size == 0) allExist = false;
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (_disposed) return;
    setState(() {
      _hasPermissions = true;
      _status = allExist
          ? "All files present. Launching extractor..."
          : "Ready to download dependencies. (~500mb)";
    });
    if (allExist) _goToExtractor();
  } catch (e) {
    debugPrint("❌ Init error: $e");
    if (!_disposed) setState(() => _status = "Init failed: $e");
  }
}


  Future<void> _downloadDependencies() async {
    setState(() => _isDownloading = true);
    try {
      for (int i = 0; i < _urls.length; i++) {
        final name = _filenames[i];
        final targetPath = "$_binPath/$name";
        final file = File(targetPath);
        await file.parent.create(recursive: true);
        debugPrint("⬇️ Downloading $name to $targetPath");

        if (file.existsSync() && file.lengthSync() > 0) {
          debugPrint("⏩ Skipping $name (already exists)");
          continue;
        }

        if (_disposed) return;
        setState(() { _currentFile = name; _progress = 0.0; });

        final response = await http.Client().send(http.Request('GET', _urls[i]));
        final sink = file.openWrite(); 
        final total = response.contentLength ?? 0;
        int downloaded = 0;
        
        await for (final chunk in response.stream) {
          sink.add(chunk); 
          downloaded += chunk.length;
          if (_disposed) return;
          setState(() => _progress = total > 0 ? downloaded / total : 0.0);
        }
        
        await sink.close();

        final size = await file.length();
        debugPrint("✅ Downloaded $name → $size bytes");

        if (size == 0) throw Exception("$name is empty after download");

        debugPrint("📦 $name downloaded to: $targetPath");

        if (name == "busybox") {
          final bb = File("$_binPath/busybox-armv7l");
          if (await bb.exists()) {
            await bb.rename("$_binPath/busybox");
            debugPrint("🔁 Renamed busybox-armv7l → busybox");
          }
        }

        if (!Platform.isWindows) {
          final chmod = await Process.run("chmod", ["+x", targetPath]);
          debugPrint("⚙️ chmod $name: ${chmod.stderr}");
        } else {
          debugPrint("⚠️ Skipping chmod for $name on Windows.");
        }
      } // 👈 CLOSES the for loop here

      debugPrint("✅ All dependencies downloaded!");
      debugPrint("📁 basePath: $_basePath");
      debugPrint("📁 binPath: $_binPath");

      if (!_disposed) {
        setState(() => _status = "Download complete. Launching extractor...");
        debugPrint("🚀 Launching extractor with basePath=$_basePath and binPath=$_binPath");
        _goToExtractor();
      }
    } catch (e) {
      debugPrint("❌ Download failed: $e");
      if (!_disposed) setState(() => _status = "Download failed: $e");
    }
  }

  void _goToExtractor() {
    if (!_disposed && mounted) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => DependenciesExtractor(basePath: _basePath, binPath: _binPath)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = !_isDownloading;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[900], borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text("HOpenCrypto Downloader", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_isDownloading || _currentFile.isNotEmpty) Column(children: [
              Text(_currentFile, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: _progress, color: Colors.tealAccent, backgroundColor: Colors.grey),
            ]),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: canDownload ? _downloadDependencies : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canDownload ? Colors.tealAccent : Colors.grey,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Download Dependencies"),
            ),
            const SizedBox(height: 30),
            TextButton(onPressed: () => exit(0), child: const Text("Quit", style: TextStyle(color: Colors.white70)))
          ]),
        ),
      ),
    );
  }
}