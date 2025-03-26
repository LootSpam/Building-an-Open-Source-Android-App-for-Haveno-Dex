## Hopencrypto – Haveno Dart Client

Hopencrypto is a standalone [Haveno](https://haveno.exchange) client built with Flutter for both Android and Windows. It uses a local daemon (.jar or .so) to operate peer-to-peer, without relying on any external server.

> 100% self-custodial · Monero-based · Privacy-first

---

### Quick Start

This is a developer preview. Features are incomplete but progressing rapidly.

#### Step 1 – Create a Flutter project

```
flutter create hopencrypto
```

#### Step 2 – Replace the `/lib` folder

Delete the default `/lib` directory and drag in the `/lib` folder from this repository.

#### Step 3 – Replace `pubspec.yaml` with the following:

```yaml
name: hopencrypto
description: "A standalone Haveno client for Windows and Android with cross-device compatibility."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  haveno: ^3.0.4
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  path_provider: ^2.1.2
  http: ^0.13.6
  archive: ^3.3.7
  permission_handler: ^11.0.1
  flutter_secure_storage: ^9.2.4
  bip39: ^1.0.6
  crypto: ^3.0.6
  intl: ^0.18.1
  protobuf: ^3.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

---

### Current Feature Progress

- ✅ Wallet login with mnemonic (no password required)
- ✅ Create and cancel trade offers
- ✅ View and manage trade contracts
- ✅ Send/receive dispute and trade messages
- ✅ Withdraw funds from escrow
- ✅ Cross-platform UI (Windows/Android)
- 🔄 Local daemon via Termux (Android) and .jar (Windows) – in progress

---

### Links

- Project Spec: https://kewbit.org/start-developing-with-the-haveno-dart-client/
- Daemon Build: https://haveno.com/documentation/building-haveno-from-source/
- Mobile Guide: https://haveno.com/documentation/install-haveno-on-a-mobile-device/
- Haveno GitHub: https://github.com/haveno-dex/haveno
