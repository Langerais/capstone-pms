import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dbObjects.dart';
import 'package:intl/intl.dart';

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

  void _fetchInitialData() async {
    rooms = await RoomService.getRooms();
    cleaningActions = await CleaningService.getCleaningActions();
    _fetchReservations();
  }

  void _fetchReservations() async {
    // Fetch all rooms and sort them by name.
    rooms = await RoomService.getRooms();
    rooms.sort((a, b) => a.name.compareTo(b.name));

    // No need to filter by active reservations as we are showing all rooms.
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
              _fetchReservations();
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
    int days = int.tryParse(daysController.text) ?? 0;
    try {
      await CleaningService.scheduleCleaning(selectedDate, days);
    } catch (e) {
      print('Failed to schedule cleaning: $e');
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
        _fetchReservations();
      });
    }
  }

  Widget _buildCleaningScheduleTable() {
    return FutureBuilder<List<DataRow>>(
      future: _buildRows(),  // Call to the async function that builds rows
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display loading indicator while waiting for data
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Display error if something went wrong
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Display message if there's no data
          return Text('No cleaning schedules available.');
        }

        // Build DataTable with the fetched rows
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _buildColumns(),
            rows: snapshot.data!,  // Use the data from the snapshot
          ),
        );
      },
    );
  }


  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [
      DataColumn(label: Text('Room')),
    ];

    columns.addAll(
      cleaningActions.map(
            (action) => DataColumn(label: Text(action.name)),
      ),
    );

    return columns;
  }

  Future<List<DataRow>> _buildRows() async {
    List<DataRow> rows = [];
    final double cellWidth = 50; // Define a fixed width for cells
    //final double cellHeight = 50; // Define a fixed height for cells

    for (var room in rooms) {
      List<CleaningSchedule> roomSchedules = await CleaningService.getRoomCleaningSchedule(room.id, selectedDate, selectedDate);

      List<DataCell> cells = [
        DataCell(Container(width: cellWidth, child: Text(room.name))),
      ];

      cells.addAll(
        cleaningActions.map((action) {
          // Find the schedule for this action
          var schedule = roomSchedules.firstWhere(
                (s) => s.actionId == action.id,
            orElse: () => CleaningSchedule(id: 0, roomId: room.id, actionId: action.id, scheduledDate: selectedDate, status: ''),
          );

          Color cellColor = Colors.grey; // Default color
          if (schedule.status == 'pending') {
            cellColor = Colors.red;
          } else if (schedule.status == 'completed') {
            cellColor = Colors.green;
          }

          return DataCell(
            Container(
              width: cellWidth,
              height: cellWidth*0.9,
              padding: EdgeInsets.all(10),
              //height: cellHeight,
              color: cellColor,
              child: Text(''), // Placeholder text if needed
            ),
            onTap: () {
              if(schedule.id != 0) {
                // Mark cleaning as completed
                //CleaningService.markCleaningAsCompleted(schedule.id);
                print(room.name + ' ' + action.name + ' ' + schedule.id.toString() + ' ' + schedule.status);
              } else {
                print(room.name + ' ' + action.name + ' ' + schedule.id.toString() + ' Not scheduled');
              }

              //print(schedule.id);
            },
          );
        }),
      );

      rows.add(DataRow(cells: cells));
    }

    return rows;
  }


}
