import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class PrepareDataQRCode extends StatelessWidget {
  final String? data;

  const PrepareDataQRCode({super.key, this.data});

  dynamic findValueByKey(Map<String, dynamic> json, String key) {
    dynamic result;

    json.forEach((k, v) {
      if (k == key) {
        result = v;
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

  Future<Map<String, dynamic>?> getJson() async {
    final token = dotenv.env['TOKEN'];
    print(data);
    final response =
        await http.post(Uri.parse('https://proverkacheka.com/api/v1/check/get'),
            body: {
              'token': token,
              'qrraw': data,
            });
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      return null;
    }
  }


  double _convertSum(dynamic number) {
    if (number != null) {
      return number / 100;
    } else {
      return 0;
    }
  }

  String formatDate(String dateTimeString) {
    DateTime dateTime = DateTime.parse(dateTimeString);
    String formattedDate = '${dateTime.day.toString().padLeft(2, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}';
    return formattedDate;
  }

  Future<void> _createReceipt(BuildContext context, Map<String, dynamic> jsonData) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('token');
    int? selectedAccount = preferences.getInt('selectedAccount');
    final responseUser = await http.get(
      Uri.parse('https://hlvm.pavlovteam.ru/users/list/user'),
      headers: <String, String>{
        'Authorization': 'Token $token',
      },
    );

    Map<String, dynamic> user = jsonDecode(responseUser.body);

    final nameSeller = findValueByKey(jsonData, 'user');
    final retailPlaceAddress = findValueByKey(jsonData, 'retailPlaceAddress');
    final retailPlace = findValueByKey(jsonData, 'retailPlace');
    final items = findValueByKey(jsonData, 'items');
    final receiptDate = findValueByKey(jsonData, 'dateTime');
    final numberReceipt = findValueByKey(jsonData, 'fiscalDocumentNumber');
    final nds10 = _convertSum(findValueByKey(jsonData, 'nds10'));
    final nds20 = _convertSum(findValueByKey(jsonData, 'nds20'));
    final totalSum = _convertSum(findValueByKey(jsonData, 'totalSum'));
    final operationType = findValueByKey(jsonData, 'operationType');

    final List<Map<String, dynamic>> products = [];

    for (var item in items) {
      final name = findValueByKey(item, 'name');
      final amount = _convertSum(findValueByKey(item, 'sum'));
      final quantity = findValueByKey(item, 'quantity');
      final price = _convertSum(findValueByKey(item, 'price'));
      final ndsType = findValueByKey(item, 'nds');
      final ndsNum = _convertSum(findValueByKey(item, 'ndsSum'));
      products.add({
        'user': user['id'],
        'product_name': name,
        'amount': amount,
        'quantity': quantity,
        'price': price,
        'nds_type': ndsType,
        'nds_sum': ndsNum,
      });
    }

    final customer = {
      'user': user['id'],
      'name_seller': nameSeller,
      'retail_place_address': retailPlaceAddress,
      'retail_place': retailPlace,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Подтверждение'),
          content: Text('Вы уверены, что хотите добавить этот чек?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
        final response = await http.post(
          Uri.parse('https://hlvm.pavlovteam.ru/receipts/api/create'),
          headers: <String, String>{
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(<String, dynamic>{
            'user': user['id'],
            'account': selectedAccount,
            'receipt_date': receiptDate,
            'number_receipt': numberReceipt,
            'nds10': nds10,
            'nds20': nds20,
            'operation_type': operationType,
            'total_sum': totalSum,
            'customer': customer,
            'product': products,
          }),
        );

        if (response.statusCode == 201) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('Чек успешно добавлен.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/MyHome');
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          final responseBody = utf8.decode(response.bodyBytes);
          final decodedResponse = jsonDecode(responseBody);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Ошибка'),
              content: Text(decodedResponse),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/MyHome');
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('Error fetching data'));
        } else {
          final jsonData = snapshot.data!;
          final dynamic itemsData = findValueByKey(jsonData, 'items');

          if (itemsData is List<dynamic>) {
            final List<Map<String, dynamic>> items = [];
            for (var item in itemsData) {
              final name = findValueByKey(item, 'name');
              final amount = _convertSum(findValueByKey(item, 'sum'));
              final quantity = findValueByKey(item, 'quantity');
              final price = _convertSum(findValueByKey(item, 'price'));
              final ndsType = findValueByKey(item, 'nds');
              final ndsNum = _convertSum(findValueByKey(item, 'ndsSum'));
              items.add({
                'product_name': name,
                'amount': amount,
                'quantity': quantity,
                'price': price,
                'nds_type': ndsType,
                'nds_sum': ndsNum,
              });
            }

            return Center(

              child: SingleChildScrollView(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ReceiptCard(
                    nameSeller: findValueByKey(jsonData, 'user'),
                    receiptDate: formatDate(findValueByKey(jsonData, 'dateTime')),
                    totalSum: _convertSum(findValueByKey(jsonData, 'totalSum')),
                    products: items,
                  ),
                  SizedBox(height: 7),
                  ElevatedButton(
                    onPressed: () async {
                      await _createReceipt(context, jsonData);
                    },
                    child: Text('Добавить чек'),
                  ),
                  SizedBox(height: 6),
                ],
              ),
            )
            );
          } else {
            // Handle if itemsData is not a List<dynamic>
            return Center(child: Text('Error: Items data is not in the expected format'));
          }
        }
      },
    );
  }


}


class ReceiptCard extends StatelessWidget {
  final String nameSeller;
  final String receiptDate;
  final double? totalSum;
  final List<Map<String, dynamic>> products;

  ReceiptCard({
    required this.nameSeller,
    required this.receiptDate,
    required this.totalSum,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Продавец: $nameSeller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Дата: $receiptDate',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Итоговая сумма: ${totalSum?.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Список продуктов:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  title: Text('${product['product_name']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Цена: ${product['price']}'),
                      Text('Количество: ${product['quantity']}'),
                      Text('Сумма: ${product['amount']}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}