# Product Catalog

A Flutter product catalog for Android and iOS.

## Getting started

Install Flutter 3.47.9 or later. For Android, you need the Android SDK
and an emulator or device. For iOS, you need macOS with Xcode
and a simulator or device.

```sh
flutter pub get
flutter devices
flutter run -d <device-id>
```

Run `flutter analyze` to check the project for static analysis issues.

## Offline mode

While online, the app saves catalog and search result pages to SQLite using
`sqflite`. If the connection fails, you can reopen previously loaded pages
for the same search query and view details for cached products. Cached data
persists across app restarts. The app loads photos over the network.
