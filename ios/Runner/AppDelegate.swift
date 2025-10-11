import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var handLandmarkerPlugin: HandLandmarkerPlugin?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup HandLandmarker channel
    let controller = window?.rootViewController as! FlutterViewController
    handLandmarkerPlugin = HandLandmarkerPlugin(messenger: controller.binaryMessenger)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
