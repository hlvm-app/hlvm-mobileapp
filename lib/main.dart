import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/state/state.dart';
import 'package:hlvm_mobileapp/auth/auth.dart';
import 'package:hlvm_mobileapp/qr/qrview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:hlvm_mobileapp/qr/live_decode.dart';
import 'package:hlvm_mobileapp/qr/picture_decode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

  runApp(
      MaterialApp(
          home: isLoggedIn ? MyHome() : LoginForm(),
          routes: {
            '/MyHome': (context) => MyHome(),
            LiveDecodePage.routeName: (context) => const LiveDecodePage(),
            PictureDecode.routeName: (context) => const PictureDecode(),
          },
          debugShowCheckedModeBanner: false
      ));
}


class MyHome extends StatelessWidget {
  const MyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code for HLVM')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                onPressed: () => LiveDecodePage.open(context),
                child: const Text('Live Decode')
            ),
            ElevatedButton(
                onPressed: () => PictureDecode.open(context),
                child: const Text('Picture Decode')
            )
          ],
        )
      ),
    );
  }
}

