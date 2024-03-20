import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/state/state.dart';
import 'package:hlvm_mobileapp/auth/auth.dart';
import 'package:hlvm_mobileapp/qr/qrview.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

  runApp(
      MaterialApp(
          home: isLoggedIn ? MyHome() : LoginForm(),
          routes: {
            '/MyHome': (context) => MyHome(),
            '/qrView': (context) => QRViewExample(),
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
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/qrView');
          },
          child: const Text('Scan'),
        ),
      ),
    );
  }
}

