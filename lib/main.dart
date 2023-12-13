//import 'dart:html';
import 'package:capstone_pms/billing_view.dart';
import 'package:flutter/material.dart';
import 'cleaning_view.dart';
import 'drawer_menu.dart';
import 'arrivals_departures_view.dart';
import 'guests_list.dart';
import 'menu_view.dart';
import 'authentication.dart';
import 'notifications_view.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    UserGroup userRole = Auth.getUserRole();

    Widget _homePage;

    switch (userRole) {
      case UserGroup.Admin:
        _homePage = ArrivalsDeparturesScreen();
        break;
      case UserGroup.Manager:
        _homePage = ArrivalsDeparturesScreen();
        break;
      case UserGroup.Reception:
        _homePage = ArrivalsDeparturesScreen();
        break;
      case UserGroup.Cleaning:
        _homePage = CleaningView();
        break;
      case UserGroup.Bar:
        _homePage = MenuView();
        break;
      default:
        _homePage = MyHomePage();
    }

    return MaterialApp(
      title: 'Hotel PMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _homePage,
      routes: {
        '/arrivals_departures': (context) => ArrivalsDeparturesScreen(),
        '/guests_list': (context) => GuestsListView(),
        '/menu_view': (context) => MenuView(),
        '/billing_view': (context) => BillingView(),
        '/cleaning_view': (context) => CleaningView(),
        '/notifications_view': (context) => NotificationsView(userGroup: userRole,),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
          ],
        ),
      ),
      body: const Center(
        child: Text('Home Page', style: TextStyle(fontSize: 24)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AI Chat
          print('AI Chat Button Pressed');
          // You might want to navigate to a new screen or open a dialog
        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
    );
  }
}