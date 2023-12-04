import 'db_helper.dart';
import 'dbObjects.dart';
import 'drawer_menu.dart';
import 'main.dart';

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
}

