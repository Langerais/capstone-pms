import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'config.dart';
import 'db_helper.dart';
import 'login_view.dart';
import 'models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


enum UserGroup {
  Admin,
  Manager,
  Reception,
  Cleaning,
  Bar,
  Pending,
  Suspended,
  None
}

class Auth {

  static Future<UserGroup> getUserRole() async {
    String? token = await CrossPlatformTokenStorage.getToken();

    if (token == null) {
      return UserGroup.None; // Assuming you have a 'None' case for when no user is logged in
    }
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String department = decodedToken['department'] ?? 'None';

    switch (department) {
      case 'Admin':
        return UserGroup.Admin;
      case 'Manager':
        return UserGroup.Manager;
      case 'Reception':
        return UserGroup.Reception;
      case 'Cleaning':
        return UserGroup.Cleaning;
      case 'Bar':
        return UserGroup.Bar;
      default:
        return UserGroup.None;
    }
  }

  // Function to extract email from JWT token
  static Future<String?> _getEmailFromToken() async {
    final token = await CrossPlatformTokenStorage.getToken();
    if (token == null) return null;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    return decodedToken['sub'] as String?;
  }

  // Function to return the current user based on the JWT token
  static Future<User?> getCurrentUser() async {
    try {
      final email = await _getEmailFromToken();
      if (email == null) return null;
      User user = await UsersService.getUserByEmail(email);
      return user;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> checkPassword(String email, String password) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/auth/check_password');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  // Function to check if the JWT token has expired
  static Future<void> checkTokenExpiration(BuildContext context) async {
    String? token = await CrossPlatformTokenStorage.getToken();

    if (token != null && JwtDecoder.isExpired(token)) {
      // Token has expired, clear it and navigate to LoginView with a message
      await CrossPlatformTokenStorage.clearToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView(expiredSessionMessage: "Session Expired")),
      );
    }
  }

}

class CrossPlatformTokenStorage {
  static const _secureStorage = FlutterSecureStorage();
  static final _prefs = SharedPreferences.getInstance();

  static Future<void> storeToken(String token) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _secureStorage.write(key: 'jwt_token', value: token);
    } else {
      final prefs = await _prefs;
      await prefs.setString('jwt_token', token);
    }
  }

  static Future<String?> getToken() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await _secureStorage.read(key: 'jwt_token');
    } else {
      final prefs = await _prefs;
      return prefs.getString('jwt_token');
    }
  }

  static Future<void> clearToken() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _secureStorage.delete(key: 'jwt_token');
    } else {
      final prefs = await _prefs;
      await prefs.remove('jwt_token');
    }
  }
}



