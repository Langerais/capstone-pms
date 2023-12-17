import 'package:flutter/material.dart';
import 'authentication.dart';


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

@override
Size get preferredSize => Size.fromHeight(kToolbarHeight);  // Required for PreferredSizeWidget

List<Widget> getDrawerItems(UserGroup userGroup, BuildContext context) {

  final colorDone = Colors.green;
  final colorWIP = Colors.blue;


  List<Widget> drawerItems = [
    DrawerHeader(
      child: Text('Menu', style: TextStyle(color: Colors.white, fontSize: 25)),
      decoration: BoxDecoration(
        color: Colors.blue,
      ),
    ),
  ];

  // Helper function to create a ListTile wrapped in an InkWell
  Widget createDrawerItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
      ),
      splashColor: Colors.blueAccent, // Color for the ripple effect
    );
  }

  /////////////////////// Common menu items Top /////////////////////////////////////////////
  // Home menu item
  drawerItems.add(
    createDrawerItem(   //TODO: Splash color to all menu items ???
      icon: Icons.home,
      title: 'Home / TBD',
      onTap: () {
        // Navigate to Home
        //Navigator.pop(context); // Close the drawer
        // Add navigation logic here, e.g., Navigator.push(...)
      },
    ),
  );

  // Notifications menu item
  drawerItems.add(
    Container(
      color: colorWIP, // Change this to your desired color
      child: ListTile(
        leading: Icon(Icons.home),
        title: Text('Notifications / WIP'),
        onTap: () {
          Navigator.pushNamed(context, '/notifications_view'); // Navigate to Notifications
        },
      ),
    ),
  );

  /////////////////////// Bar-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Bar || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager){
    drawerItems.add(
      Container(
        color: colorDone, // Change this to your desired color
        child: ListTile(
          leading: Icon(Icons.home),
          title: Text('Restoraurant Menu'),
          onTap: () {
            Navigator.pushNamed(context, '/menu_view'); // Navigate to Menu
          },
        ),
      ),
    );

    drawerItems.add(
      Container(
        color: colorDone, // Change this to your desired color
        child: ListTile(
          leading: Icon(Icons.monetization_on),
          title: const Text('Restaurant Payments'),
          onTap: () {
            Navigator.pushNamed(context, '/billing_view'); // Navigate to Restaurant Billing
          },
        ),
      ),
    );
  }

  /////////////////////// Cleaning-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Cleaning || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager) {
    drawerItems.add(
        Container(
          color: colorDone, // Change this to your desired color
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Cleaning Schedule'),
            onTap: () {
              Navigator.pushNamed(context, '/cleaning_view'); // Navigate to Cleaning Schedule Management
            },
          ),
        ),
    );
  }

  /////////////////////// Reception-specific menu items /////////////////////////////////////////////
  if (userGroup == UserGroup.Reception || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager) {

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.meeting_room),
        title: Text('Arrivals / Departures'),
        tileColor: colorDone,
        onTap: () {
          Navigator.pushNamed(context, '/arrivals_departures');
          // Navigate to Arrivals / Departures
        },
      ),
    );

    drawerItems.add(
      ListTile(
        leading: Icon(Icons.swap_vert),
        title: Text('Check In/Out'),  // TODO: Move to Arrivals / Departures
        onTap: () {
          // Navigate to Check-in
          Navigator.pop(context);
        },
      ),
    );


    drawerItems.add(
      ListTile(
        leading: Icon(Icons.people),
        tileColor: colorDone,
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
      Container(
        color: colorDone, // Change this to your desired color
        child: ListTile(
          leading: Icon(Icons.history),
          title: Text('Logs'),
          onTap: () {
            Navigator.pushNamed(context, '/log_view'); // Navigate to Logs
          },
        ),
      ),
    );

    drawerItems.add(
      Container(
        color: colorWIP, // Change this to your desired color
        child: ListTile(
          leading: Icon(Icons.people),
          title: Text('User Management / WIP'),
          onTap: () {
            Navigator.pushNamed(context, '/user_management_view'); // Navigate to User Management
          },
        ),
      ),
    );
  }

  /////////////////// Admin-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Admin) {
    // Menu items for Admin




    // Add more menu items as needed
  }



    ////////////////// Common menu items Bottom /////////////////////////////////////////////

    drawerItems.add(
      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings / TBD'),
        onTap: () {
          // Navigate to Settings
        },
      ),
    );

  drawerItems.add(
    Container(
      color: colorDone, // Change this to your desired color
      child: ListTile(
        leading: Icon(Icons.person),
        title: Text('Profile'),
        onTap: () {
          Navigator.pushNamed(context, '/profile_view'); // Navigate to Profile
        },
      ),
    ),
  );

  drawerItems.add(
    ListTile(
      leading: Icon(Icons.logout),
      title: Text('Logout / TBD'),
      onTap: () {
        // Navigate to Logout
      },
    ),
  );




  return drawerItems;
}