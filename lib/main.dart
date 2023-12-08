//import 'dart:html';
import 'package:capstone_pms/billing_view.dart';
import 'package:flutter/material.dart';
import 'cleaning_view.dart';
import 'drawer_menu.dart';
import 'arrivals_departures_view.dart';
import 'guests_list.dart';
import 'menu_view.dart';
import 'authentication.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotel PMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      routes: {
        '/arrivals_departures': (context) => ArrivalsDeparturesScreen(), //Add route for Arrivals/Departures
        '/guests_list': (context) => GuestsListView(), // Guests list view route
        '/menu_view': (context) => MenuView(), // Menu view route
        '/billing_view': (context) => BillingView(), // Billing view route
        '/cleaning_view': (context) => CleaningView(), // Cleaning view route
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