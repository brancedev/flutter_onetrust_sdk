# OTPublishersNativeSDK

Expose OneTrust's Native CMP platform to your Flutter project.

# Getting Started
## Versioning
The SDK version used must match the version of the JSON published from your OneTrust instance. For example, if you’ve published version 6.10.0 of the JSON in your OneTrust environment, you must use the Flutter plugin version 6.10.0 as well. It is recommended to specify a version to avoid automatic updates, as a OneTrust publish is required when you update your SDK version.

To install the OneTrust plugin, run `flutter pub add onetrust_publishers_native_cmp`

Specify a version in your `pubspec.yaml` file, for example:
```
dependencies:
  onetrust_publishers_native_cmp: '6.10.0'
```

After adding the plugin to your Flutter project, build the project to check for any immediate errors.

This plugin pulls the OneTrust SDK from mavenCentral and Cocoapods.

### Notes
OTPublishersNativeSDK supports a minimum iOS version of 11.0. You may have to specify a platform target in your `podfile`:
```ruby
platform :ios, '11.0'
```

In Android, the underlying Native SDK requires a `FragmentActivity` in order to render a UI. In your Android `MainActivity.java` file, ensure that the `MainActivity` class is extending `FlutterFragmentActivity`. 

Additionally, Android must use `targetSdkVersion 31` and `compileSDKVersion 31` or higher.

```java
public class MainActivity extends FlutterFragmentActivity {
}
```

# Usage
## Initialization
Initialize OneTrust to fetch the data configured in your OneTrust tenant. This will make one or two network calls (depending on the type of template) and deliver a JSON object that contains all of the information required to render a banner and preference center.

The init call is an async function that returns a boolean status value; `true` if the initialization and download of data was successful, `false` if not.

```dart
Future<void> initOneTrust() async{
    bool status;
    Map<String, String> params = { //Params are not required
      "countryCode":"US",
      "regionCode":"CA"
    }
    try{
      status = await OTPublishersNativeSDK.startSDK("cdn.cookielaw.org","dec6b152-4ad9-487b-8e5a-24a06298417f","en", params);
    } on PlatformException{
      print("Error communicating with platform-side code");
    }

    if (!mounted) return;

    setState(() {
      _cmpDownloadStatus = status ? 'Success!':'Error';
    });

  }
```
### Arguments
|Name|Type|Description|
|-|-|-|
|storageLocation|String|**[Required]** The CDN location for the JSON that the SDK fetches. (Usually, but not always, `cdn.cookielaw.org`.)
|domainIdentifier|String|**[Required]** The Application guid (retrieved from OneTrust Admin console)|
|languageCode|String|**[Required]** 2-digit ISO language code used to return content in a specific langauge.<br></br>**Note:** Any language code format which is not listed in OneTrust environment will be considered as invalid input.<br></br>**Note:** If the languageCode passed by your application is valid, but does not match with a language configuration for your template, then the SDK will return content in the default language configured in OneTrust environment (usually, but not always, English).
|params|Map<String, String>|Parameter map (see below for accepted values)

### Initialization Parameters
All initialization parameters are expected to be of type `String`, and all are optional.

|Name|Type|Description|
|-|-|-|
|countryCode|String|2-digit ISO country code that will override OneTrust's geolocation service for locating the user. Typically used for QA to test other regions, or if your application knows the user's location applicable for consent purposes.
|regionCode|String|2-digit ISO region code that will overide OneTrust's geolocation service.|
|androidUXParams|String|A stringified representation of the OTUXParams JSON object to override styling in-app. See **"Android - Custom Styling with UXParams JSON"** below.

## Show an Interface
The plugin can load a Banner or a Preference center using the methods below:

```dart
OTPublishersNativeSDK.showBannerUI(); //load Banner
OTPublishersNativeSDK.showPreferenceCenterUI(); //load Preference Center
```
To determine if a banner should be shown (based on the template rendered and the status of the user's current consent,) use the `shouldShowBanner()` method. This returns a `bool` indicating whether or not a banner should be shown.

```dart
bool _shouldShowBanner;
try{
      _shouldShowBanner = await OTPublishersNativeSDK.shouldShowBanner();
    } on PlatformException{
      print("Error communicating with platform-side code");
    }
    if(_shouldShowBanner){
      OTPublishersNativeSDK.showBannerUI();
    }
```

### Permission Prompts (App Tracking Transparency and Age Gate)
A permission prompt can be displayed for several reasons. Currently, two prompts are supported on Flutter: the App Tracking Transparency pre-prompt and the Age Gate prompt.

To surface these prompts, ensure that they have been configured in your OneTrust template. The prompts are surfaced by calling `showConsentUI` and passing in an `OTDevicePermission` enum. An integer is returned that indicates the result of the prompt.
```dart
//IDFA/ATT - iOS Only
 int authStatus = await OTPublishersNativeSDK.showConsentUI(OTDevicePermission.idfa);
 //Use the following to get the status as an enum -- there are several outcomes for IDFA specifically
 OTATTrackingAuthorizationStatus IDFAStatus = OTATTrackingAuthorizationStatus.values[authStatus];

 //Age Gate - iOS and Android
 int authStatus = await OTPublishersNativeSDK.showConsentUI(OTDevicePermission.AgeGate);
 //returns a 0 (user responded no) or a 1 (user responded yes)
```
This method will not resolve until the user has made a selection for the permission prompt..

This method takes an argument of type `OTDevicePermission`, which is provided as an `enum` for ease of use. It returns an `OTATTrackingAuthorizationStatus`.
#### Query ATT Status
The current status of App Tracking Transparency can be obtained by calling
```dart
OTATTrackingAuthorizationStatus authStatus = await OTPublishersNativeSDK.getATTrackingAuthorizationStatus();
```

The above method returns an `OTATTTrackingAuthorizationStatus` which is namespaced as such to avoid issues with other ATT plugins being used. For unsupported OS versions (all Android versions and iOS versions < 14,) this function will immediately return `platformNotSupported`. Possible values of the enum are
* `notDetermined`
* `restricted`
* `denied`
* `authorized`
* `platformNotSupported`
  
#### Query for Age Gate Status
The current status of the Age Gate can be obtained by calling
```dart
int authStatus = await OTPublishersNativeSDK.getAgeGatePromptValue()
```
This method will return a 0 for a No response to the Age Gate and a 1 for a Yes response.

## Android - Custom Styling with UXParams JSON
OneTrust allows you to add custom styling to your preference center by passing in style JSON in a certain format. Build out your JSON by following the guide in the [OneTrust Developer Portal](https://developer.onetrust.com/sdk/mobile-apps/android/customize-ui).

Pass the JSON **as a string** into the `startSDK` function's `params` argument.

```dart
  String AndroidUXParams = await DefaultAssetBundle.of(context)
        .loadString("assets/AndroidUXParams.json");
    Map<String, String> params = {
      "androidUXParams": AndroidUXParams
    };
    try {
      status = await OTPublishersNativeSDK.startSDK(
          "cdn.cookielaw.org", appId, "en", params);
    } on PlatformException {
      print("Error communicating with platform code");
    }
```

## iOS - Custom Styling with UXParams Plist
Custom styling can be added to your iOS Cordova application by using a .plist file in the iOS platform code. In addition to adding the .plist file (which can be obtained from the OneTrust Demo Application) to your bundle, there are a few changes that need to be made in the platform code, outlined below. Review the guide in the [OneTrust Developer Portal](https://developer.onetrust.com/sdk/mobile-apps/ios/customize-ui).

In `AppDelegate.swift`, import OTPublishersHeadlessSDK. Add an extension below the class to handle the protocol methods:

```swift
import OTPublishersHeadlessSDK
...
extension AppDelegate: UIConfigurator{
    func shouldUseCustomUIConfig() -> Bool {
        return true
    }
    
    func customUIConfigFilePath() -> String? {
        return Bundle.main.path(forResource: "OTSDK-UIConfig-iOS", ofType: "plist")
    }
}

```

In the `didFinishLaunchingWithOptions` protocol method, assign the AppDelegate as the UIConfigurator:

```swift
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    OTPublishersHeadlessSDK.shared.uiConfigurator = self //add this line only
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Listening for UI Changes
The plugin implements an `EventChannel` that opens a `BroadcastStream` with the platform-side code. To listen for changes in the ui.

Note that:
* The `BroadcastStream` will stay open until it is closed by calling `.cancel()` on it
* Only one `BroadcastStream` per `EventChannel` can be open at a single time. Therefore, you must call `.cancel()` on this stream before calling `.listenForUIInteractions().listen` again.

```dart
var interactionListener = OTPublishersNativeSDK.listenForUIInteractions().listen((event) {
      print(event);
      });
```
Expected return:
```dart
{
    'uiEvent':String,
    'payload':Object
}
```
### UI Events
|Event Name|Description|Payload|
|-|-|-|
|onShowBanner|Triggered when banner is shown|`null`|
|onHideBanner|Triggered when banner is closed|`null`|
|onBannerClickedAcceptAll|Triggered when user allows all consent from banner|`null`|
onBannerClickedRejectAll|Triggered when user rejects all consent from banner|`null`|
onShowPreferenceCenter|Triggered when Preference Center is displayed|`null`|
onHidePreferenceCenter|Triggered when Preference Center is closed|`null`|
onPreferenceCenterAcceptAll|Triggered when user allows all consent from Preference Center|`null`|
onPreferenceCenterRejectAll|Triggered when user rejects all consent from Preference Center|`null`|
onPreferenceCenterConfirmChoices|Triggered when user clicked on save choices after updating consent values from Preference Center|`null`|
onShowVendorList|Triggered when vendor list UI is displayed from an IAB banner/ IAB Preference center|`null`|
onHideVendorList|Triggered when vendor list UI is closed or when back button is clicked|`null`|
onVendorConfirmChoices|Triggered when user updates vendor consent / legitimate interests purpose values and save the choices from vendor list|`null`|
onVendorListVendorConsentChanged|Triggered when user updates consent values for a particular vendor id on vendor list UI|`{vendorId:String, consentStatus:Int}`|
onVendorListVendorLegitimateInterestChanged|Triggered when user updates Legitimate interests values for a particular vendor id on vendor list UI|`{vendorId:String, legitInterest:Int}`|
onPreferenceCenterPurposeConsentChanged|Triggered when user updates consent values for a particular category on Preference Center UI|`{purposeId:String, consentStatus:Int}`|
onPreferenceCenterPurposeLegitimateInterestChanged|Triggered when user updates Legitimate interest values for a particular category on Preference Center UI|`{purposeId:String, legitInterest:Int}`|
allSDKViewsDismissed|Triggered when all the OT SDK Views are dismissed from the view hierarchy.|`{interactionType:String}`|

## When Consent Changes
The consent status is returned as an integer value:
|Status|Description|
|-|-|
|1|Consent given|
|0|Consent not given|
|-1|Consent not gathered or SDK not initialized|
<br></br>
### Query for Consent
To get the present consent state for a category, you can query for consent:

```dart
Future<void> getConsentStatus() async{
    int status;
    try{
      status = await OTPublishersNativeSDK.getConsentStatusForCategory("C0002");
    } on PlatformException{
      print("Error communicating with platform-side code.");
    }
    print("Queried Status for C0002 is = "+status.toString());
  }
```
### Listen for Consent Changes
The plugin implements an `EventChannel` that opens a `BroadcastStream` with the platform-side code. To listen for changes to the consent state.

Note that:
* The `BroadcastStream` will stay open until it is closed by calling `.cancel()` on it
* Only one `BroadcastStream` per `EventChannel` can be open at a single time. Therefore, you must call `.cancel()` on this stream before calling `.listenForConsentChanges().listen` again.

```dart
var consentListener = OTPublishersNativeSDK.listenForConsentChanges(["C0002","C0003"]).listen((event) {
      setCategoryState(event['categoryId'], event['consentStatus']);
      print("New status for "+event['categoryId']+" is "+event['consentStatus'].toString());
    });

    //consentListener.cancel() //cancel listener
```

This listener accepts an array of strings containing Category IDs to listen for. The listener returns an object:
```dart
{
    'categoryId':String
    'consentStatus':int
}
```

## Get OneTrust-set Data Subject Identifier
OneTrust sets a GUID to identify the user for audit purposes. The identifier can be used to look up the user's consent history in the OneTrust Consent module. To surface the identifier:

```dart
String id = await OTPublishersNativeSDK.getCachedIdentifier();
```

## Inject Consent to WebView
If you use WebViews in your applications, you may encounter a situation where you render a webpage running OneTrust’s Cookie Consent module, and the cookie banner is displayed. OneTrust provides a native way to take the consent gathered from the Native SDK and pass it down to the WebView.

To do this, simply call the function below to request a JavaScript variable from the OneTrust SDK. Placing this on the OneTrust SDK before the Cookies SDK loads will suppress the banner and pass consent to the WebView.

```dart
String jsToPass = await OTPublishersNativeSDK.getOTConsentJSForWebview();
```

## Build Your Own UI
The OneTrust SDK offers several methods that can be leveraged to build your own interface.

### Get Domain Info
This method returns a map containing all the information about the domain (application) including rulesets and template configurations.
```dart
Map<String, dynamic> domainInfo = await OTPublishersNativeSDK.getDomainInfo();
```

### Get Common Data
This method returns a map which contains template based information like branding which includes keys for determining colors and styles in the UI specific to a template configured for the user's geolocation along with consent logging information.

```dart
Map<String, dynamic> commonData = await OTPublishersNativeSDK.getCommonData();
```

### Get Groups Data
This method returns a dictionary containing the information about all the categories and sdk IDs specific to a template configured for the user's geolocation. This is generally used to populate the preference center's toggle section.

```dart
Map<String, dynamic> groups = await OTPublishersNativeSDK.getDomainGroupData();
```

### Get Banner Data
This method returns a dictionary which contains all the keys required to render a banner.
```dart
Map<String, dynamic> bannerData = await OTPublishersNativeSDK.getBannerData();
```

### Update Purpose Consent
This method is used to modify the consent status of a category by passing Custom Group ID as the key and consent status as value. Note that you have to call 'saveConsent(OTInteractionType)', with type being ConsentInteractionType, to have any modifications you perform to actually register in OneTrust SDK. OneTrust will notify the consent status changes to your app on saving changes.

```dart
  //A user has just toggled on Category C0002
  OTPublishersNativeSDK.updatePurposeConsent("C0002", true);
  //After the user has made all of their selections and taps save, execute the saveConsent method below
```
### Save Consent
Call this method to save the user's consent when they've indicated they wish for their consent to take effect. Examples include calling this method when a user accepts all on the banner, or after they've made all of their selections inside of a preference center.
```dart
//User confirms their choices in Pref Center
OTPublishersNativeSDK.saveConsent(OTInteractionType.preferenceCenterConfirm);

//User accepts all on the banner
OTPublishersNativeSDK.saveConsent(OTInteractionType.bannerAllowAll);
```

If configured, this will cause a record of consent to be sent. It will also signal the choices to the rest of your application via listeners.

The `OTInteractionType` is a convenient way to keep track of interaction types. There are many, but the most commonly used are
|Enum Name|Description|
|-|-|
|`bannerAllowAll`|User has accepted all on the banner.|
|`bannerRejectAll`|User has rejected all on teh banner.|
|`bannerContinueWithoutAccepting`|User has selected the "Continue Without Accepting" CNIL button on the banner.|
|`bannerClose`|User has closed the banner without making a selection.|
|`preferenceCenterAllowAll`|User has selected Allow All in the preference center.|
|`preferenceCenterRejectAll`|User has selected Reject All in the preference center.|
|`preferenceCenterConfirm`|User has made selections in the Preference Center and tapped Confirm.|

### Reset Local Consent
If a user has made selections in the preference center but then closes the preference center without saving, call this method to abandon the "staged" consent changes.
```dart
OTPublishersNativeSDK.resetUpdatedConsent();
```

## Resolving Dependency Clashes
In rare cases, one of the dependencies required by OneTrust's underlying Native Android SDK may clash with dependencies in your application. Most of the time, Gradle will resolve these automatically. If that is not the case however, OneTrust provides the option to suppress all transitive dependencies from the OneTrust `.aar` file.

To suppress all transitive dependencies, add `onetrust.includeTransitiveDependencies=false` to your Android project's `local.properties` file. **If your application suppresses OneTrust's dependencies, the dependencies must be added to your project manually.** A list of required dependencies is available at [Developer.OneTrust.com](https://developer.onetrust.com).