import 'package:flutter/material.dart';
import 'package:onetrust_publishers_native_cmp/onetrust_publishers_native_cmp.dart';

class EvenMore extends StatelessWidget {
  const EvenMore({Key? key}) : super(key: key);

  void getJSForWebview() async {
    String? js = await OTPublishersNativeSDK.getOTConsentJSForWebView();
    print("JavaScript is $js");
  }

  void getConsentForC2() async {
    int? cat2Status =
        await OTPublishersNativeSDK.getConsentStatusForCategory("C0002");
    print("Status for C0002 = $cat2Status");
  }

  void updateConsentForC2(bool consent) async {
    OTPublishersNativeSDK.updatePurposeConsent("C0002", consent);
    print("Remember to save the consent!");
  }

  void saveConsent() async {
    OTPublishersNativeSDK.saveConsent(
        OTInteractionType.preferenceCenterConfirm);
  }

  void discardStagedConsent() async {
    OTPublishersNativeSDK.resetUpdatedConsent();
  }

  void getBannerData() async {
    Map<String, dynamic>? data = await OTPublishersNativeSDK.getBannerData();
    print(data);
  }

  void getDomainGroupData() async {
    Map<String, dynamic>? data =
        await OTPublishersNativeSDK.getDomainGroupData();
    print(data);
  }

  void getPreferenceCenterData() async {
    Map<String, dynamic>? data =
        await OTPublishersNativeSDK.getPreferenceCenterData();
    print(data);
  }

  void getCommonData() async {
    Map<String, dynamic>? data = await OTPublishersNativeSDK.getCommonData();
    print(data);
  }

  void getDomainInfo() async {
    Map<String, dynamic>? data = await OTPublishersNativeSDK.getDomainInfo();
    print(data);
  }

  void getAgeGateValue() async {
    int? ageGateValue = await OTPublishersNativeSDK.getAgeGatePromptValue();
    print("Age Gate Value is $ageGateValue");
  }

  ElevatedButton buttonBuilder(String text, void Function() func) {
    return ElevatedButton(onPressed: func, child: Text(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
      ),
      body: Center(
          child: ListView(
        padding: EdgeInsets.all(12.0),
        children: <Widget>[
          Text('Most of these functions simply print a value to the console.'),
          buttonBuilder("Get JS For Webview", getJSForWebview),
          buttonBuilder("Query Category C0002", getConsentForC2),
          buttonBuilder("Get Banner Data", getBannerData),
          buttonBuilder("Get Domain Groups", getDomainGroupData),
          buttonBuilder("Get Domain Info", getDomainInfo),
          buttonBuilder("Get Preference Center Data", getPreferenceCenterData),
          buttonBuilder("Get Common Data", getCommonData),
          buttonBuilder("Grant Consent for C0002", () {
            updateConsentForC2(true);
          }),
          buttonBuilder("Revoke Consent for C0002", () {
            updateConsentForC2(false);
          }),
          buttonBuilder("Save Updated Consent", saveConsent),
          buttonBuilder("Discard Staged Consent", discardStagedConsent),
          buttonBuilder("Age Gate Value", getAgeGateValue),
          buttonBuilder("Go Home", () {
            Navigator.pop(context);
          })
        ],
      )),
    );
  }
}
