## 6.28.0
* Added support for OneTrust 6.28.0

## 6.27.0
* Added support for OneTrust 6.27.0

## 6.26.0
* Added support for OneTrust 6.26.0

## 6.25.0
* Added support for iOS 6.25.1
* Added support for Android 6.25.0

## 6.24.0
* Added support for OneTrust 6.24.0

## 6.23.0
* Added support for OneTrust 6.23.0

## 6.22.0
* Added support for OneTrust 6.22.0
* Exposed `showConsentUI` method to render App Tracking Transparency pre-prompts on iOS

## 6.21.0
* Added support for OneTrust 6.21.0
* Exposed UXParams methods to pass in custom JSON for Android
* Added ability to override the OneTrust geolocation service with app-supplied location values
* Updated ReadMe to specify requirement for FragmentActivity

## 6.20.0
* Added support for OneTrust 6.20.0
* Exposed `getCachedIdentifier` method
* Published to Pub.dev

## 6.19.0
* Added support for OneTrust 6.19.0

## 6.18.0
* Added support for OneTrust 6.18.0

## 6.16.0
* Added `getOTConsentJSForWebView` function to return JS to inject into a WebView

## 6.15.0
* Replaced `initOTSDKData` with `startSDK` method
* Fixed force casting issue on Android

## 6.14.0
* Updated OTSDK version
* Added allSDKViewsDismissed event for Android

## 6.13.0
* Update versioning code
* Fixed crash when moving toggles on Android
* Updated to 6.13.0 SDK
* Added example of how to call different IDs for Android and iOS

## 6.12.0
Initial release is of version 6.13.0 to match the OneTrust SDK versioning. Exposes methods of the OTPublishersSDK to:
* Generate a UI
* Prompt users for consent
* Query saved consent status
* Subscribe to consent changes

