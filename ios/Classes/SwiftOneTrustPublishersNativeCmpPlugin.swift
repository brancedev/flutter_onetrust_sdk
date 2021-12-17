import Flutter
import UIKit
import OTPublishersHeadlessSDK
import AppTrackingTransparency

public class SwiftOneTrustPublishersNativeCmpPlugin: NSObject, FlutterPlugin {
    var viewController:FlutterViewController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "onetrust_publishers_native_cmp", binaryMessenger: registrar.messenger())
        let instance = SwiftOneTrustPublishersNativeCmpPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let consentChangeStream = FlutterEventChannel(name: "OTPublishersChangeListener", binaryMessenger: registrar.messenger())
        consentChangeStream.setStreamHandler(OTPublishersChangeListener())
        
        let uiInteractionStream = FlutterEventChannel(name:"OTPublishersUIInteractionListener", binaryMessenger: registrar.messenger())
        uiInteractionStream.setStreamHandler(OTPublishersUIInteractionListener())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController as? FlutterViewController{
            viewController = rootViewController
            OTPublishersHeadlessSDK.shared.setupUI(rootViewController, UIType: .none)
            OTPublishersHeadlessSDK.shared.addEventListener(rootViewController)
            
        }
        
        switch call.method{
        case "startSDK":
            startSDK(call: call, result: result)
        case "shouldShowBanner":
            result(OTPublishersHeadlessSDK.shared.shouldShowBanner())
        case "showBannerUI":
            OTPublishersHeadlessSDK.shared.showBannerUI()
        case "showPreferenceCenterUI":
            OTPublishersHeadlessSDK.shared.showPreferenceCenterUI()
        case "showConsentUI":
            guard let arguments = call.arguments else {return}
            if let permissionType = (arguments as? [String:Int])?["permissionType"]{
                showConsentUI(for: permissionType, result: result)
            }
        case "getATTrackingAuthorizationStatus":
            if #available(iOS 14, *){
                result(ATTrackingManager.trackingAuthorizationStatus.rawValue)
            }else{
                result(4) //if ATT not supported, pass back 4, which is platformNotSupported
            }
        case "getConsentStatusForCategory":
            guard let arguments = call.arguments else {return}
            if let args = arguments as? [String:String],
               let categoryId = args["forCategory"]{
                result(OTPublishersHeadlessSDK.shared.getConsentStatus(forCategory: categoryId))
            }
        case "getOTConsentJSForWebView":
            result(OTPublishersHeadlessSDK.shared.getOTConsentJSForWebView())
        case "getCachedIdentifier":
            result(OTPublishersHeadlessSDK.shared.cache.dataSubjectIdentifier)
        default:
            print("Invalid Method")
        }
    }
    
    private func startSDK(call:FlutterMethodCall, result: @escaping FlutterResult){
        guard let arguments = call.arguments else {return}
        if let args = arguments as? [String:Any],
           let storageLocation = args["storageLocation"] as? String,
           let domainIdentifier = args["domainIdentifier"] as? String,
           let languageCode = args["languageCode"] as? String{
            var params:OTSdkParams? = nil
            if let otParams = args["otInitParams"] as? [String:String]{
                params = OTSdkParams(countryCode: otParams["countryCode"], regionCode: otParams["regionCode"])
                
                if let versionOverride = otParams["setAPIVersion"]{
                    params?.setSDKVersion(versionOverride)
                }
            }
            
            OTPublishersHeadlessSDK.shared.startSDK(storageLocation: storageLocation,
                                                    domainIdentifier:domainIdentifier,
                                                    languageCode: languageCode,
                                                    params: params){(otResponse) in
                print("Status = \(otResponse.status) and error = \(String(describing: otResponse.error))")
                result(otResponse.status)
            }
        }
    }
    
    private func showConsentUI(for permissionInt:Int, result: @escaping FlutterResult){
        guard #available(iOS 14, *) else {
            //If iOS version is not available, pass back 4 (platformNotSupported)
            result(4)
            return
        }
        
        var permissionType:AppPermissionType?
        
        //Create a map of permission types so we can easily adopt new permissions in the future
        switch permissionInt{
        case 0:
            permissionType = .idfa
        default:
            permissionType = nil
        }
        //Only proceed if we have a valid permissionType and the viewController is valid.
        guard let newPermissionType = permissionType,
              let vc = viewController else {
            let error = FlutterError(code: "consentUI_err", message: "Invalid permissionType or ViewController was not able to be located for presentation.", details: "Pass a valid OTPermissionType")
            result(error)
            return
        }
        
        OTPublishersHeadlessSDK.shared.showConsentUI(for: newPermissionType, from: vc){
            /*after user dismisses the ATT prompt, pass back the rawValue of the type
              this is converted into an enum on the Flutter side */
            result(ATTrackingManager.trackingAuthorizationStatus.rawValue)
        }
    }
}

class OTPublishersChangeListener:NSObject, FlutterStreamHandler{
    var emit:FlutterEventSink?
    var error = FlutterError(code: "OneTrustInvalidArgs", message: "Unable to add/remove event listener; invalid parameter passed.", details: "You must listen for specific categories. Eg, pass C0002 to listen for changes to that category")
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        emit = events
        guard let args = arguments as? [String:[String]] else{
            return error
        }
        if let categories = args["categoryIds"]{
            categories.forEach{(catId) in
                NotificationCenter.default.addObserver(self, selector: #selector(listenForChanges(_:)), name: Notification.Name(catId as String), object: nil)
            }
            
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        guard let args = arguments as? [String:[String]] else {
            return error
        }
        if let category = args["categoryId"]{
            category.forEach{
                NotificationCenter.default.removeObserver(Notification.Name($0 as String))
            }
            
        }
        return nil
    }
    
    @objc func listenForChanges(_ notification:Notification){
        if let consentStatus = notification.object as? Int{
            emit?(["categoryId":notification.name, "consentStatus": consentStatus])
        }
    }
    
}

class OTPublishersUIInteractionListener:NSObject, FlutterStreamHandler{
    
    static var emit:FlutterEventSink?
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        FlutterViewController.emit.event = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        FlutterViewController.emit.event = nil
        return nil
    }
    
}



extension FlutterViewController:OTEventListener{
    public struct emit{
        static var event:FlutterEventSink?
    }
    
    private class eventData{
        let eventName:String
        let payload:[String:Any]?
        
        init(eventName:String, payload:[String:Any]?=nil) {
            self.eventName = eventName
            self.payload = payload
        }
        
        public func format() -> [String:Any]{
            return ["uiEvent":eventName, "payload":payload as Any]
        }
    }
    
    public func onHideBanner() {emit.event?(eventData(eventName: "onHideBanner").format())}
    public func onShowBanner() {emit.event?(eventData(eventName: "onShowBanner").format())}
    public func onBannerClickedRejectAll() {emit.event?(eventData(eventName: "onBannerClickedRejectAll").format())}
    public func onBannerClickedAcceptAll() {emit.event?(eventData(eventName: "onBannerclickedAcceptAll").format())}
    public func onShowPreferenceCenter() {emit.event?(eventData(eventName: "onShowPreferenceCenter").format())}
    public func onHidePreferenceCenter() {emit.event?(eventData(eventName: "onHidePreferenceCenter").format())}
    public func onPreferenceCenterRejectAll() {emit.event?(eventData(eventName: "onPreferenceCenterRejectAll").format())}
    public func onPreferenceCenterAcceptAll() {emit.event?(eventData(eventName: "onPreferenceCenterAcceptAll").format())}
    public func onPreferenceCenterConfirmChoices() {emit.event?(eventData(eventName: "onPreferenceCenterConfirmChoices").format())}
    public func onPreferenceCenterPurposeLegitimateInterestChanged(purposeId: String, legitInterest: Int8) {
        emit.event?(eventData(eventName: "onPreferenceCenterPurposeLegitimateInterestChanged", payload: ["purposeId":purposeId, "legitInterest":legitInterest]).format())
    }
    public func onPreferenceCenterPurposeConsentChanged(purposeId: String, consentStatus: Int8) {
        emit.event?(eventData(eventName: "onPreferenceCenterPurposeConsentChanged", payload: ["purposeId":purposeId, "consentStatus":consentStatus]).format())
    }
    public func onShowVendorList() {emit.event?(eventData(eventName: "onShowVendorList").format())}
    public func onHideVendorList() {emit.event?(eventData(eventName: "onHideVendorList").format())}
    public func onVendorListVendorConsentChanged(vendorId: String, consentStatus: Int8) {
        emit.event?(eventData(eventName: "onVendorListVendorConsentChanged", payload: ["vendorId":vendorId,"consentStatus":consentStatus]).format())
    }
    public func onVendorListVendorLegitimateInterestChanged(vendorId: String, legitInterest: Int8) {
        emit.event?(eventData(eventName: "onVendorListVendorLegitimateInterestChanged", payload: ["vendorId":vendorId,"legitInterest":legitInterest]).format())
    }
    public func onVendorConfirmChoices() {emit.event?(eventData(eventName: "onVendorConfirmChoices").format())}
    public func allSDKViewsDismissed(interactionType: ConsentInteractionType) {
        emit.event?(eventData(eventName: "allSDKViewsDismissed", payload: ["interactionType":interactionType.description as Any]).format() )
    }
    
}
