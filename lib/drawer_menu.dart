import 'package:flutter/material.dart';

enum UserGroup {
  Admin,
  Manager,
  Reception,
  Cleaning,
  Bar
}

class CustomAppBar extends StatelessWidget {
  final UserGroup userGroup;

  CustomAppBar({required this.userGroup});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Hotel PMS'),
      actions: [
        IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Open the drawer
            Scaffold.of(context).openDrawer();
          },
        ),
      ],
    );
  }
}

List<Widget> getDrawerItems(UserGroup userGroup, BuildContext context) {
  List<Widget> drawerItems = [
    DrawerHeader(
      child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 25)),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
    ),
  ];

  /////////////////////// Common menu items Top /////////////////////////////////////////////
  // Home menu item
  drawerItems.add(
    ListTile(
      leading: Icon(Icons.home),
      title: Text('Home'),
      onTap: () {
        // Navigate to Home
      },
    ),
  );

  // Notifications menu item
  drawerItems.add(
    ListTile(
      leading: Icon(Icons.notifications),
      title: Text('Notifications'),
      onTap: () {
        // Navigate to Notifications
      },
    ),
  );

  /////////////////////// Bar-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Bar || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager){
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

  /////////////////////// Cleaning-specific menu items /////////////////////////////////////////////

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

  /////////////////////// Reception-specific menu items /////////////////////////////////////////////
  if (userGroup == UserGroup.Reception || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager) {

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.calendar_today),
        title: Text('Arrivals / Departures'),
        onTap: () {
          Navigator.pushNamed(context, '/arrivals_departures');
          // Navigate to Arrivals / Departures
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.arrow_circle_down),
        title: Text('Check-in'),
        onTap: () {
          // Navigate to Check-in
          Navigator.pop(context);
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.arrow_circle_up),
        title: Text('Check-out'),
        onTap: () {
          // Navigate to Check-out
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.people),
        title: Text('Guests'),
        onTap: () {
          Navigator.pushNamed(context, '/guests_list'); // Navigate to GuestsListView
        },
      ),
    );
  }

  //////////////////// Manager-specific menu items ///////////////////////////////////////////

  if (userGroup == UserGroup.Manager || userGroup == UserGroup.Admin) {
    // Menu items for Manager and Admin
    drawerItems.add(
      ListTile(
        leading: Icon(Icons.meeting_room),
        title: Text('Cleaning Schedule Management'),
        onTap: () {
          // Navigate to Cleaning Schedule Management
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.notification_add),
        title: Text('Notification Management'),
        onTap: () {
          // Navigate to Notification Management
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.people),
        title: Text('User Management'),
        onTap: () {
          // Navigate to User Management
        },
      ),
    );
    // Add more menu items as needed
  }

  /////////////////// Admin-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Admin) {
    // Menu items for Admin




    // Add more menu items as needed
  }



    ////////////////// Common menu items Bottom /////////////////////////////////////////////

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.settings),
        title: Text('Settings'),
        onTap: () {
          // Navigate to Settings
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.account_box),
        title: Text('Profile'),
        onTap: () {
          // Navigate to Account
        },
      ),
    );

  drawerItems.add(
    ListTile(
      leading: Icon(Icons.logout),
      title: Text('Logout'),
      onTap: () {
        // Navigate to Logout
      },
    ),
  );




  return drawerItems;
}