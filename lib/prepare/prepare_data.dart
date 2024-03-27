import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PrepareDataQRCode extends StatelessWidget {
  final String? data;

  const PrepareDataQRCode({super.key, this.data});

  Future<void> _getJson() async {
    final token = dotenv.env['TOKEN'];
    final response =
        await http.post(Uri.parse('https://proverkacheka.com/api/v1/check/get'),
            body: {
              'token': token,
              'qrraw': data,
            });
    if (response.statusCode == 200) {
      print(response.body);
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
