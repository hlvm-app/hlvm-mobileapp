import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/state.dart';
import 'auth/auth.dart';
import 'qr/qrview.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoggedIn) {
            return MyHome();
          } else {
            return LoginForm();
          }
        },
      ),
      routes: {
        '/myHome': (context) => MyHome(),
        '/qrView': (context) => QRViewExample(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
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

