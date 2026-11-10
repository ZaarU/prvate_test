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
`sqflite`. If the connection fails, the app uses previously loaded pages
and can search cached product titles when a page is missing. You can search
with a new query and open details for cached products. Cached data persists
across app restarts. The app loads photos over the network.

## Test product deep links

The app opens a product directly from `productcatalog://app/products/<id>`.
Install the app on the emulator or simulator before running these commands.

### Android emulator

```sh
adb shell am force-stop com.example.product_catalog
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "productcatalog://app/products/1" -p com.example.product_catalog
adb shell am start -W -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "productcatalog://app/products/16" -p com.example.product_catalog
```

### iOS simulator

```sh
xcrun simctl terminate booted com.example.productCatalog
xcrun simctl openurl booted "productcatalog://app/products/1"
xcrun simctl openurl booted "productcatalog://app/products/16"
```

The first link opens product 1 from a cold start. The second replaces it
with product 16 while the app is running. The Back button returns to the catalog.
