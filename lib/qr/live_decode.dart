import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:hlvm_mobileapp/prepare/prepare_data.dart';

///
/// Created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 28/06/22
class LiveDecodePage extends StatefulWidget {
  static const routeName = '/live';

  static get route =>
      {routeName: (BuildContext context) => const LiveDecodePage()};

  static open(BuildContext context) {
    Navigator.of(context).pushNamed(routeName);
  }

  const LiveDecodePage({super.key});

  @override
  LiveDecodePageState createState() => LiveDecodePageState();
}

class LiveDecodePageState extends State<LiveDecodePage> {
  Result? currentResult;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: QRCodeDartScanView(
        scanInvertedQRCode: true,
        onCapture: (Result result) {
          setState(() {
            currentResult = result;
          });
          if (currentResult != null) {
            _copyToClipboard(currentResult!.text);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PrepareDataQRCode(data: currentResult!.text),
              ),
            );
          }
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/MyHome');
                        },
                        child: Icon(Icons.home)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String? data) {
    if (data != null) {
      _vibrate();
    } else {
      _vibrate();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _vibrate() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != null && hasVibrator) {
      Vibration.vibrate();
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
