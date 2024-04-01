import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hlvm_mobileapp/prepare/prepare_data.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override 
  State<StatefulWidget> createState() => _LoginFormState();
} 
 
class _LoginFormState extends State<LoginForm> { 
  final _usernameController = TextEditingController(); 
  final _passwordController = TextEditingController();
 
  Future<void> _login() async {
    final response = await http.post(
        Uri.parse('https://hlvm.ru/users/login/'), body: jsonEncode(<String, String>{
      'username': _usernameController.text, 
      'password': _passwordController.text, 
    }));
    if (response.statusCode == 200) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setBool('isLoggedIn', true);

      final responseData = jsonDecode(response.body);
      final token = responseData['token'];
      print(token);
      final user = responseData['user'];
      print(user);
      await preferences.setString('user', user);
      await preferences.setString('token', token);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHome(token: token)));
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Ошибка входа'),
            content: Text('Имя пользователя или пароль неверны.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Hasta La Vista, Money!')),
      ),
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                    hintText: 'Введите имя пользователя',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
                ),
                keyboardType: TextInputType.text,
                onSubmitted: (_) => _login(),
              ),
            ),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                    hintText: 'Введите пароль',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
                ),
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                onSubmitted: (_) => _login(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              autofocus: true,
              onPressed: _login,
              child: Text('Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
