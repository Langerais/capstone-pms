import 'package:flutter/material.dart';

enum UserGroup {
  Admin,
  Manager,
  Reception,
  Cleaning,
  Bar
}


List<Widget> getDrawerItems(UserGroup userGroup) {
  List<Widget> drawerItems = [
    DrawerHeader(
      child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 25)),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
    ),
  ];

  // Common menu item for all users
  drawerItems.add(
    ListTile(
      leading: Icon(Icons.home),
      title: Text('Home'),
      onTap: () {
        // Navigate to Home
      },
    ),
  );

  if (userGroup == UserGroup.Bar || userGroup == UserGroup.Admin){
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.emoji_food_beverage),
        title: Text('Menu'),
        onTap: () {
          // Navigate to Room Management
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.monetization_on),
        title: Text('Bar Bill'),
        onTap: () {
          // Navigate to Room Management
        },
      ),
    );
  }

  if (userGroup == UserGroup.Cleaning || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager) {
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.calendar_month),
        title: Text('Cleaning Schedule'),
        onTap: () {
          // Navigate to Cleaning Schedule
        },
      ),
    );
  }


  if (userGroup == UserGroup.Admin) {
    // Menu items for Staff and Admin
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.meeting_room),
        title: Text('Room Management'),
        onTap: () {
          // Navigate to Room Management
        },
      ),
    );
    // Add more menu items as needed
  }

  if (userGroup == UserGroup.Admin) {
    // Admin-specific menu items
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.settings),
        title: Text('Settings'),
        onTap: () {
          // Navigate to Settings
        },
      ),
    );
  }

  if (userGroup == UserGroup.Admin) {
    // Admin-specific menu items
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.account_box),
        title: Text('Profile'),
        onTap: () {
          // Navigate to Account
        },
      ),
    );
  }

  return drawerItems;
}