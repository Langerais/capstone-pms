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
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleaning Schedule'),
      ),
      body: Column(
        children: [
          _buildDatePicker(),
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
        ElevatedButton(
          onPressed: _scheduleCleaning,
          child: Text('Schedule Cleaning'),
        ),
      ],
    );
  }

  void _scheduleCleaning() async {
    try {
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
      firstDate: DateTime.now().subtract(Duration(days: 3)),
      lastDate: DateTime.now().add(Duration(days: 3)),
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


