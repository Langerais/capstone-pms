import 'dart:async';
import 'package:capstone_pms/billing_view.dart';
import 'package:capstone_pms/profile_view.dart';
import 'package:capstone_pms/user_management_view.dart';
import 'package:flutter/material.dart';
import 'package:capstone_pms/authentication.dart';
import 'cleaning_view.dart';
import 'drawer_menu.dart';
import 'arrivals_departures_view.dart';
import 'guests_list.dart';
import 'log_view.dart';
import 'login_view.dart';
import 'menu_view.dart';
import 'notifications_view.dart';
import 'package:timezone/data/latest.dart' as tz;



void main() {
  tz.initializeTimeZones();
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget? _initialScreen;
  Timer? _tokenExpirationCheckTimer;

  @override
  void initState() {
    super.initState();
    _determineInitialScreen();
    startRefreshTimer();
  }

  @override
  void dispose() {
    cancelRefreshTimer();
    super.dispose();
  }

  void startRefreshTimer() {
    cancelRefreshTimer();
    if (_tokenExpirationCheckTimer == null || !_tokenExpirationCheckTimer!.isActive) {
      const refreshInterval = Duration(seconds: 60); // Interval after which to check token expiration
      _tokenExpirationCheckTimer = Timer.periodic(refreshInterval, (Timer t) => Auth.checkTokenExpiration(context));
    }
  }

  void cancelRefreshTimer() {
    _tokenExpirationCheckTimer?.cancel();
    _tokenExpirationCheckTimer = null;
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
            _initialScreen = const NotificationsView(); // Default home page
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

    return MaterialApp(
      title: 'Hotel PMS',
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
        future: Auth.getUserRole(),  // Get the current user's role
        builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting, show a progress indicator
            return const Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            // If there's an error, show an error message
            return Drawer(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            // Once data is available, build the drawer
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...getDrawerItems(snapshot.data!, context), // Generate items for User
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