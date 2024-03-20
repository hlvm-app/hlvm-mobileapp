import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hlvm_mobileapp/main.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:hlvm_mobileapp/state/state.dart';


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
      Provider.of<AuthProvider>(context, listen: false).setLoggedIn(true);
      Navigator.pushReplacementNamed(context, '/MyHome');
      print(response.body);
    } else { 
      print('Неудача');
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(hintText: 'Введите имя пользователя'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(hintText: 'Введите пароль'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: _login,
            child: Text('Войти'),
          ),
        ],
      ),
    );
  }
}