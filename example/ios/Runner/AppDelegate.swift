import UIKit
import Flutter
import OTPublishersHeadlessSDK

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    OTPublishersHeadlessSDK.shared.uiConfigurator = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension AppDelegate: UIConfigurator{
    func shouldUseCustomUIConfig() -> Bool {
        return false //change to true to use values from plist
    }
    
    func customUIConfigFilePath() -> String? {
            return Bundle.main.path(forResource: "OTSDK-UIConfig-iOS", ofType: "plist")
    }
}
