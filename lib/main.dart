//import 'dart:html';
import 'package:flutter/material.dart';
import 'drawer_menu.dart';
import 'arrivals_departures_screen.dart';
import 'guests_list.dart';
import 'menu_view.dart';

UserGroup userGroup = UserGroup.Admin; //Debug Role

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
            ...getDrawerItems(userGroup, context), //Generate items for User
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