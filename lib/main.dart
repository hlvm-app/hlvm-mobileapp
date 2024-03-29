import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hlvm_mobileapp/qr/live_decode.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;
  String? user = preferences.getString('user');
  print(user);
  print(isLoggedIn);
  await dotenv.load();

  runApp(MaterialApp(
      home: isLoggedIn ? MyHome(user: user!) : LoginForm(),
      routes: {
        '/MyHome': (context) => MyHome(user: user),
        LiveDecodePage.routeName: (context) => const LiveDecodePage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark,)
      ),
      debugShowCheckedModeBanner: false));
}

class MyHome extends StatefulWidget {
  final String? user;
  const MyHome({super.key, required this.user});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
      case 1:
        page = AccountPage(user: widget.user ?? '');
      case 2:
        page = ReceiptPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                      icon: Icon(Icons.home), label: Text('Домашняя страница')),
                  NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined), label: Text('Счета')),
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
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _logout,
          tooltip: 'LogOut',
          child: Icon(Icons.logout_outlined),
        ),
      );
    });
  }
  void _logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('isLoggedIn', false);

    final storage = FlutterSecureStorage();
    await storage.delete(key: 'user');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginForm()),
    );
  }
}

class HomePage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Домашняя страница', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
      ),
    );
  }
}


class AccountPage extends StatelessWidget {
  final String? user;
  final Future<String?> tokenFuture;
  final storage = FlutterSecureStorage();

  AccountPage({super.key, required this.user})
      : tokenFuture = _initTokenFuture(user!);

  static Future<String?> _initTokenFuture(String user) async {
    final storage = FlutterSecureStorage();
    return await storage.read(key: user);
  }

  Future<List<Map<String, dynamic>>?> _getAccount(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('https://hlvm.ru/account/api/list'),
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final decodedResponse = jsonDecode(responseBody);
        final List<Map<String, dynamic>> accounts = [];
        for (var item in decodedResponse) {
          accounts.add({
            'name_account': item['name_account'],
            'balance': item['balance'].toString(),
            'currency': item['currency'].toString(),
          });
        }
        return accounts;
      } else {
        print('Не удалось получить список счетов');
        return null;
      }
    } catch (e) {
      print('Ошибка при получении списка счетов: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Ошибка при получении токена'),
            ),
          );
        } else {
          final token = snapshot.data;
          if (token != null) {
            return FutureBuilder<List<Map<String, dynamic>>?>(
              future: _getAccount(token),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Ошибка при получении списка счетов'),
                    ),
                  );
                } else {
                  final List<Map<String, dynamic>> accounts = snapshot.data ?? [];
                  return Scaffold(
                    body: Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          final account = accounts[index];
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AccountCard(
                              name: account['name_account'],
                              balance: account['balance'],
                              currency: account['currency'],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            );
          } else {
            return Text('Токен отсутствует');
          }
        }
      },
    );
  }
}

class AccountCard extends StatelessWidget {
  const AccountCard({
    super.key,
    required this.name,
    required this.balance,
    required this.currency,
  });

  final String name;
  final String balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 3),
            Text(
              'Баланс: $balance $currency',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}




class ReceiptPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: SafeArea(
          child: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => LiveDecodePage.open(context),
                    child: const Icon(Icons.qr_code_scanner_outlined),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
