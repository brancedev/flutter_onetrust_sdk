import 'dart:async';

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

  ///Show consent UI
  static Future<OTATTrackingAuthorizationStatus?> showConsentUI(
      OTDevicePermission permissionType) async {
    OTATTrackingAuthorizationStatus authStatus =
        OTATTrackingAuthorizationStatus.notDetermined;
    final int? status = await _channel.invokeMethod(
        'showConsentUI', {'permissionType': permissionType.index});
    if (status != null) {
      authStatus = OTATTrackingAuthorizationStatus.values[status];
    }
    return authStatus;
  }

  static Future<OTATTrackingAuthorizationStatus>
      getATTrackingAuthorizationStatus() async {
    int status =
        await _channel.invokeMethod("getATTrackingAuthorizationStatus");
    return OTATTrackingAuthorizationStatus.values[status];
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
  static Future<String?> getCachedIdentifier() async {
    final String? identifier =
        await _channel.invokeMethod('getCachedIdentifier');
    return identifier;
  }
}

///Enums for type-safety
enum OTDevicePermission { idfa }
enum OTATTrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  platformNotSupported
}
