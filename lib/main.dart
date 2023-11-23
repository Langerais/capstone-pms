//import 'dart:html';

import 'package:flutter/material.dart';
import 'drawer_menu.dart';

UserGroup currentUserGroup = UserGroup.Admin; //Debug Role

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
            ...getDrawerItems(currentUserGroup), //Generate items for User
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