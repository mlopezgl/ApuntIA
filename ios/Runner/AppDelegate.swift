import Flutter
import UIKit
import Vision
import ImageIO

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let storageQueue = DispatchQueue(label: "apuntia.storage")
    FlutterMethodChannel(name: "com.axiomanetwork.apuntia/storage", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "read" || call.method == "write" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let value = (call.arguments as? [String: Any])?["value"] as? String
        storageQueue.async {
          do {
            var directory = try FileManager.default.url(for: .applicationSupportDirectory,
              in: .userDomainMask, appropriateFor: nil, create: true)
            var resources = URLResourceValues()
            resources.isExcludedFromBackup = true
            try directory.setResourceValues(resources)
            let url = directory.appendingPathComponent("apuntia-v1.json")
            if call.method == "read" {
              let raw = FileManager.default.fileExists(atPath: url.path)
                ? try String(contentsOf: url, encoding: .utf8) : nil
              DispatchQueue.main.async { result(raw) }
            } else {
              guard let data = value?.data(using: .utf8) else {
                DispatchQueue.main.async { result(FlutterError(code: "input", message: "Faltan los datos.", details: nil)) }
                return
              }
              try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
              DispatchQueue.main.async { result(nil) }
            }
          } catch {
            DispatchQueue.main.async { result(FlutterError(code: "storage", message: "No se pudo acceder al archivo local.", details: nil)) }
          }
        }
      }
    FlutterMethodChannel(name: "com.axiomanetwork.apuntia/ocr", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "recognize" else { result(FlutterMethodNotImplemented); return }
        guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
          result(FlutterError(code: "input", message: "Falta la imagen.", details: nil)); return
        }
        DispatchQueue.global(qos: .userInitiated).async {
          do {
            let url = URL(fileURLWithPath: path)
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)
            let props = source.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [CFString: Any] }
            let orientationValue = (props?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["es-ES", "en-US"]
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(url: url, orientation: orientation).perform([request])
            let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async { result(text) }
          } catch {
            DispatchQueue.main.async { result(FlutterError(code: "ocr", message: "No se pudo leer la imagen.", details: nil)) }
          }
        }
      }
  }
}
