import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override 
  State<StatefulWidget> createState() => _LoginFormState();
} 
 
class _LoginFormState extends State<LoginForm> { 
  final _usernameController = TextEditingController(); 
  final _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();
 
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
      final user = responseData['user'];
      await preferences.setString('user', user);
      await _storage.write(key: user, value: token);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MyHome(user: user)));
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
        title: Text('Login'),
      ),
      body: AutofillGroup(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(hintText: 'Введите имя пользователя'),
              keyboardType: TextInputType.text,
              onSubmitted: (_) => _login(),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(hintText: 'Введите пароль'),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              onSubmitted: (_) => _login(),
            ),
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
