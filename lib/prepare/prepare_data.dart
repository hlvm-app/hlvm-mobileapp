import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

  Future<void> _getJson() async {
    final token = dotenv.env['TOKEN'];
    final response =
        await http.post(Uri.parse('https://proverkacheka.com/api/v1/check/get'),
            body: {
              'token': token,
              'qrraw': data,
            });
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = jsonDecode(response.body);
      print(jsonData);
      print('Seller: ${findValueByKey(jsonData, 'user')}');
      print('Items: ${findValueByKey(jsonData, 'items')}');
    } else {
      print(response.statusCode);
      print(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    _getJson();
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
