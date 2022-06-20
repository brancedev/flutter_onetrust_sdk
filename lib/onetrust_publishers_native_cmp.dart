import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class OTPublishersNativeSDK {
  static const EventChannel _eventChannel =
      EventChannel("OTPublishersChangeListener");
  static const EventChannel _uiInteractions =
      EventChannel("OTPublishersUIInteractionListener");
  static const MethodChannel _channel =
      MethodChannel('onetrust_publishers_native_cmp');

  static Future<bool> startSDK(
      String storageLocation, String domainIdentifier, String languageCode,
      [Map<String, String>? otInitParams]) async {
    final bool status = await _channel.invokeMethod('startSDK', {
      'storageLocation': storageLocation,
      'domainIdentifier': domainIdentifier,
      'languageCode': languageCode,
      'otInitParams': otInitParams
    });

    return status;
  }

  ///Determines whether or not a banner should be shown, based on settings in the OneTrust tenant & whether or not consent was gathered already.
  static Future<bool> shouldShowBanner() async {
    final bool shouldShowBanner =
        await _channel.invokeMethod('shouldShowBanner');
    return shouldShowBanner;
  }

  ///Returns the consent status for the inputted category; 0 = consent not given, 1 = consent given, -1 = invalid category, or SDK not yet initialized.
  static Future<int> getConsentStatusForCategory(String categoryId) async {
    final int status = await _channel.invokeMethod(
        'getConsentStatusForCategory', {'forCategory': categoryId});
    return status;
  }

  ///Shows the banner atop the current view
  static void showBannerUI() {
    _channel.invokeMethod('showBannerUI');
  }

  ///Shows the preference center atop the current view
  static void showPreferenceCenterUI() {
    _channel.invokeMethod('showPreferenceCenterUI');
  }

  ///Show Consent UIs for Age Gate, IDFA
  ///Returns [int?] with the resulting value of the prompt
  static Future<int?> showConsentUI(OTDevicePermission permissionType) async {
    final int? status = await _channel.invokeMethod(
        'showConsentUI', {'permissionType': permissionType.index});
    return status;
  }

  static Future<OTATTrackingAuthorizationStatus>
      getATTrackingAuthorizationStatus() async {
    int status =
        await _channel.invokeMethod("getATTrackingAuthorizationStatus");
    return OTATTrackingAuthorizationStatus.values[status];
  }

  ///Returns an [int?] with the resulting prompt value
  static Future<int?> getAgeGatePromptValue() async {
    int value = await _channel.invokeMethod("getAgeGatePromptValue");
    return value;
  }

  ///Starts listening for consent changes for the category IDs inputted
  static Stream<dynamic> listenForConsentChanges(List<String> categoryIds) {
    return _eventChannel.receiveBroadcastStream({'categoryIds': categoryIds});
  }

  //Starts listening for UI Interactions, eg. when the Banner leaves the view hierarchy
  static Stream<dynamic> listenForUIInteractions() {
    return _uiInteractions.receiveBroadcastStream();
  }

  //Gets the JavaScript that can be injected into a WebView to pass consent to pages running the OneTrust Cookies CMP
  static Future<String?> getOTConsentJSForWebView() async {
    final String? js = await _channel.invokeMethod('getOTConsentJSForWebView');
    return js;
  }

  //Exposes method to get cached identifier from OneTrust
  @Deprecated(
      "Use getCurrentActiveProfile instead. This will be removed in a future release.")
  static Future<String?> getCachedIdentifier() async {
    final String? identifier =
        await _channel.invokeMethod('getCachedIdentifier');
    return identifier;
  }

  static Future<String?> getCurrentActiveProfile() async {
    final String? identifier =
        await _channel.invokeMethod('getCurrentActiveProfile');
    return identifier;
  }

  //BYOUI Methods
  ///returns a [Map<String,dynamic>] containing all the information about the
  ///domain (application) including rulesets and template configurations.
  static Future<Map<String, dynamic>?> getDomainInfo() async {
    final data = await _channel.invokeMethod('getDomainInfo');
    return _encodeJson(data);
  }

  ///returns a [Map<String,dynamic>] which contains template based information
  ///like branding which includes keys for determining colors and styles in the
  ///UI specific to a template configured for the user's geolocation along with
  ///consent logging information.
  static Future<Map<String, dynamic>?> getCommonData() async {
    final data = await _channel.invokeMethod('getCommonData');
    return _encodeJson(data);
  }

  ///returns a [Map<String,dynamic>] containing the information about all the
  ///categories and sdk IDs specific to a template configured for the user's geolocation.
  static Future<Map<String, dynamic>?> getDomainGroupData() async {
    final data = await _channel.invokeMethod('getDomainGroupData');
    return _encodeJson(data);
  }

  ///returns a [Map<String,dynamic>] which contains all the keys required to render a banner
  static Future<Map<String, dynamic>?> getBannerData() async {
    final data = await _channel.invokeMethod('getBannerData');
    return _encodeJson(data);
  }

  ///returns a [Map<String,dynamic>] which contains all the keys required to render a Preference Center.
  static Future<Map<String, dynamic>?> getPreferenceCenterData() async {
    final data = await _channel.invokeMethod('getPreferenceCenterData');
    return _encodeJson(data);
  }

  ///Used to programmatically update a user's consent for a specific category
  ///```dart
  ///updatePurposeConsent("C0002", true)
  ///```
  static void updatePurposeConsent(String categoryId, bool consentValue) {
    _channel.invokeMethod('updatePurposeConsent',
        {'group': categoryId, 'consentValue': consentValue});
  }

  ///Commits the user's staged consent to local storage and, if configured, sends
  ///a consent receipt to OneTrust. Takes an Enum to dictate the type of interaction.
  ///All consent updates (updatePurposeConsent) should all be made before calling
  ///this method. Calling this method with an Accept All or Reject All  interaction
  ///type will overwrite the consent as all accepted or all rejected.
  static void saveConsent(OTInteractionType interactionType) {
    _channel.invokeMethod(
        'saveConsent', {'interactionType': interactionType.index + 1});
  }

  ///Unstages any pending consent. For example, if a user closes out of a
  ///preference center without hitting save, this should be called to clear out
  ///the choices they made in order to abandon them
  static void resetUpdatedConsent() {
    _channel.invokeMethod("resetUpdatedConsent");
  }

  ///Private function to encode the JSON coming back from iOS and Android native
  ///for the BYOUI methods
  static Map<String, dynamic>? _encodeJson(dynamic data) {
    if (data == null) {
      return null;
    }
    Map<String, dynamic>? serialized =
        json.decode(data) as Map<String, dynamic>;
    return serialized;
  }
}

///Enums for type-safety
///Enum describing the permission prompt to surface
enum OTDevicePermission { idfa, ageGate }

///Apple's App Tracking Transparency statuses
enum OTATTrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  platformNotSupported
}

///Enum describing a user's interaction with the CMP. Used to trigger a save
///action programmatically
enum OTInteractionType {
  bannerAllowAll,
  bannerRejectAll,
  bannerContinueWithoutAccepting,
  bannerClose,
  preferenceCenterAllowAll,
  preferenceCenterRejectAll,
  preferenceCenterConfirm,
  preferenceCenterClose,
  consentPurposesConfirm,
  consentPurposesClose,
  vendorListConfirm,
  appTrackingConfirm,
  appTrackingOptOut,
  ucPreferenceCenterConfirm
}
