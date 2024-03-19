class LoginForm extends StatefulWidget { 
  @override 
  _LoginFormState createState() => _LoginFormState(); 
} 
 
class _LoginFormState extends State<LoginForm> { 
  final _usernameController = TextEditingController(); 
  final _passwordController = TextEditingController(); 
 
  Future<void> _login() async { 
    final Uri url = Uri.parse('https://hlvm.ru/users/login/'); 
    final response = await http.post(url, body: { 
      'username': _usernameController.text, 
      'password': _passwordController.text, 
    }); 
 
    if (response.statusCode == 200) { 
      // Успешная авторизация 
    } else { 
      // Ошибка авторизации 
    } 
  } 
 
  @override 
  Widget build(BuildContext context) { 
    return Column( 
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
    ); 
  } 
}