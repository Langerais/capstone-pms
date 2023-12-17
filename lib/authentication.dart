import 'db_helper.dart';
import 'models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'drawer_menu.dart';
import 'main.dart';

const _baseUrl = 'http://16.16.140.209:5000';  //TODO: Move to config file

enum UserGroup {
  Admin,
  Manager,
  Reception,
  Cleaning,
  Bar
}

class Auth {

  static UserGroup currentUserRole = UserGroup.Admin; //Debug Role TODO : Remove
  static UserGroup getUserRole() {
    return currentUserRole;
  }

  static Future<User> getCurrentUser() {
    return UsersService.getUser(6);   //TODO : Change to get current user
  }

  static Future<bool> checkPassword(String email, String password) async {
    var url = Uri.parse('$_baseUrl/auth/check_password');
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

}

