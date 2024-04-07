import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hlvm_mobileapp/qr/live_decode.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isLoggedIn = preferences.getBool('isLoggedIn') ?? false;
  String? token = preferences.getString('token');
  await dotenv.load();

  runApp(MaterialApp(
      home: isLoggedIn ? MyHome(token: token!) : LoginForm(),
      routes: {
        '/MyHome': (context) => MyHome(token: token),
        LiveDecodePage.routeName: (context) => const LiveDecodePage(),
      },
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      )),
      debugShowCheckedModeBanner: false));
}

class MyHome extends StatefulWidget {
  final String? token;

  const MyHome({super.key, required this.token});

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
        page = AccountPage(token: widget.token ?? '');
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
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: Text('Счета')),
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
    await storage.delete(key: 'token');

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
        child: Text(
          'Домашняя страница',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AccountPage extends StatefulWidget {
  final String? token;

  AccountPage({Key? key, this.token}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final storage = FlutterSecureStorage();
  late int? selectedAccountId;

  @override
  void initState() {
    super.initState();
    _loadSelectedAccount();
  }

  Future<void> _loadSelectedAccount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAccountId = prefs.getInt('selectedAccount');
    });
  }

  Future<void> _selectAccount(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedAccountId = id;
    });
    print(widget.token);
    prefs.setInt('selectedAccount', id);
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
            'id': item['id'],
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
    return FutureBuilder<List<Map<String, dynamic>>?>(
      future: _getAccount(widget.token),
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
                      id: account['id'] ?? 0,
                      name: account['name_account'],
                      balance: account['balance'],
                      currency: account['currency'],
                      isSelected: selectedAccountId == account['id'],
                      onSelect: () async {
                        await _selectAccount(account['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
    );
  }
}

class AccountCard extends StatefulWidget {
  const AccountCard({
    super.key,
    required this.id,
    required this.name,
    required this.balance,
    required this.currency,
    required this.isSelected,
    required this.onSelect,
  });

  final int id;
  final String name;
  final String balance;
  final String currency;
  final bool isSelected;
  final Function onSelect;

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.onSelect();
      },
      child: AnimatedOpacity(
        opacity: widget.isSelected ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 3),
                Text(
                  'Баланс: ${widget.balance} ${widget.currency}',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReceiptPage extends StatefulWidget {
  ReceiptPage({Key? key}) : super(key: key);

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  late List<Map<String, dynamic>> _receiptList;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _receiptList = [];
    loadSellerData();
  }

  Future<void> loadSellerData() async {
    await listSeller();
    await listReceipt();
  }

  double _convertSum(dynamic number) {
    if (number != null) {
      return double.parse(number.toString());
    } else {
      return 0;
    }
  }

  dynamic findValueByKey(Map<String, dynamic> json, String key) {
    dynamic result;

    json.forEach((k, v) {
      if (k == key) {
        if (key == 'user' && v is! String) {
          result = '';
        } else {
          result = v;
        }
      }

      if (v is Map<String, dynamic>) {
        var innerResult = findValueByKey(v, key);

        if (innerResult != null) {
          result = innerResult;
        }
      }

      if (result != null) {
        return;
      }
    });

    return result;
  }

  Future<String?> listSeller({int sellerId = 907}) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('token');

    Dio dio = Dio();
    dio.interceptors.add(DioCacheManager(
            CacheConfig(baseUrl: 'https://hlvm.ru/receipts/seller/$sellerId'))
        .interceptor);
    dio.options.headers['Authorization'] = 'Token $token';

    Response response;
    try {
      response = await dio.get(
        'https://hlvm.ru/receipts/seller/$sellerId',
        options: buildCacheOptions(
          Duration(days: 7), // Кэширование на 7 дней
          maxStale: Duration(days: 7),
          // Разрешить использовать устаревшие данные на 7 дней
          forceRefresh: true, // Принудительно обновить данные из сети
        ),
      );

      final List<Map<String, dynamic>> sellers =
          List<Map<String, dynamic>>.from(response.data);
      for (var seller in sellers) {
        if (seller['id'] == sellerId) {
          return seller['name_seller']; // Возвращаем имя продавца
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> listReceipt() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('token');

    Dio dio = Dio();
    dio.interceptors.add(DioCacheManager(
            CacheConfig(baseUrl: 'https://hlvm.ru/receipts/api/list'))
        .interceptor);
    dio.options.headers['Authorization'] = 'Token $token';

    Response response;
    try {
      response = await dio.get(
        'https://hlvm.ru/receipts/api/list',
        options: buildCacheOptions(
          Duration(days: 7), // Кэширование на 7 дней
          maxStale: Duration(days: 7),
          // Разрешить использовать устаревшие данные на 7 дней
          forceRefresh: true, // Принудительно обновить данные из сети
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final decodedResponse = response.data;
    setState(() {
      _receiptList = List<Map<String, dynamic>>.from(decodedResponse);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список чеков'),
        actions: [
          IconButton(
            onPressed: () => LiveDecodePage.open(context),
            icon: Icon(Icons.qr_code_scanner_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _receiptList.isEmpty
              ? Center(
                  child: Text('Нет доступных чеков'),
                )
              : ListView.builder(
                  itemCount: _receiptList.length,
                  itemBuilder: (context, index) {
                    final receipt = _receiptList[index];
                    final totalSum =
                        _convertSum(findValueByKey(receipt, 'total_sum'));

                    return FutureBuilder<String?>(
                      future: listSeller(sellerId: receipt['customer']),
                      builder: (context, snapshot) {
                          final sellerName = snapshot.data ?? 'Загрузка...';

                          return ReceiptCard(
                            id: receipt['id'],
                            seller: sellerName,
                            receiptDate:
                                DateTime.parse(receipt['receipt_date']),
                            totalSum: totalSum,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Информация о товарах:', style: TextStyle(
                                      fontSize: 16,
                                    ),),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (var product
                                              in receipt['product'])
                                            ListTile(
                                              title: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  RichText(
                                                    text: TextSpan(
                                                      style:
                                                      DefaultTextStyle.of(
                                                          context)
                                                          .style,
                                                      children: [
                                                        TextSpan(
                                                          text: 'Наименование: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                              FontWeight
                                                                  .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                            '${product['product_name']}'),
                                                      ],
                                                    ),
                                                  ),
                                                  RichText(
                                                    text: TextSpan(
                                                      style:
                                                          DefaultTextStyle.of(
                                                                  context)
                                                              .style,
                                                      children: [
                                                        TextSpan(
                                                          text: 'Цена: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '${product['price']}'),
                                                      ],
                                                    ),
                                                  ),
                                                  RichText(
                                                    text: TextSpan(
                                                      style:
                                                          DefaultTextStyle.of(
                                                                  context)
                                                              .style,
                                                      children: [
                                                        TextSpan(
                                                          text: 'Количество: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '${product['quantity']}'),
                                                      ],
                                                    ),
                                                  ),
                                                  RichText(
                                                    text: TextSpan(
                                                      style:
                                                          DefaultTextStyle.of(
                                                                  context)
                                                              .style,
                                                      children: [
                                                        TextSpan(
                                                          text: 'Сумма: ',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        TextSpan(
                                                            text:
                                                                '${product['amount']}'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Закрыть'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }
                    );
                  },
                ),
    );
  }
}

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    Key? key,
    required this.id,
    required this.receiptDate,
    required this.totalSum,
    required this.seller,
    required this.onTap,
  }) : super(key: key);

  final int id;
  final DateTime receiptDate;
  final double totalSum;
  final String? seller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5),
              Text(
                'Продавец: ${seller.toString()}',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                'Дата: ${receiptDate.toString()}',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 5),
              Text(
                'Сумма: $totalSum',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
