# Flutter NFC Kit

[![pub version](https://img.shields.io/pub/v/flutter_nfc_kit)](https://pub.dev/packages/flutter_nfc_kit)
![Build Example App](https://github.com/nfcim/flutter_nfc_kit/workflows/Build%20Example%20App/badge.svg)

Yet another plugin to provide NFC functionality on Android and iOS.

This plugin's functionalities include:

* transceive commands with tags / cards complying with:
  * ISO 7816 Smart Cards (layer 4, in APDUs)

### Android

* Add [android.permission.NFC](https://developer.android.com/reference/android/Manifest.permission.html#NFC) to your `AndroidManifest.xml`.

### iOS

* Add [Near Field Communication Tag Reader Session Formats Entitlements](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_nfc_readersession_formats) to your entitlements.

* Add [NFCReaderUsageDescription](https://developer.apple.com/documentation/bundleresources/information_property_list/nfcreaderusagedescription) to your `Info.plist`.

* Add [com.apple.developer.nfc.readersession.felica.systemcodes](https://developer.apple.com/documentation/bundleresources/information_property_list/systemcodes) and [com.apple.developer.nfc.readersession.iso7816.select-identifiers](https://developer.apple.com/documentation/bundleresources/information_property_list/select-identifiers) to your `Info.plist` as needed. WARNING: you **MUST** add them before invoking `poll` with `readIso18092` or `readIso15693` enabled, or your NFC **WILL BE TOTALLY UNAVAILABLE BEFORE REBOOT** due to a [CoreNFC bug](https://github.com/nfcim/flutter_nfc_kit/issues/23).

* Open Runner.xcworkspace with Xcode and navigate to project settings then the tab _Signing & Capabilities._

* Select the Runner in targets in left sidebar then press the "+ Capability" in the left upper corner and choose _Near Field Communication Tag Reading._

## Usage

### Error codes

We use error codes with similar meaning as HTTP status code. Brief explanation and error cause in string (if available) will also be returned when an error occurs.
