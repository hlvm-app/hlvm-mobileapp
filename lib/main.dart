import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hlvm_mobileapp/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hlvm_mobileapp/qr/live_decode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;

  runApp(MaterialApp(
      home: isLoggedIn ? MyHome() : LoginForm(),
      routes: {
        '/MyHome': (context) => MyHome(),
        LiveDecodePage.routeName: (context) => const LiveDecodePage(),
      },
      debugShowCheckedModeBanner: false));
}

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Hasta La Vista, Money!',
        style: TextStyle(color: Colors.green),
      )),
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              extended: false,
              destinations: [
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text('Домашняя страница')),
                NavigationRailDestination(
                    icon: Icon(Icons.receipt), label: Text('Чеки')),
              ],
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) {
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
              child: Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedIndex == 0 || selectedIndex == 1)
                  ElevatedButton(
                    onPressed: () => LiveDecodePage.open(context),
                    child: const Icon(Icons.qr_code_scanner_outlined),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
