package com.onetrust.flutter.otpublishersnativesdk.onetrust_publishers_native_cmp;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

import androidx.annotation.NonNull;
import androidx.fragment.app.FragmentActivity;

import com.onetrust.otpublishers.headless.Public.DataModel.OTSdkParams;
import com.onetrust.otpublishers.headless.Public.DataModel.OTUXParams;
import com.onetrust.otpublishers.headless.Public.Keys.OTBroadcastServiceKeys;
import com.onetrust.otpublishers.headless.Public.OTCallback;
import com.onetrust.otpublishers.headless.Public.OTEventListener;
import com.onetrust.otpublishers.headless.Public.OTPublishersHeadlessSDK;
import com.onetrust.otpublishers.headless.Public.OTThemeConstants;
import com.onetrust.otpublishers.headless.Public.Response.OTResponse;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
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
      case "getATTrackingAuthorizationStatus":
        //These methods are currently only used for ATT on iOS, so we'll return 4 which corresponds to platformNotSupported
        result.success(4);
        break;
      case "getConsentStatusForCategory":
        String category = call.argument("forCategory");
        int status = ot.getConsentStatusForGroupId(category);
        result.success(status);
        break;
      case "getOTConsentJSForWebView":
        String js = ot.getOTConsentJSForWebView();
        result.success(js);
      case "getCachedIdentifier":
        String id = ot.getOTCache().getDataSubjectIdentifier();
        result.success(id);
        break;
    }
  }

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

