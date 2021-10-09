import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Availability of the NFC reader.
enum NFCAvailability {
  not_supported,
  disabled,
  available,
}

class ResponseAPDU {
  final String sw1;
  final String sw2;
  final String data;

  const ResponseAPDU(
      {required this.sw1, required this.sw2, required this.data});

  static ResponseAPDU fromMap(Map<String, String> map) {
    return ResponseAPDU(sw1: map["sw1"]!, sw2: map["sw2"]!, data: map["data"]!);
  }
}

/// Main class of NFC Kit
class FlutterNfcKit {
  static const MethodChannel _channel = const MethodChannel('flutter_nfc_kit');

  /// get the availablility of NFC reader on this device
  static Future<NFCAvailability> get nfcAvailability async {
    final String availability =
        await _channel.invokeMethod('getNFCAvailability');
    return NFCAvailability.values
        .firstWhere((it) => it.toString() == "NFCAvailability.$availability");
  }

  /// Try to poll a NFC tag from reader.
  ///
  /// If tag is successfully polled, a session is started.
  ///
  /// The [timeout] parameter only works on Android (default to be 20 seconds). On iOS it is ignored and decided by the OS.
  ///
  /// On iOS, set [iosAlertMessage] to display a message when the session starts (to guide users to scan a tag),
  /// and set [iosMultipleTagMessage] to display a message when multiple tags are found.
  ///
  /// On Android, set [androidPlatformSound] to control whether to play sound when a tag is polled,.
  ///
  ///
  static Future<void> poll(
      {Duration? timeout,
      bool androidPlatformSound = true,
      String iosAlertMessage = "Hold your iPhone near the card",
      String iosMultipleTagMessage =
          "More than one tags are detected, please leave only one tag and try again."}) async {
    await _channel.invokeMethod('poll', {
      'timeout': timeout?.inMilliseconds ?? 20 * 1000,
      'iosAlertMessage': iosAlertMessage,
      'iosMultipleTagMessage': iosMultipleTagMessage
    });
  }

  /// Transceive data with the card / tag in the format of APDU (iso7816) or raw commands (other technologies).
  /// The [capdu] can be either of type Uint8List or hex string.
  /// Return value will be in the same type of [capdu].
  ///
  /// There must be a valid session when invoking.
  ///
  /// On Android, [timeout] parameter will set transceive execution timeout that is persistent during a active session.
  /// Also, Ndef TagTechnology will be closed if active.
  /// On iOS, this parameter is ignored and is decided by the OS again.
  /// Timeout is reset to default value when [finish] is called, and could be changed by multiple calls to [transceive].
  static Future<ResponseAPDU> transceive(String capdu,
      {Duration? timeout}) async {
    assert(capdu is String);
    dynamic res = await _channel.invokeMethod('transceive', {
      'data': capdu,
      'timeout': timeout?.inMilliseconds,
    });

    return ResponseAPDU.fromMap(Map<String, String>.from(res));
  }

  /// Finish current session.
  ///
  /// You must invoke it before start a new session.
  ///
  /// On iOS, use [iosAlertMessage] to indicate success or [iosErrorMessage] to indicate failure.
  /// If both parameters are set, [iosErrorMessage] will be used.
  static Future<void> finish(
      {String? iosAlertMessage, String? iosErrorMessage}) async {
    return await _channel.invokeMethod('finish', {
      'iosErrorMessage': iosErrorMessage,
      'iosAlertMessage': iosAlertMessage,
    });
  }

  /// iOS only, change currently displayed NFC reader session alert message with [message].
  /// There must be a valid session when invoking.
  /// On Android, call to this function does nothing.
  static Future<void> setIosAlertMessage(String message) async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod('setIosAlertMessage', message);
    }
  }
}
