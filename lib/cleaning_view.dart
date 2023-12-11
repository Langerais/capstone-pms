import 'package:capstone_pms/authentication.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dbObjects.dart';
import 'package:intl/intl.dart';

// TODO: Individual refresh for each task

class CleaningView extends StatefulWidget {
  @override
  _CleaningScheduleViewState createState() => _CleaningScheduleViewState();
}

class _CleaningScheduleViewState extends State<CleaningView> {
  DateTime selectedDate = DateTime.now();
  List<Reservation> reservations = [];
  List<Room> rooms = [];
  List<CleaningAction> cleaningActions = [];
  TextEditingController daysController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() async {    // TODO: Do I need this?
    _fetchData();
  }

  void _fetchData() async {
    // Fetch all rooms and sort them by name.
    rooms = await RoomService.getRooms();
    rooms.sort((a, b) => a.name.compareTo(b.name));
    cleaningActions = await CleaningService.getCleaningActions();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    UserGroup userRole = Auth.getUserRole();

    List<Widget> _buildAppBarActions() {
      List<Widget> actions = [];
      if (userRole == UserGroup.Admin || userRole == UserGroup.Manager) {
        actions.add(
          IconButton(
            icon: Icon(Icons.settings), // Icon for managing cleaning actions
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
        title: Text('Cleaning Schedule'),
        actions: _buildAppBarActions(),
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


  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _selectDate(context),
          child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
        ),
        IconButton(
          icon: Icon(Icons.today),
          onPressed: () {
            setState(() {
              selectedDate = DateTime.now();
              _fetchData();
            });
          },
        ),
        SizedBox(width: 10),
        Flexible(
          child: TextField(
            controller: daysController,
            decoration: InputDecoration(hintText: 'Enter days'),
            keyboardType: TextInputType.number,
          ),
        ),
        if (kDebugMode)
          ElevatedButton(
            onPressed: _scheduleCleaning,
            child: Text('Schedule Cleaning'),
          ),
      ],
    );
  }

  void _scheduleCleaning() async {
    try {

      // Should not be able to schedule cleaning for a date in the past outside of debug mode
      if(!kDebugMode && selectedDate != DateTime.now()){
        print("ERROR: Date is not today");
        return;
      }

      await CleaningService.scheduleCleaning(selectedDate);

    } catch (e) {
      if (kDebugMode) { print('Failed to schedule cleaning: $e'); }
    }
  }

  @override
  void dispose() {
    daysController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 60)),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _fetchData();
      });
    }
  }

  Widget _buildCleaningScheduleTable() {
    return FutureBuilder<List<DataRow>>(
      future: _buildRows(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No cleaning schedules available.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 0,  // Adjust column spacing if needed
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


  List<DataColumn> _buildColumns() {

    return [
      DataColumn(
        label: Container(
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade100,
            border: Border(
              right: BorderSide(width: 2.0, color: Colors.black), // Right border
              bottom: BorderSide(width: 1.0, color: Colors.black), // Bottom border
            ),
          ),
          padding: EdgeInsets.zero, // Explicitly set padding to zero

          alignment: Alignment.center,
          child: Text('Room'),
        ),

      ),
      ...cleaningActions.map(
            (action) => DataColumn(
          label: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              border: Border(
                right: BorderSide(width: 1.0, color: Colors.black), // Right border
                bottom: BorderSide(width: 1.0, color: Colors.black), // Bottom border
              ),
            ),
            padding: EdgeInsets.all(0), // Set padding to zero

            alignment: Alignment.center,
            child: Text(action.name),
          ),
        ),
      ),
    ].map((DataColumn column) {
      return DataColumn(
        label: Expanded(
          child: Container(
            color: Colors.lightBlue.shade50, // Your desired background color
            child: Center(child: column.label),
          ),
        ),
        onSort: column.onSort,
      );
    }).toList();
  }



  Future<List<DataRow>> _buildRows() async {
    List<DataRow> rows = [];

    for (var room in rooms) {
      List<CleaningSchedule> roomSchedules = await CleaningService.getRoomCleaningSchedule(room.id, selectedDate, selectedDate);

      List<DataCell> cells = [
        DataCell(
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black12, // Your desired cell background color
              border: Border(right: BorderSide(width: 2.0, color: Colors.black)), // Right border
            ),
            child: Text(room.name),
          ),
        ),
      ];

      cells.addAll(
        cleaningActions.map((action) {
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
                      setState(() {}); // Local setState to refresh the cell
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(width: 1.0, color: Colors.black)), // Right border
                    ),
                    child: Center(
                      child: schedule.status == 'pending'
                          ? Icon(Icons.check_box_outline_blank, color: Colors.red)
                          : schedule.status == 'completed'
                          ? Icon(Icons.check_box, color: Colors.green)
                          : Icon(Icons.circle, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      );

      rows.add(DataRow(cells: cells));
    }

    return rows;
  }

  // Helper function to toggle the status of a cleaning schedule
  void _toggleStatus(CleaningSchedule schedule, Function refreshCell) async {
    String newStatus = schedule.status == 'pending' ? 'completed' : 'pending';
    try {
      await CleaningService.toggleCleaningTaskStatus(schedule.id, newStatus, DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()));
      schedule.status = newStatus; // Update the schedule's status
      refreshCell(); // Call the provided function to refresh the cell
    } catch (e) {
      print('Failed to toggle cleaning task status: $e');
    }
  }

}

class ExpandedHeader extends StatelessWidget {
  final String text;
  final Color backgroundColor;

  const ExpandedHeader({Key? key, required this.text, required this.backgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 8.0), // Adjust padding as needed
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          // Add text style as required
        ),
      ),
    );
  }
}

class ManageCleaningActions extends StatefulWidget {
  @override
  _ManageCleaningActionsState createState() => _ManageCleaningActionsState();
}

class _ManageCleaningActionsState extends State<ManageCleaningActions> {
  List<CleaningAction> cleaningActions = [];
  List<CleaningAction> editedCleaningActions = []; // A list to track edited actions
  Map<int, TextEditingController> nameControllers = {};
  Map<int, TextEditingController> frequencyControllers = {};

  bool attemptedSave = false;

  @override
  void initState() {
    super.initState();
    fetchCleaningActions();
  }

  void fetchCleaningActions() async {
    var actions = await CleaningService.getCleaningActions();
    setState(() {
      cleaningActions = actions;
      editedCleaningActions = List<CleaningAction>.from(actions); // Create a copy of the actions
      nameControllers = {
        for (var action in actions)
          action.id: TextEditingController(text: capitalize(action.name))
      };
      frequencyControllers = {
        for (var action in actions) action.id: TextEditingController(text: action.frequency.toString())
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Cleaning Actions'),
        actions: <Widget>[
          SizedBox(
            width: 60, // Width of the SizedBox
            height: 60, // Height of the SizedBox
            child: IconButton(
              icon: Icon(Icons.add, size: 50), // You can also increase the icon size
              onPressed: () {
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
            title: TextFormField(
              controller: nameControllers[action.id],
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: (nameControllers[action.id]?.text.isEmpty ?? true) && attemptedSave ? 'Name cannot be empty' : null,              ),
              onChanged: (value) {
                String capitalizedValue = capitalize(value);
                // To avoid cursor jumping, only update if the value has changed
                if (capitalizedValue != value) {
                  nameControllers[action.id]?.value = nameControllers[action.id]!.value.copyWith(
                    text: capitalizedValue,
                    selection: TextSelection.collapsed(offset: capitalizedValue.length),
                  );
                }
                updateAction(index, value ?? action.name, action.frequency);
              },
            ),
            subtitle: TextFormField(
              keyboardType: TextInputType.number,
              controller: frequencyControllers[action.id],
              decoration: InputDecoration(
                labelText: 'Frequency (Days)',
                errorText: validateFrequency(frequencyControllers[action.id]!.text),
              ),
              onChanged: (value) {
                int? frequency;
                if (value.isEmpty) {
                  frequency = null;
                } else {
                  frequency = int.tryParse(value);
                }
                print("New Frequency: ${frequency ?? 'null'} Value: $value");
                updateAction(index, action.name, frequency ?? 0);
              },
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                deleteAction(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.save),
        onPressed: () {
          saveChanges();
        },
      ),
    );
  }

  void updateAction(int index, String newName, int newFrequencyDays) {
    var action = editedCleaningActions[index];
    action.name = capitalize(newName);
    action.frequency = newFrequencyDays;
    nameControllers[action.id]?.text = newName;
    frequencyControllers[action.id]?.text = newFrequencyDays.toString();
  }

  void saveChanges() async {
    for (var action in editedCleaningActions) {

      setState(() {
        attemptedSave = true;
      });

      if (nameControllers[action.id]!.text.isEmpty || int.tryParse(frequencyControllers[action.id]!.text) == null || int.parse(frequencyControllers[action.id]!.text) <= 0) {
        // Show a toast or another form of error message
        // Do not proceed with saving
        return;
      }


      if (action.id == -1) {
        // This is a new action
        await CleaningService.createCleaningAction(action.name, action.frequency);
      } else {
        // Update existing action
        print("Updating action");
        //var acti = await CleaningService.getCleaningAction(action.id);
        //print(action.id.toString() + " " + action.name + " " + action.frequency.toString());
        await CleaningService.updateCleaningAction(action.id, action.name, action.frequency);
      }
    }
    // Fetch the latest actions from the server to update the UI
    fetchCleaningActions();
  }

  void deleteAction(int index) {
    var action = editedCleaningActions[index];
    if (action.id != -1) {
      // This is an existing action, delete from database
      CleaningService.deleteCleaningAction(action.id);
    }
    setState(() {
      editedCleaningActions.removeAt(index);
    });
  }

  @override
  void dispose() {
    nameControllers.forEach((key, controller) => controller.dispose());
    frequencyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }


  String? validateFrequency(String value) {
    if (attemptedSave) {
      if (value.isEmpty) return 'Frequency cannot be empty';
      int? frequency = int.tryParse(value);
      if (frequency == null || frequency <= 0) return 'Frequency must be a positive number';
    }
    return null;
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

}



