import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'authentication.dart';
import 'config.dart';
import 'main.dart';



class LoginView extends StatefulWidget {
  final String? expiredSessionMessage;

  LoginView({Key? key, this.expiredSessionMessage}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _errorMessage = ''; // Used to display error messages from the server (e.g. invalid credentials)

  Future<void> _login() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/auth/login');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      // Store the JWT token using CrossPlatformTokenStorage
      await CrossPlatformTokenStorage.storeToken(data['access_token']);

      // Navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()), // Navigate to MyApp which will decide the home screen
      );
    } else {
      // Handle login failure
      setState(() {
        _errorMessage = json.decode(response.body)['msg'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            // Display the session expired message if it's passed
            if (widget.expiredSessionMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(widget.expiredSessionMessage!, style: TextStyle(color: Colors.red)),
              ),
            // Display login error messages
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
