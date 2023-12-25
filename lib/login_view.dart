import 'dart:async';

import 'package:MyLittlePms/token_expiration_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
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
  //Timer? _tokenExpirationCheckTimer;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  FocusNode _focusNode = FocusNode();
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  String _errorMessage = ''; // Used to display error messages from the server (e.g. invalid credentials)

  @override
  void initState() {
    super.initState();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        RawKeyboard.instance.addListener(_handleKeyPress);
      } else {
        RawKeyboard.instance.removeListener(_handleKeyPress);
      }
    });

    TokenExpirationManager.stopRefreshTimer();  // Stop the timer from main.dart when the user is on the login screen
  }

  @override
  void dispose() {
    // Dispose of the TextEditingController instances
    _emailController.dispose();
    _passwordController.dispose();

    // Dispose of the FocusNode instances
    _focusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();

    // Remove the listener from the RawKeyboard instance
    RawKeyboard.instance.removeListener(_handleKeyPress);

    super.dispose();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _login();
    }
  }

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
      //await CrossPlatformTokenStorage.clearToken();
      var data = json.decode(response.body);
      await CrossPlatformTokenStorage.storeToken(data['access_token']);
      Map<String, dynamic> decodedToken = JwtDecoder.decode(
          data['access_token']);
      String department = decodedToken['department'] ?? 'None';
      if (department == "Suspended") {
        _errorMessage = 'Your account is suspended. Please contact support.';
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          WidgetsBinding.instance?.addPostFrameCallback((_) {  // Restart the timer from main.dart when the user is logged in
            TokenExpirationManager.startRefreshTimer(context);
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          );
        }
      }
    } else {
      var responseData = json.decode(response.body);
      _errorMessage = responseData['msg'];
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset('lib/icon-PMS.png', height: 200, width: 200),
                SizedBox(height: 16.0),
                Container(
                  constraints: BoxConstraints(maxWidth: 300),
                  child: Text(
                    'Login',
                    style: Theme
                        .of(context)
                        .textTheme
                        .headline5,
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          _passwordFocusNode
                              .requestFocus(), // Switch focus to next field
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 300),
                    child: TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
                if (widget.expiredSessionMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.expiredSessionMessage!,
                        style: TextStyle(color: Colors.red)),
                  ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_errorMessage,
                        style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
