import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onetrust_publishers_native_cmp/onetrust_publishers_native_cmp.dart';

import 'debugMenu.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _cmpDownloadStatus = 'Waiting';
  int _c0003Status = -1;
  int _c0004Status = -1;
  OTATTrackingAuthorizationStatus _attStatus =
      OTATTrackingAuthorizationStatus.notDetermined;
  String _dataSubjectId = "Unknown";
  @override
  void initState() {
    super.initState();
    initOneTrust();
    startListening();
  }

  Future<void> initOneTrust() async {
    bool? status;
    String appId;
    bool? shouldShowBanner;
    String? id;
    OTATTrackingAuthorizationStatus startupATTStatus;

    if (Platform.isAndroid) {
      appId = "162cfe19-aff6-4d60-b10e-6e7b6fdcfb8b-test";
    } else if (Platform.isIOS) {
      appId = "162cfe19-aff6-4d60-b10e-6e7b6fdcfb8b-test";
    } else {
      Exception("Platform not found!");
      return;
    }
    String AndroidUXParams = await DefaultAssetBundle.of(context)
        .loadString("assets/AndroidUXParams.json");
    Map<String, String> params = {
      "countryCode": "US",
      "regionCode": "GA",
      //"androidUXParams": AndroidUXParams
    };
    try {
      status = await OTPublishersNativeSDK.startSDK("cdn.cookielaw.org", appId, "en", params);
      shouldShowBanner = await OTPublishersNativeSDK.shouldShowBanner();
      id = await OTPublishersNativeSDK.getCachedIdentifier();
    } on PlatformException {
      print("Error communicating with platform code");
    }

    startupATTStatus =
        await OTPublishersNativeSDK.getATTrackingAuthorizationStatus();

    if (status! && shouldShowBanner!) {
      OTPublishersNativeSDK.showBannerUI();
    }

    if (!mounted) return;

    setState(() {
      _cmpDownloadStatus = status! ? 'Success!' : 'Error';
      _dataSubjectId = id!;
      _attStatus = startupATTStatus;
    });
  }

  void startListening() {
    var consentListener =
        OTPublishersNativeSDK.listenForConsentChanges(["C0003", "C0004"])
            .listen((event) {
      setCategoryState(event['categoryId'], event['consentStatus']);
      print("New status for " +
          event['categoryId'] +
          " is " +
          event['consentStatus'].toString());
    });

    var interactionListener =
        OTPublishersNativeSDK.listenForUIInteractions().listen((event) {
      print(event);
    });

    //consentListener.cancel(); //Cancel event stream before opening a new one
  }

  void setCategoryState(String category, int status) {
    setState(() {
      switch (category) {
        case "C0003":
          _c0003Status = status;
          break;
        case "C0004":
          _c0004Status = status;
          break;
        default:
          break;
      }
    });
  }

  void loadATTPrompt() async {
    int? status;
    status = await OTPublishersNativeSDK.showConsentUI(OTDevicePermission.idfa);
    if (status != null) {
      setState(() {
        _attStatus = OTATTrackingAuthorizationStatus.values[status!];
      });
    }
  }

  Column getATTColumn() {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              loadATTPrompt();
            },
            child: Text("Load ATT Prompt")),
        Text("ATT Status = $_attStatus\n")
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('OneTrust Download Status: $_cmpDownloadStatus\n'),
            ElevatedButton(
                onPressed: () {
                  OTPublishersNativeSDK.showBannerUI();
                },
                child: Text("Load Banner")),
            ElevatedButton(
                onPressed: () {
                  OTPublishersNativeSDK.showPreferenceCenterUI();
                },
                child: Text("Load Preference Center")),
            ElevatedButton(
                onPressed: () {
                  OTPublishersNativeSDK.showConsentUI(
                      OTDevicePermission.ageGate);
                },
                child: Text("Load Age Gate")),
            Platform.isIOS //conditionally render ATT Pre-prompt button
                ? getATTColumn()
                : Container(),
            Text('Category C0003 Status: $_c0003Status\n'),
            Text('Category C0004 Status: $_c0004Status\n'),
            Text('Data Subject Identifier is'),
            Text(_dataSubjectId, style: TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EvenMore()),
                  );
                },
                child: Text("More")),
          ],
        ),
      ),
    );
  }
}
