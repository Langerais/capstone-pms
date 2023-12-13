import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'authentication.dart';
import 'dbObjects.dart';
import 'drawer_menu.dart';

class NotificationsView extends StatefulWidget {
  final UserGroup userGroup;

  NotificationsView({required this.userGroup});

  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  fetchNotifications() async {
    // Call your backend endpoint to fetch notifications
    var response = await http.get(Uri.parse('your_backend_endpoint'));
    if (response.statusCode == 200) {
      setState(() {
        notifications = json.decode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),

      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
          ],// Your drawer items
        ),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          var notification = notifications[index];
          return ListTile(
            title: Text(notification['title']),
            subtitle: Text(notification['body']),
          );
        },
      ),
    );
  }
}
