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

  Future<void> createCustomerAndGetId(String token, accountId) async {
    final response = await http.post(
      Uri.parse('https://hlvm.ru/receipts/customer/api/create'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'user': 1,
        'name_seller': 'Example Seller', // Здесь передайте данные о продавце
        'retail_place_address': '123 Main Street',
        'retail_place': 'Example Store',
        // Другие данные о продавце, если необходимо
      }),
    );

    if (response.statusCode == 201) {
      // Если пользователь успешно создан
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final customerId = responseData['id'];
      print('Customer ID: $customerId');

      await _createReceiptWithCustomerId(token, customerId, accountId);
    } else {
      // Обработка ошибок
      print('Failed to create customer. Status code: ${response.statusCode}');
      print(response.body);
    }
  }


  Future<void> _createReceiptWithCustomerId(String token, int customerId, accountId) async {
    // String? usernameData = await getUsername();
    final jData = PrepareDataQRCode();
    final jsonData = await jData.getJson();
    print('JSON: $jsonData');
    // Map<String, dynamic> usernameJsonData = jsonDecode(usernameData!);
    // int usernameId = usernameJsonData['id'];
    final response = await http.post(
      Uri.parse('https://hlvm.ru/receipts/api/create'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        // 'user': usernameId,
        'account': accountId,
        'receipt_date': '2023-11-21T12:00:00Z',
        'number_receipt': 123456789,
        'nds10': 10.0,
        'nds20': 10.0,
        'operation_type': 1,
        'total_sum': 500,
        'customer': customerId,
        'product': [
          {
            // 'user': usernameId,
            'product_name': 'Product 1',
            'price': 10.00,
            'quantity': 2,
            'nds_type': 10,
          },
          {
            // 'user': usernameId,
            'product_name': 'Product 2',
            'price': 5.00,
            'quantity': 1,
            'nds_type': 20,
          },
        ],
      }),
    );

    if (response.statusCode == 201) {
      print('Receipt created successfully.');
    } else {
      print('Failed to create receipt. Status code: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<void> _createReceipt() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('token');
    final responseUser = await http.get(
      Uri.parse('https://hlvm.ru/users/list/user'),
      headers: <String, String>{
        'Authorization': 'Token $token',
      },
    );
    final jsonData = await getJson();
    print('jsonData: $jsonData');

    Map<String, dynamic> user = jsonDecode(responseUser.body);
    print(user);

    final nameSeller = findValueByKey(jsonData!, 'user');
    final retailPlaceAddress = findValueByKey(jsonData, 'retailPlaceAddress');
    final retailPlace = findValueByKey(jsonData, 'retailPlace');
    final response = await http.post(
      Uri.parse('https://hlvm.ru/receipts/customer/api/create'),
      headers: <String, String>{
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'user': user['id'],
        'name_seller': nameSeller, // Здесь передайте данные о продавце
        'retail_place_address': retailPlaceAddress,
        'retail_place': retailPlace,
      }),
    );
    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final customerId = responseData['id'];
      print('Customer ID: $customerId');
    } else {
      print('Failed to create customer. Status code: ${response.statusCode}');
      print(response.body);
    }
  }

  @override
  Widget build(BuildContext context) {
    _createReceipt();
    return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back)),
              ],
            ),
          ],
        ));
  }
}
