import 'package:flutter/material.dart';
import 'authentication.dart';
import 'login_view.dart';
import 'notifications_view.dart';


class CustomAppBar extends StatelessWidget {
  final UserGroup userGroup;

  CustomAppBar({required this.userGroup});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Hotel PMS'),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu),
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
Size get preferredSize => const Size.fromHeight(kToolbarHeight);  // Required for PreferredSizeWidget

List<Widget> getDrawerItems(UserGroup userGroup, BuildContext context) {

  List<Widget> drawerItems = [

    Container(
      height: 80,  // Set the desired height
      color: Colors.blue,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: const Text(
        'My Little PMS',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    ),
  ];

  /////////////////////// Common menu items Top /////////////////////////////////////////////


  // Notifications menu item
  drawerItems.add(
    Container(
      child: ListTile(
        leading: const Icon(Icons.notifications),
        title: const Text('Notifications'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsView()),
          ); // Navigate to Notifications
        },
      ),
    ),
  );

  /////////////////////// Bar-specific menu items /////////////////////////////////////////////

  if (userGroup == UserGroup.Bar || userGroup == UserGroup.Admin || userGroup == UserGroup.Manager){
    drawerItems.add(
      Container(
        child: ListTile(
          leading: const Icon(Icons.restaurant),
          title: const Text('Restaurant Menu'),
          onTap: () {
            Navigator.pushNamed(context, '/menu_view'); // Navigate to Menu
          },
        ),
      ),
    );

    drawerItems.add(
      Container(
        child: ListTile(
          leading: const Icon(Icons.monetization_on),
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
        leading: const Icon(Icons.meeting_room),
        title: const Text('Arrivals / Departures'),
        onTap: () {
          Navigator.pushNamed(context, '/arrivals_departures');
          // Navigate to Arrivals / Departures
        },
      ),
    );


    drawerItems.add(
      ListTile(
        leading: const Icon(Icons.emoji_people_outlined),
        title: const Text('Guests'),
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
      Container(// Change this to your desired color
        child: ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Logs'),
          onTap: () {
            Navigator.pushNamed(context, '/log_view'); // Navigate to Logs
          },
        ),
      ),
    );

    drawerItems.add(
      Container(
        child: ListTile(
          leading: const Icon(Icons.people),
          title: const Text('User Management'),
          onTap: () {
            Navigator.pushNamed(context, '/user_management_view'); // Navigate to User Management
          },
        ),
      ),
    );
  }

  /////////////////// Admin-specific menu items /////////////////////////////////////////////

  ////////////////// Common menu items Bottom /////////////////////////////////////////////


  drawerItems.add(
    Container(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: const Text('Profile'),
        onTap: () {
          Navigator.pushNamed(context, '/profile_view'); // Navigate to Profile
        },
      ),
    ),
  );

  // Logout menu item
  drawerItems.add(
    ListTile(
      leading: const Icon(Icons.logout),
      title: const Text('Logout'),
      onTap: () async {
        // Clear the stored JWT token
        await CrossPlatformTokenStorage.clearToken();

        // Navigate to the Login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
              (Route<dynamic> route) => false, // Remove all routes below the LoginView
        );
      },
    ),
  );




  return drawerItems;
}