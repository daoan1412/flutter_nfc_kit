import 'dart:async';
import 'dart:io' show Platform, sleep;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() => runApp(MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _platformVersion =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  NFCAvailability _availability = NFCAvailability.not_supported;
  final nfcKit = FlutterNfcKit();
  String? _result;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await nfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _availability = availability;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NFC Flutter Kit Example App'),
        ),
        body: SingleChildScrollView(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
              Text('Running on: $_platformVersion\nNFC: $_availability'),
              Text(_result ?? ""),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await nfcKit.poll();
                    await nfcKit.setIosAlertMessage("working on it...");
                  } catch (e) {
                    setState(() {
                      _result = 'error: $e';
                    });
                  }
                  // 00A40400 - tag
                  // 07 - length of value
                  // A0000002471001 - value
                  final x1 = await nfcKit.transceive(
                      "00A404000CA000000063504B43532D3135");
                  final x2 = await nfcKit.transceive(
                      "00200081083132333435363738");
                  final x3 = await nfcKit.transceive("00A40000026F00");
                  // 00B0000000878696E206368616F
                  final x4 = await nfcKit.transceive(
                      "00B0000000878696E206368616F".toUpperCase());
                  setState(() {
                    _result = 'sw1: ${x1.sw1}, sw2: ${x1.sw2}, data ${x1.data}';
                  });
                  await nfcKit.finish(iosAlertMessage: "Finished!");
                },
                child: Text('Start polling'),
              ),
            ]))),
      ),
    );
  }
}
