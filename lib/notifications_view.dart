import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'authentication.dart';
import 'db_helper.dart';
import 'drawer_menu.dart';
import 'models.dart';
import 'package:http/http.dart' as http;

// TODO: Refresh view every minute

class NotificationsView extends StatefulWidget {
  const NotificationsView({Key? key}) : super(key: key);

  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<AppNotification> notifications = [];
  String selectedNotificationTitle = 'AllNotifications';
  List<String> notificationTitles = ['AllNotifications'];
  List<String> availableRoles = []; // All available roles
  Map<String, bool> selectedRoles = {}; // Selected roles
  int selectedPriority = 1;
  UserGroup userRole = UserGroup.None;

  Duration lifetime = Duration();
  TextEditingController daysController = TextEditingController();
  TextEditingController hoursController = TextEditingController();
  TextEditingController minutesController = TextEditingController();

  int days = 0, hours = 0, minutes = 0; // Local state for the picker

  @override
  void initState() {
    super.initState();
    print('NotificationsView initState');
    _fetchNotifications();
    _fetchDepartments();
  }

  _fetchDepartments() async {
    try {
      var departments = await UsersService.getAllDepartments();
      setState(() {
        availableRoles = departments.map((department) => department.departmentName).toList();
        // Update selectedRoles based on the fetched departments
        selectedRoles = {
          for (var role in availableRoles) role: selectedRoles[role] ?? false
        };
      });
    } catch (e) {
      // Handle errors appropriately
    }
  }

  _fetchNotifications() async {
    try {
      userRole = await Auth.getUserRole();
      String roleString = userRole.toString().split('.').last;

      var notificationsList = await AppNotificationsService.getAppNotificationsByDepartment(
          roleString
      );

      // Sort notifications by priority and then by time to live
      notificationsList.sort((a, b) {
        // Compare by priority first
        int priorityComparison = a.priority.compareTo(b.priority);
        if (priorityComparison != 0) {
          return priorityComparison;
        }

        // If priorities are equal, compare by expiry date (time to live)
        return a.expiryDate.compareTo(b.expiryDate);
      });

      setState(() {
        notifications = notificationsList;
        notificationTitles = ['AllNotifications', ...notificationsList.map((n) => n.title).toSet().toList()];
      });

    } catch (e) {
      // Handle network error
    }
  }


  List<AppNotification> get filteredNotifications {
    if (selectedNotificationTitle == 'AllNotifications') {
      return notifications;
    } else {
      return notifications.where((n) => n.title == selectedNotificationTitle).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Row(
          children: [
            const Text('Notifications'),
            const SizedBox(width: 20),
            DropdownButton<String>(
              value: selectedNotificationTitle,
              onChanged: (String? newValue) {
                setState(() {
                  selectedNotificationTitle = newValue!;
                });
              },
              items: notificationTitles.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),

        actions: <Widget>[

          if(userRole == UserGroup.Admin || userRole == UserGroup.Manager)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showAddNotificationDialog();
              },
            ),
        ],
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
      body: ListView.builder(
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];

          bool isAlert = notification.title.startsWith('ALERT') || notification.title.startsWith('UNPAID');
          bool isAttention = notification.title.startsWith('ATTENTION') || notification.title.startsWith('Expected Arrival') || notification.title.startsWith('REQUIRED');
          bool isReminder = notification.title.startsWith('Reminder:') || notification.title.startsWith('Expected Departure');

          return ListTile(
            title: Text(
              notification.title,
              style: TextStyle(
                color:
                isAlert ? Colors.red :
                (isAttention ? Colors.orange :
                (isReminder ? Colors.green :
                Colors.black)),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text("${notification.message} - Expires: ${DateFormat('yyyy-MM-dd HH:mm').format(notification.expiryDate)}")
          );
        },
      ),
    );
  }


  void _showAddNotificationDialog() {
    String selectedPrefix = ' ';
    String notificationTitle = '';
    String notificationMessage = '';


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Create Custom Notification'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    // Prefix Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        const Text('Prefix: '),
                        SizedBox(width: 20),
                        DropdownButton<String>(
                          value: selectedPrefix,
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              selectedPrefix = newValue!;
                            });
                          },
                          items: <String>[' ', 'Reminder: ', 'ALERT: ']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Title Input
                    TextField(
                      onChanged: (value) => notificationTitle = value,
                      decoration: const InputDecoration(labelText: 'Notification Title'),
                    ),
                    // Message Input
                    TextField(
                      onChanged: (value) => notificationMessage = value,
                      decoration: const InputDecoration(labelText: 'Notification Message'),
                    ),
                    SizedBox(height: 15),
                    // User Role Picker
                    ElevatedButton(
                      child: const Text('Select Roles'),
                      onPressed: () => _showRolePickerDialog(),
                    ),
                    // Priority Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    const Text('Priority: '),
                    DropdownButton<int>(
                      value: selectedPriority,
                      onChanged: (int? newValue) {
                        setDialogState(() {
                          selectedPriority = newValue!;
                        });
                      },
                      items: [1, 2, 3, 4, 5].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                    // Inline Lifetime Picker with Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildNumberAdjuster(
                          label: 'Days',
                          initialValue: days,
                          maxValue: 30,
                          setDialogState: setDialogState,
                          updateValue: (change) {
                            days = (days + change + 30) % 30;
                            setDialogState(() {});
                          },
                        ),
                        _buildNumberAdjuster(
                          label: 'Hours',
                          initialValue: hours,
                          maxValue: 24,
                          setDialogState: setDialogState,
                          updateValue: (change) {
                            hours = (hours + change + 24) % 24;
                            setDialogState(() {});
                          },
                        ),
                        _buildNumberAdjuster(
                          label: 'Minutes',
                          initialValue: minutes,
                          maxValue: 60,
                          setDialogState: setDialogState,
                          updateValue: (change) {
                            minutes = (minutes + change * 5 + 60) % 60;
                            setDialogState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    // Calculate the expiry date
                    DateTime expiryDate = DateTime.now().add(lifetime);

                    // Invert priority
                    int invertedPriority = -selectedPriority;

                    // Iterate over selected roles and create notifications
                    selectedRoles.forEach((role, isSelected) async {
                      if (isSelected) {
                        // Create a notification object for each selected role
                        AppNotification newNotification = AppNotification(
                          id: 0, // Assuming ID is assigned by the backend
                          title: selectedPrefix + notificationTitle,
                          message: notificationMessage,
                          department: role, // Use the role as the department
                          priority: invertedPriority,
                          expiryDate: expiryDate,
                        );

                        // Call the method to save the notification
                        await AppNotificationsService.createNotification(newNotification);
                      }
                    });

                    setState(() {
                      lifetime = Duration(days: days, hours: hours, minutes: minutes);
                    });
                    Navigator.of(context).pop();
                  },
                ),

              ],
            );
          },
        );
      },
    );
  }


  Widget _buildNumberAdjuster({
    required String label,
    required int initialValue,
    required int maxValue,
    required StateSetter setDialogState,
    required Function(int) updateValue,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.arrow_upward, size: 20),
          onPressed: () => setDialogState(() => updateValue(1)),
        ),
        Text('$initialValue $label'),
        IconButton(
          icon: const Icon(Icons.arrow_downward, size: 20),
          onPressed: () => setDialogState(() => updateValue(-1)),
        ),
      ],
    );
  }

  void _updateSelectedRoles(String role, bool isSelected) {
    setState(() {
      selectedRoles[role] = isSelected;
    });
  }

  void _showRolePickerDialog() {
    Map<String, bool> localSelectedRoles = Map.from(selectedRoles);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Select User Roles'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: availableRoles.map((role) {
                    return CheckboxListTile(
                      value: localSelectedRoles[role],
                      title: Text(role),
                      onChanged: (bool? value) {
                        setDialogState(() {
                          localSelectedRoles[role] = value!;
                        });
                        _updateSelectedRoles(role, value!);
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                ElevatedButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
