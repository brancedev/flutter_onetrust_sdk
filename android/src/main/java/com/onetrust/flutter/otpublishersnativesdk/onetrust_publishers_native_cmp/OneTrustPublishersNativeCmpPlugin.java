package com.onetrust.flutter.otpublishersnativesdk.onetrust_publishers_native_cmp;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;

import com.onetrust.otpublishers.headless.Public.DataModel.OTSdkParams;
import com.onetrust.otpublishers.headless.Public.DataModel.OTUXParams;
import com.onetrust.otpublishers.headless.Public.Keys.OTBroadcastServiceKeys;
import com.onetrust.otpublishers.headless.Public.OTCallback;
import com.onetrust.otpublishers.headless.Public.OTConsentInteractionType;
import com.onetrust.otpublishers.headless.Public.OTConsentUICallback;
import com.onetrust.otpublishers.headless.Public.OTEventListener;
import com.onetrust.otpublishers.headless.Public.OTPublishersHeadlessSDK;
import com.onetrust.otpublishers.headless.Public.OTThemeConstants;
import com.onetrust.otpublishers.headless.Public.PromptUIType;
import com.onetrust.otpublishers.headless.Public.Response.OTResponse;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Dictionary;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** OneTrustPublishersNativeCmpPlugin */
public class OneTrustPublishersNativeCmpPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

  private MethodChannel channel;
  private Context mContext;
  private Activity activity;
  private OTPublishersHeadlessSDK ot;
  private EventChannel consentChangeChannel;
  private EventChannel uiInteractionChannel;

  private String storageLocation;
  private String appId;
  private String language;
  private HashMap initParams;
  private OTUXParams uxParams;
  private OTSdkParams params;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    mContext = flutterPluginBinding.getApplicationContext();
    ot = new OTPublishersHeadlessSDK(mContext);
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "onetrust_publishers_native_cmp");
    channel.setMethodCallHandler(this);

    // Consent Change Event Channel //
    consentChangeChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "OTPublishersChangeListener");
    createConsentStreamChangeHandler(consentChangeChannel);

    // UI Interaction Event Channel //
    uiInteractionChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "OTPublishersUIInteractionListener");
    createUIInteractionStreamChangeHandler(uiInteractionChannel);
  }


  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    switch (call.method) {
      case "startSDK":
        startSDK(call, result);
        break;
      case "shouldShowBanner":
        result.success(ot.shouldShowBanner());
        break;
      case "showBannerUI":
        ot.showBannerUI((FragmentActivity) activity);
        break;
      case "showPreferenceCenterUI":
        ot.showPreferenceCenterUI((FragmentActivity) activity);
        break;
      case "showConsentUI":
        int uiType = call.argument("permissionType");
        showConsentUI(uiType, result);
        break;
      case "getATTrackingAuthorizationStatus":
        //These methods are currently only used for ATT on iOS, so we'll return 4 which corresponds to platformNotSupported
        result.success(4);
        break;
      case "getConsentStatusForCategory":
        String category = call.argument("forCategory");
        int status = ot.getConsentStatusForGroupId(category);
        result.success(status);
        break;
      case "getAgeGatePromptValue":
        result.success(ot.getAgeGatePromptValue());
        break;
      case "getOTConsentJSForWebView":
        String js = ot.getOTConsentJSForWebView();
        result.success(js);
        break;
      case "getCachedIdentifier":
      case "getCurrentActiveProfile": //This method will change in the future.
        String id = ot.getOTCache().getDataSubjectIdentifier();
        result.success(id);
        break;
      case "saveConsent":
        int rawInteractionType = call.argument("interactionType");
        saveConsent(rawInteractionType);
        break;

        /* All of the GET methods for BYOUI are JSON strings that are then parsed into a MAP on the flutter side */
      case "getDomainInfo":
        result.success(ot.getDomainInfo().toString());
        break;
      case "getCommonData":
        result.success(ot.getCommonData().toString());
        break;
      case "getDomainGroupData":
        result.success(ot.getDomainGroupData().toString());
        break;
      case "getBannerData":
        result.success(ot.getBannerData().toString());
        break;
      case "getPreferenceCenterData":
        result.success(ot.getPreferenceCenterData().toString());
        break;
      case "updatePurposeConsent":
        String consentGroup = call.argument("group");
        boolean consentValue = call.argument("consentValue");
        ot.updatePurposeConsent(consentGroup, consentValue);
        break;
      case "resetUpdatedConsent":
        ot.resetUpdatedConsent();
        break;
      default:
        result.error("OT Error", "Flutter method not implemented", call.method + "not implemented on Android");
    }
  }

  private void startSDK(@NonNull MethodCall call, @NonNull final Result result){
    storageLocation = call.argument("storageLocation");
    appId = call.argument("domainIdentifier");
    language = call.argument("languageCode");
    initParams = call.argument("otInitParams");

    //Create builders for the params objects so that we can add in params from the inputted hashmap
    OTUXParams.OTUXParamsBuilder uxParamsBuilder = OTUXParams.OTUXParamsBuilder.newInstance()
            .setOTSDKTheme(OTThemeConstants.OT_THEME_APP_COMPACT_LIGHT_NO_ACTION_BAR); //Always set theme as Flutter relies on Material under the hood

    OTSdkParams.SdkParamsBuilder paramsBuilder = OTSdkParams.SdkParamsBuilder.newInstance();

    //If the app does not put in any initParams, this block will skip.
    if(initParams != null){
      if(initParams.containsKey("countryCode")){
        paramsBuilder.setOTCountryCode(initParams.get("countryCode").toString());
      }

      if(initParams.containsKey("regionCode")){
        paramsBuilder.setOTRegionCode(initParams.get("regionCode").toString());
      }

      if(initParams.containsKey("setAPIVersion")){
        paramsBuilder.setAPIVersion(initParams.get("setAPIVersion").toString());
      }

      if(initParams.containsKey("androidUXParams")){
        try {
          uxParamsBuilder.setUXParams(new JSONObject((String) initParams.get("androidUXParams")));
        } catch (JSONException e) {
          e.printStackTrace();
        }
      }
    }

    //We must pass in uxParams every time so that the theme gets set
    uxParams = uxParamsBuilder.build();
    paramsBuilder.setOTUXParams(uxParams);
    params = paramsBuilder.build();

    ot.startSDK(storageLocation, appId, language, params, new OTCallback() {
      @Override
      public void onSuccess(@NonNull OTResponse otResponse) {
        result.success(true);
      }

      @Override
      public void onFailure(@NonNull OTResponse otResponse) {
        result.error("Error downloading", otResponse.getResponseMessage(), null);
      }
    });
  }

  private void showConsentUI(int devicePermission, final Result result){
    /* Transform the devicePermission int from flutter to the counterpart in Android */
    int promptType = OTFlutterConsentUIType.values()[devicePermission].getIntValue();

    /*If the type is only supported on iOS, the enum for devicePermission will have a negative
     *number whose opposite is the code for "not available on this platform" */
    if(promptType < 0){
      result.success((promptType)* -1);
      return;
    };

    ot.showConsentUI((FragmentActivity) activity, promptType, null, new OTConsentUICallback() {
      @Override
      public void onCompletion() {
        //TODO: Add in switch for different UITypes here. We only have one case now, so no need to clutter it up
        result.success(ot.getAgeGatePromptValue());
      }
    });
  }

  private void saveConsent(int interactionType){
    String interactionString = OTFlutterInteractionType.values()[interactionType].getStringValue();
    ot.saveConsent(interactionString);
  }
  //region OVERRIDDEN
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    this.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges () {

  }

  @Override
  public void onReattachedToActivityForConfigChanges (@NonNull ActivityPluginBinding binding){

  }

  @Override
  public void onDetachedFromActivity () {

  }
  //endregion
  //region CHANGELISTENERS
  private void createConsentStreamChangeHandler (EventChannel eventChannel){
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      BroadcastReceiver broadcastReceiver;

      @Override
      public void onListen(Object arguments, final EventChannel.EventSink events) {
        HashMap args = (HashMap) arguments;
        final ArrayList<String> categories = (ArrayList<String>) args.get("categoryIds");

        for (final String category : categories) {
          broadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
              int status = intent.getIntExtra(OTBroadcastServiceKeys.EVENT_STATUS, -1);
              HashMap<String, Object> dataStream = new HashMap<>();
              dataStream.put("categoryId", category);
              dataStream.put("consentStatus", status);
              events.success(dataStream);
            }
          };
          mContext.registerReceiver(broadcastReceiver, new IntentFilter(category));
        }

      }

      @Override
      public void onCancel(Object arguments) {
        mContext.unregisterReceiver(broadcastReceiver);
      }
    });
  }
  //endregionS
  //region UIINTERACTIONS
  private void createUIInteractionStreamChangeHandler (EventChannel eventChannel){
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, final EventChannel.EventSink events) {
        ot.addEventListener(new OTEventListener() {
          @Override
          public void onShowBanner() {
            events.success(new eventData("onShowBanner").format());
          }

          @Override
          public void onHideBanner() {
            events.success(new eventData("onHideBanner").format());
          }

          @Override
          public void onBannerClickedAcceptAll() {
            events.success(new eventData("onBannerClickedAcceptAll").format());
          }

          @Override
          public void onBannerClickedRejectAll() {
            events.success(new eventData("onBannerClickedRejectAll").format());
          }

          @Override
          public void onShowPreferenceCenter() {
            events.success(new eventData("onShowPreferenceCenter").format());
          }

          @Override
          public void onHidePreferenceCenter() {
            events.success(new eventData("onHidePreferenceCenter").format());
          }

          @Override
          public void onPreferenceCenterAcceptAll() {
            events.success(new eventData("onPreferenceCenterAcceptAll").format());
          }

          @Override
          public void onPreferenceCenterRejectAll() {
            events.success(new eventData("onPreferenceCenterRejectAll").format());
          }

          @Override
          public void onPreferenceCenterConfirmChoices() {
            events.success(new eventData("onPreferenceCenterConfirmChoices").format());
          }

          @Override
          public void onShowVendorList() {
            events.success(new eventData("onShowVendorList").format());
          }

          @Override
          public void onHideVendorList() {
            events.success(new eventData("onHideVendorList").format());
          }

          @Override
          public void onVendorConfirmChoices() {
            events.success(new eventData("onHideVendorConfirmChoices").format());
          }

          @Override
          public void onVendorListVendorConsentChanged(String s, int i) {
            HashMap<String, Object> payload = new HashMap<>();
            payload.put("vendorId", s);
            payload.put("consentStatus", i);

            events.success(new eventData("onVendorListVendorConsentChanged", payload).format());
          }

          @Override
          public void onVendorListVendorLegitimateInterestChanged(String s, int i) {
            HashMap<String, Object> payload = new HashMap<>();
            payload.put("vendorId", s);
            payload.put("legitInterest", i);

            events.success(new eventData("onVendorListVendorLegitimateInterestChanged", payload).format());
          }

          @Override
          public void onPreferenceCenterPurposeConsentChanged(String s, int i) {
            HashMap<String, Object> payload = new HashMap<>();
            payload.put("purposeId", s);
            payload.put("consentStatus", i);

            events.success(new eventData("onPreferenceCenterPurposeConsentChanged", payload).format());
          }

          @Override
          public void onPreferenceCenterPurposeLegitimateInterestChanged(String s, int i) {
            HashMap<String, Object> payload = new HashMap<>();
            payload.put("purposeId", s);
            payload.put("legitInterest", i);

            events.success(new eventData("onPreferenceCenterPurposeLegitimateInterestChanged", payload).format());
          }

          @Override
          public void allSDKViewsDismissed(String event) {
            HashMap<String, Object> payload = new HashMap<>();
            payload.put("interactionType", event);
            events.success(new eventData("allSDKViewsDismissed", payload).format());
          }
        });
      }

        @Override
        public void onCancel(Object arguments) {

        }
      });

    }
    //endregion
  //region ENUMS
    /* There are slight differences in the Enums for Android and iOS, so these are bridging enums
    * that are specific to Flutter. The order of these is important. They are exposed to Flutter in
    * this order, and we pass the index through the method channel  */
    private enum OTFlutterInteractionType {
      placeholder("Invalid"), //iOS starts the index of this enum with 1, so we offset
      bannerAllowAll(OTConsentInteractionType.BANNER_ALLOW_ALL),
      bannerRejectAll(OTConsentInteractionType.BANNER_REJECT_ALL),
      bannerContinueWithoutAccepting(OTConsentInteractionType.BANNER_CONTINUE_WITHOUT_ACCEPTING),
      bannerClose(OTConsentInteractionType.BANNER_CLOSE),
      preferenceCenterAllowAll(OTConsentInteractionType.PC_ALLOW_ALL),
      preferenceCenterRejectAll(OTConsentInteractionType.PC_REJECT_ALL),
      preferenceCenterConfirm(OTConsentInteractionType.PC_CONFIRM),
      preferenceCenterClose(OTConsentInteractionType.PC_CLOSE),
      consentPurposesConfirm(OTConsentInteractionType.UC_PC_CONFIRM),
      consentPurposesClose(OTConsentInteractionType.UC_PC_CONFIRM),
      vendorListConfirm(OTConsentInteractionType.VENDOR_LIST_CONFIRM),
      appTrackingConfirm("Invalid"), //only available on iOS
      appTrackingOptOut("Invalid"), //only available on iOS
      ucPreferenceCenterConfirm(OTConsentInteractionType.UC_PC_CONFIRM);

      private String stringValue;

      OTFlutterInteractionType(String stringValue){
        this.stringValue = stringValue;
      }

      public String getStringValue(){
        return this.stringValue;
      }
    }

    /* Enum for the PromptUITypes. There are differences in what is supported on iOS and Android,
    * so here we lay those out. The prompts respond with an integer that may be able to be mapped
    * to another enum in Flutter (at the time of writing, it's just IDFA that does that.) There's
    * always a code for "Platform Not Supported", so we pass in the negative version of that here
    * and if called on Android, it'll automatically return the "not supported" code. */
    private enum OTFlutterConsentUIType {
      idfa(-4),
      ageGate(PromptUIType.AGE_GATE);

      private int permissionType;
      OTFlutterConsentUIType(int permission){
        this.permissionType = permission;
      }
      public int getIntValue(){
        return this.permissionType;
      }
    }

    //endregion


  private class eventData {
    String interactionType;
    HashMap<String, Object> payload;

    eventData(String interactionType, HashMap payload) {
      this.interactionType = interactionType;
      this.payload = payload;
    }

    eventData(String interactionType) {
      this.interactionType = interactionType;
      this.payload = null;
    }

    public HashMap<String, Object> format() {
      HashMap eventLoad = new HashMap();
      eventLoad.put("uiEvent", interactionType);
      eventLoad.put("payload", payload);
      return eventLoad;
    }
  }
}

