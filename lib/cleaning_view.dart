import 'package:capstone_pms/authentication.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'models.dart';
import 'package:intl/intl.dart';

import 'drawer_menu.dart';

// TODO: Individual refresh for each task

/// A StatefulWidget for displaying and managing cleaning schedules.
class CleaningView extends StatefulWidget {
  const CleaningView({super.key});

  @override
  _CleaningScheduleViewState createState() => _CleaningScheduleViewState();
}

class _CleaningScheduleViewState extends State<CleaningView> {
  // Current selected date for scheduling.
  DateTime selectedDate = DateTime.now();

  // Lists to hold data fetched from the database.
  List<Reservation> reservations = [];
  List<Room> rooms = [];
  List<CleaningAction> cleaningActions = [];

  // Controller for the 'Enter days' TextField.
  TextEditingController daysController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Fetches rooms and cleaning actions from the server.
  void _fetchData() async {
    rooms = await RoomService.getRooms();
    rooms.sort((a, b) => a.name.compareTo(b.name));
    cleaningActions = await CleaningService.getCleaningActions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserGroup>(
      future: Auth.getUserRole(), // Get the current user's role
      builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting, show a progress indicator
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cleaning Schedule'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // If there's an error, show an error message
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cleaning Schedule'),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          // Once the user role is available, build the UI
          UserGroup userRole = snapshot.data!;

          /// Builds action buttons for the AppBar based on user role.
          List<Widget> buildAppBarActions() {
            List<Widget> actions = [];
            if (userRole == UserGroup.Admin || userRole == UserGroup.Manager) {
              actions.add(
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageCleaningActions()),
                    );
                  },
                ),
              );
            }
            return actions;
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Cleaning Schedule'),
              actions: buildAppBarActions(),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...getDrawerItems(userRole, context), // Generate items for User
                ],
              ),
            ),
            body: Column(
              children: [
                if (kDebugMode) _buildDatePicker(),
                Expanded(
                  child: _buildCleaningScheduleTable(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Builds a date picker widget for selecting cleaning dates.
  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _selectDate(context),
          child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
        ),
        IconButton(
          icon: const Icon(Icons.today),
          onPressed: () {
            setState(() {
              selectedDate = DateTime.now();
              _fetchData();
            });
          },
        ),
        const SizedBox(width: 10),
        if (kDebugMode)
          ElevatedButton(
            onPressed: _scheduleCleaning,
            child: const Text('Schedule Cleaning'),
          ),
      ],
    );
  }

  /// Schedules cleaning for the selected date.
  void _scheduleCleaning() async {
    try {
      // Prevent scheduling in the past outside of debug mode.
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime dateOnlySelected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      if (dateOnlySelected.isBefore(today)) {
        print("ERROR: Date is in the past");
        return;
      }
      await CleaningService.scheduleCleaning(selectedDate);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to schedule cleaning: $e');
      }
    }
  }

  @override
  void dispose() {
    daysController.dispose();
    super.dispose();
  }

  /// Selects a new date for cleaning scheduling.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _fetchData();
      });
    }
  }


  /// Builds a table displaying the cleaning schedule.
  Widget _buildCleaningScheduleTable() {
    return FutureBuilder<List<DataRow>>(
      future: _buildRows(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No cleaning schedules available.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 0,
                  columns: _buildColumns(),
                  rows: snapshot.data!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds the columns for the cleaning schedule table.
  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: Container(
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade100,
            border: const Border(
              right: BorderSide(width: 2.0, color: Colors.black),
              bottom: BorderSide(width: 1.0, color: Colors.black),
            ),
          ),
          padding: EdgeInsets.zero,
          alignment: Alignment.center,
          child: const Text('Room'),
        ),
      ),
      ...cleaningActions.map(
            (action) => DataColumn(
          label: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              border: const Border(
                right: BorderSide(width: 1.0, color: Colors.black),
                bottom: BorderSide(width: 1.0, color: Colors.black),
              ),
            ),
            padding: const EdgeInsets.all(0),
            alignment: Alignment.center,
            child: Text(action.name),
          ),
        ),
      ),
    ].map((DataColumn column) {
      return DataColumn(
        label: Expanded(
          child: Container(
            color: Colors.lightBlue.shade50,
            child: Center(child: column.label),
          ),
        ),
        onSort: column.onSort,
      );
    }).toList();
  }

  /// Builds the data rows for the cleaning schedule table.
  Future<List<DataRow>> _buildRows() async {
    List<DataRow> rows = [];

    for (var room in rooms) {
      List<CleaningSchedule> roomSchedules = await CleaningService.getRoomCleaningSchedule(room.id, selectedDate, selectedDate);

      List<DataCell> cells = [
        DataCell(
          Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.black12,
              border: Border(right: BorderSide(width: 2.0, color: Colors.black)),
            ),
            child: Text(room.name),
          ),
        ),
        ...cleaningActions.map((action) {
          var schedule = roomSchedules.firstWhere(
                (s) => s.actionId == action.id,
            orElse: () => CleaningSchedule(id: 0, roomId: room.id, actionId: action.id, scheduledDate: selectedDate, status: ''),
          );

          return DataCell(
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return GestureDetector(
                  onTap: () {
                    _toggleStatus(schedule, () {
                      setState(() {}); // Refresh the cell
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(width: 1.0, color: Colors.black)),
                    ),
                    child: Center(
                      child: schedule.status == 'pending'
                          ? const Icon(Icons.check_box_outline_blank, color: Colors.red)
                          : schedule.status == 'completed'
                          ? const Icon(Icons.check_box, color: Colors.green)
                          : const Icon(Icons.circle, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ];

      rows.add(DataRow(cells: cells));
    }

    return rows;
  }

  // Helper function to toggle the status of a cleaning schedule
  void _toggleStatus(CleaningSchedule schedule, Function refreshCell) async {
    String newStatus = schedule.status == 'pending' ? 'completed' : 'pending';
    print('Toggling status of schedule ${schedule.id} to $newStatus');
    try {
      await CleaningService.toggleCleaningTaskStatus(schedule.id, newStatus, DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
      schedule.status = newStatus; // Update the schedule's status
      refreshCell(); // Refresh the cell
    } catch (e) {
      if (kDebugMode) {
        print('Failed to toggle cleaning task status: $e');
      }
    }
  }
}


/// A StatelessWidget for displaying expanded header information.
class ExpandedHeader extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  /// Constructs an ExpandedHeader widget.
  ///
  /// `text`: The text to display in the header.
  /// `backgroundColor`: The background color of the header.
  const ExpandedHeader({super.key, required this.text, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(),
      ),
    );
  }
}


/// ManageCleaningActions is a StatefulWidget that allows users
/// to manage (create, edit, delete) cleaning actions in the app.
class ManageCleaningActions extends StatefulWidget {
  const ManageCleaningActions({super.key});

  @override
  _ManageCleaningActionsState createState() => _ManageCleaningActionsState();
}

class _ManageCleaningActionsState extends State<ManageCleaningActions> {
  // Lists to store the original and edited cleaning actions.
  List<CleaningAction> cleaningActions = [];
  List<CleaningAction> editedCleaningActions = [];

  // Maps to manage the TextEditingControllers for each cleaning action.
  Map<int, TextEditingController> nameControllers = {};
  Map<int, TextEditingController> frequencyControllers = {};

  // Flag to track if a save attempt has been made, for validation purposes.
  bool attemptedSave = false;

  @override
  void initState() {
    super.initState();
    fetchCleaningActions();
  }

  /// Fetches cleaning actions from the CleaningService and initializes controllers.
  void fetchCleaningActions() async {
    var actions = await CleaningService.getCleaningActions();
    setState(() {
      cleaningActions = actions;
      editedCleaningActions = List<CleaningAction>.from(actions);
      nameControllers = {
        for (var action in actions)
          action.id: TextEditingController(text: capitalize(action.name))
      };
      frequencyControllers = {
        for (var action in actions)
          action.id: TextEditingController(text: action.frequency.toString())
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cleaning Actions'),
        actions: <Widget>[
          // Button to add a new cleaning action.
          SizedBox(
            width: 60,
            height: 60,
            child: IconButton(
              icon: const Icon(Icons.add, size: 50),
              onPressed: () {
                // Adding a new cleaning action with default values.
                var newAction = CleaningAction(
                  id: -1, // Temporary ID for new action
                  name: 'New Task',
                  frequency: 1,
                );
                setState(() {
                  editedCleaningActions.add(newAction);
                  nameControllers[newAction.id] = TextEditingController(text: newAction.name);
                  frequencyControllers[newAction.id] = TextEditingController(text: newAction.frequency.toString());
                });
              },
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: editedCleaningActions.length,
        itemBuilder: (context, index) {
          var action = editedCleaningActions[index];
          return ListTile(
            // Text field for editing action name.
            title: TextFormField(
              controller: nameControllers[action.id],
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: (nameControllers[action.id]?.text.isEmpty ?? true) && attemptedSave ? 'Name cannot be empty' : null,
              ),
              onChanged: (value) {
                // Updating the action name as the user types.
                String capitalizedValue = capitalize(value);
                if (capitalizedValue != value) {
                  nameControllers[action.id]?.value = nameControllers[action.id]!.value.copyWith(
                    text: capitalizedValue,
                    selection: TextSelection.collapsed(offset: capitalizedValue.length),
                  );
                }
                updateAction(index, value, action.frequency);
              },
            ),
            // Text field for editing action frequency.
            subtitle: TextFormField(
              keyboardType: TextInputType.number,
              controller: frequencyControllers[action.id],
              decoration: InputDecoration(
                labelText: 'Frequency (Days)',
                errorText: validateFrequency(frequencyControllers[action.id]!.text),
              ),
              onChanged: (value) {
                // Updating the action frequency as the user types.
                int? frequency = value.isEmpty ? null : int.tryParse(value);
                updateAction(index, action.name, frequency ?? 0);
              },
            ),
            // Button to delete the cleaning action.
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                deleteAction(index);
              },
            ),
          );
        },
      ),
      // Floating action button to save changes.
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.save),
        onPressed: () {
          saveChanges();
        },
      ),
    );
  }

  /// Updates the properties of a specific action based on user input.
  void updateAction(int index, String newName, int newFrequencyDays) {
    var action = editedCleaningActions[index];
    action.name = capitalize(newName);
    action.frequency = newFrequencyDays;
    // Update the text in controllers after editing.
    nameControllers[action.id]?.text = newName;
    frequencyControllers[action.id]?.text = newFrequencyDays.toString();
  }

  /// Saves changes made to cleaning actions, either creating new ones
  /// or updating existing ones.
  void saveChanges() async {
    for (var action in editedCleaningActions) {
      setState(() {
        attemptedSave = true;
      });

      // Perform validation before saving.
      if (nameControllers[action.id]!.text.isEmpty || int.tryParse(frequencyControllers[action.id]!.text) == null || int.parse(frequencyControllers[action.id]!.text) <= 0) {
        // Show error message if validation fails.
        return;
      }

      // Handle creation of a new action.
      if (action.id == -1) {
        await CleaningService.createCleaningAction(action.name, action.frequency);
      } else {
        // Handle updating an existing action.
        await CleaningService.updateCleaningAction(action.id, action.name, action.frequency);
      }
    }
    // Refresh the actions list after saving.
    fetchCleaningActions();
  }

  /// Deletes a cleaning action from the list and the database.
  void deleteAction(int index) {
    var action = editedCleaningActions[index];
    if (action.id != -1) {
      CleaningService.deleteCleaningAction(action.id);
    }
    setState(() {
      editedCleaningActions.removeAt(index);
    });
  }

  @override
  void dispose() {
    // Dispose of controllers when the widget is disposed.
    nameControllers.forEach((key, controller) => controller.dispose());
    frequencyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  /// Validates the frequency field input.
  String? validateFrequency(String value) {
    // Validation logic for frequency input.
    if (attemptedSave) {
      if (value.isEmpty) return 'Frequency cannot be empty';
      int? frequency = int.tryParse(value);
      if (frequency == null || frequency <= 0) return 'Frequency must be a positive number';
    }
    return null;
  }

  /// Capitalizes the first letter of a string.
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}



