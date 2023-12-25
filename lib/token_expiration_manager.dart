import 'dart:async';
import 'package:flutter/material.dart';
import 'login_view.dart';
import 'authentication.dart';
import 'config.dart';

class TokenExpirationManager {
  static Timer? _tokenExpirationCheckTimer;

  static Future<void> startRefreshTimer(BuildContext context) async {
    const refreshInterval = Duration(seconds: AppConfig.TOKEN_CHECK_TIMER);
    _tokenExpirationCheckTimer?.cancel(); // Cancel any existing timer

    // Set up the periodic timer
    _tokenExpirationCheckTimer = Timer.periodic(refreshInterval, (Timer t) async {
      bool tokenValid = await Auth.checkTokenExpiration();
      if (!tokenValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginView(expiredSessionMessage: "Session Expired")),
        );
      }
    });
  }

  static void stopRefreshTimer() {
    _tokenExpirationCheckTimer?.cancel();
    print('Timer stopped');
  }
}