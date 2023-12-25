/*
Developer: Samuil Shintel 228487
Supervisor: Prof. Ioannis Vetsikas
Deree – The American College of Greece
Fall Semester 2023
*/

import 'dart:async';
import 'package:MyLittlePms/token_expiration_manager.dart';
import 'package:flutter/material.dart';
import 'package:MyLittlePms/authentication.dart'; // Import your Auth class from another file
import 'package:timezone/data/latest.dart' as tz;

import 'arrivals_departures_view.dart';
import 'billing_view.dart';
import 'cleaning_view.dart';
import 'config.dart';
import 'drawer_menu.dart';
import 'guests_list.dart';
import 'log_view.dart';
import 'login_view.dart';
import 'menu_view.dart';
import 'notifications_view.dart';
import 'profile_view.dart';
import 'user_management_view.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}

// Define a global key for your app's navigation
//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late BuildContext mainContext;
  Widget? _initialScreen;
  Timer? _tokenExpirationCheckTimer;
  final tokenExpirationManager = TokenExpirationManager();

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      TokenExpirationManager.startRefreshTimer(mainContext);
    });
  }

  @override
  void dispose() {
    TokenExpirationManager.stopRefreshTimer();
    super.dispose();
  }

  Future<void> startRefreshTimer(BuildContext context) async {
    const refreshInterval = Duration(seconds: AppConfig.TOKEN_CHECK_TIMER);
    _tokenExpirationCheckTimer?.cancel(); // Cancel any existing timer

    // Set up the periodic timer
    _tokenExpirationCheckTimer = Timer.periodic(refreshInterval, (Timer t) async {
      print('Checking token expiration...');
      bool tokenValid = await Auth.checkTokenExpiration();
      if (!tokenValid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginView(expiredSessionMessage: "Session Expired")),
        );
      }
    });
  }

  void _determineInitialScreen() async {
    String? token = await CrossPlatformTokenStorage.getToken();
    if (token != null) {
      // User is logged in, determine the home page based on user role
      UserGroup userRole = await Auth.getUserRole(); // Await the future result
      setState(() {
        switch (userRole) {
          case UserGroup.Admin:
          case UserGroup.Manager:
          case UserGroup.Reception:
            _initialScreen = ArrivalsDeparturesScreen();
            break;
          case UserGroup.Cleaning:
            _initialScreen = const CleaningView();
            break;
          case UserGroup.Bar:
            _initialScreen = MenuView();
            break;
          default:
            _initialScreen = UserProfileView(); // Default home page
        }
      });
    } else {
      // User is not logged in, show login screen
      setState(() {
        _initialScreen = LoginView();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    mainContext = context;
    return MaterialApp(
      title: 'Hotel PMS',
      //navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _initialScreen ?? CircularProgressIndicator(), // Show loading indicator while determining the initial screen
      routes: {
        '/arrivals_departures': (context) => ArrivalsDeparturesScreen(),
        '/guests_list': (context) => GuestsListView(),
        '/menu_view': (context) => MenuView(),
        '/billing_view': (context) => BillingView(),
        '/cleaning_view': (context) => CleaningView(),
        '/log_view': (context) => LogsView(),
        '/profile_view': (context) => UserProfileView(),
        '/user_management_view': (context) => UserManagementView(),
        '/notifications_view': (context) => const NotificationsView(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel PMS'),
      ),
      drawer: FutureBuilder<UserGroup>(
        future: Auth.getUserRole(),
        builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Drawer(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...getDrawerItems(snapshot.data!, context),
                ],
              ),
            );
          }
        },
      ),
      body: const Center(
        child: Text('Home Page', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
