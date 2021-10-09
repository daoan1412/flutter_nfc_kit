import CoreNFC
import Flutter
import UIKit

// taken from StackOverflow
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = [.upperCase]) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}

func dataWithHexString(hex: String) -> Data {
    var hex = hex
    var data = Data()
    while hex.count > 0 {
        let subIndex = hex.index(hex.startIndex, offsetBy: 2)
        let c = String(hex[..<subIndex])
        hex = String(hex[subIndex...])
        var ch: UInt64 = 0
        Scanner(string: c).scanHexInt64(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}

public class SwiftFlutterNfcKitPlugin: NSObject, FlutterPlugin, NFCTagReaderSessionDelegate {
    var session: NFCTagReaderSession?
    var result: FlutterResult?
    var tag: NFCTag?
    var multipleTagMessage: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_nfc_kit", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterNfcKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // from FlutterPlugin
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "getNFCAvailability" {
            if NFCReaderSession.readingAvailable {
                result("available")
            } else {
                result("disabled")
            }
        } else if call.method == "poll" {
            if session != nil {
                result(FlutterError(code: "406", message: "Cannot invoke poll in a active session", details: nil))
            } else {
                let arguments = call.arguments as! [String: Any?]
                session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
                if let alertMessage = arguments["iosAlertMessage"] as? String {
                    session?.alertMessage = alertMessage
                }
                if let multipleTagMessage = arguments["iosMultipleTagMessage"] as? String {
                    self.multipleTagMessage = multipleTagMessage
                }
                self.result = result
                session?.begin()
            }
        } else if call.method == "transceive" {
            if tag != nil {
                let req = (call.arguments as? [String: Any?])?["data"]
                if req != nil, req is String {
                    var data: Data?
                    switch req {
                    case let hexReq as String:
                        data = dataWithHexString(hex: hexReq)
                    default:
                        data = nil
                    }

                    switch tag {
                    case let .iso7816(tag):
                        var apdu: NFCISO7816APDU?
                        if data != nil {
                            apdu = NFCISO7816APDU(data: data!)
                        }

                        if apdu != nil {
                            tag.sendCommand(apdu: apdu!, completionHandler: { (response: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                                if let error = error {
                                    result(FlutterError(code: "5004", message: "Communication error", details: error.localizedDescription))
                                } else {
                                    var apduResponse = ["sw1": String(format:"%02X", sw1),
                                            "sw2": String(format:"%02X", sw2),
                                            "data": response.hexEncodedString()] 
                                    result(apduResponse)
                                }
                            })
                        } else {
                            result(FlutterError(code: "400", message: "Command format error", details: nil))
                        }
                    default:
                        result(FlutterError(code: "405", message: "Transceive not supported on this type of card", details: nil))
                    }
                } else {
                    result(FlutterError(code: "400", message: "Bad argument", details: nil))
                }
            } else {
                result(FlutterError(code: "406", message: "No tag polled", details: nil))
            }
        } else if call.method == "finish" {
            self.result?(FlutterError(code: "406", message: "Session not active", details: nil))
            self.result = nil

            if let session = session {
                let arguments = call.arguments as! [String: Any?]
                let alertMessage = arguments["iosAlertMessage"] as? String
                let errorMessage = arguments["iosErrorMessage"] as? String

                if let errorMessage = errorMessage {
                    session.invalidate(errorMessage: errorMessage)
                } else {
                    if let alertMessage = alertMessage {
                        session.alertMessage = alertMessage
                    }
                    session.invalidate()
                }
                self.session = nil
            }

            tag = nil
            result(nil)
        } else if call.method == "setIosAlertMessage" {
            if let session = session {
                if let alertMessage = call.arguments as? String {
                    session.alertMessage = alertMessage
                }
                result(nil)
            } else {
                result(FlutterError(code: "406", message: "Session not active", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    // from NFCTagReaderSessionDelegate
    public func tagReaderSessionDidBecomeActive(_: NFCTagReaderSession) {}

    // from NFCTagReaderSessionDelegate
    public func tagReaderSession(_: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if result != nil {
            NSLog("Got error when reading NFC: %@", error.localizedDescription)
            result?(FlutterError(code: "5003", message: "Invalidate session with error", details: error.localizedDescription))
            result = nil
            session = nil
            tag = nil
        }
    }

    // from NFCTagReaderSessionDelegate
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 && result != nil {
            NSLog("tagReaderSession:more than 1 tag detected!")
            result?(FlutterError(code: "5001", message: "More than 1 tag detected!", details: nil))
            result = nil
            self.session = nil
            tag = nil
            return
        }
        
        let tag = tags.first!
        if session != nil {
            session.connect(to: tag) {[unowned self] (error: Error?) in
                if error != nil {
                    NSLog("tagReaderSession:failed to connect to tag")
                    result?(FlutterError(code: "5002", message: "Failed to connect to tag", details: nil))
                    self.tag = nil
                    self.session = nil
                    result = nil
                    return
                }
                self.tag = tag
                result?("")
            }
        } else {
            result?(FlutterError(code: "5005", message: "tagReaderSession: session is nil", details: nil))
            result = nil
            self.tag = nil
        }
    }
}
