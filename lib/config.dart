// File: lib/config.dart
class AppConfig {
  static const BASE_URL = 'http://16.16.140.209:8000';
  static const int REFRESH_TIMER = 300;  // Refresh db every X seconds
  static const int TOKEN_CHECK_TIMER = 300;  // Check token expiration every X seconds
  static const String AES_KEY = 'c77e7aff47294b8eea6e2dee85c58ac2750d1ef22224af7673ff1d0d2793aa57'; //TODO: Find a better way to store this
}