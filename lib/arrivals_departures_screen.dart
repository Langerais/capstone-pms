import 'package:capstone_pms/drawer_menu.dart';
import 'package:capstone_pms/main.dart';
import 'package:flutter/material.dart';
import 'test_db.dart';
import 'db_helper.dart';



class ArrivalsDeparturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arrivals/Departures'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(userGroup, context), //Generate items for User
          ],
        ),
      ),
      body: ArrivalsDeparturesTable(),

    );
  }
}

class ArrivalsDeparturesTable extends StatefulWidget {
  @override
  _ArrivalsDeparturesTableState createState() => _ArrivalsDeparturesTableState();
}

class _ArrivalsDeparturesTableState extends State<ArrivalsDeparturesTable> {
  late DateTime currentWeekStart;

  @override
  void initState() {
    super.initState();
    // Initialize current week start date
    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          // Forward/Backward buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
                  });
                },
              ),
              Text('Week of ${formatDate(currentWeekStart)}'),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    currentWeekStart = currentWeekStart.add(Duration(days: 7));
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                  });
                },
                child: Text('TODAY'),
              ),
            ],
          ),


          // Header row with dates
          Container(
            color: Colors.grey[300],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.grey[500],
                        child: Center(child: Text('Room')),
                      ),
                    ),
                    for (int i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          color: currentWeekStart.add(Duration(days: i)).day == DateTime.now().day &&
                              currentWeekStart.add(Duration(days: i)).month == DateTime.now().month
                              ? Colors.grey[500] // Darker grey for today's date
                              : Colors.grey[300],
                          child: Center(child: Text(formatDate(currentWeekStart.add(Duration(days: i))))),
                        ),
                      ),
                  ],
                ),
                // Thin row under the date with day names
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.grey[500],
                        child: Center(child: Text('Day')),
                      ),
                    ),
                    for (int i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          color: currentWeekStart.add(Duration(days: i)).day == DateTime.now().day &&
                              currentWeekStart.add(Duration(days: i)).month == DateTime.now().month
                              ? Colors.grey[500] // Darker grey for today's date
                              : Colors.grey[300],
                          child: Center(child: Text(formatDayName(currentWeekStart.add(Duration(days: i))))),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Scrollable table
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(), // Disable ListView scrolling
            itemCount: DBHelper.getRooms().length,
            itemBuilder: (BuildContext context, int index) {
              Room room = DBHelper.getRooms()[index];

              return Container(
                //color: getCellColor(room.id, currentWeekStart),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        color: Colors.grey[500],
                        child: Center(child: Text(room.name)),
                      ),
                    ),
                    for (int i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          color: getCellColor(room.id, currentWeekStart.add(Duration(days: i))),
                          child: Center(child: Text(getReservationInfo(room.id, currentWeekStart.add(Duration(days: i))))),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year % 100}';
  }

  String formatDayName(DateTime date) {
    List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek[date.weekday - 1];
  }


  Color? getCellColor(int roomId, DateTime date) {
    DateTime yesterday = date.subtract(Duration(days: 1));
    DateTime tomorrow = date.add(Duration(days: 1));

    List<Reservation> yesterdayReservations = DBHelper.getReservations()
        .where((res) => res.roomId == roomId && yesterday.isAfter(res.startDate) && yesterday.isBefore(res.endDate))
        .toList();

    List<Reservation> todayReservations = DBHelper.getReservations()
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    List<Reservation> tomorrowReservations = DBHelper.getReservations()
        .where((res) => res.roomId == roomId && tomorrow.isAfter(res.startDate) && tomorrow.isBefore(res.endDate))
        .toList();


    if (todayReservations.isNotEmpty) {
      // Check for changes in reservations (check-in, check-out, stay, or change of guest)
      if (yesterdayReservations.isEmpty) {
        return Colors.lightGreenAccent; // Guest is arriving today, use light green
      } else if (tomorrowReservations.isNotEmpty && todayReservations[0].id != tomorrowReservations[0].id) {
        return Colors.greenAccent; // Guest is changing today, use green
      } else if (tomorrowReservations.isEmpty) {
        return Colors.lightGreenAccent; // Guest is leaving today, use light green
      } else {
        return Colors.lightGreen[200]; // Guest is staying, use light green
      }
    }

    return Colors.white; // Room available

  }

  String getGuestFullName(int guestId) {
    Guest guest = DBHelper.getGuests().firstWhere((g) => g.id == guestId);
    return guest.lastName;
  }

  String getReservationInfo(int roomId, DateTime date) {
    List<Reservation> roomReservations = DBHelper.getReservations()
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    if (roomReservations.isNotEmpty) {
      Reservation reservation = roomReservations[0];

      if (reservation.startDate == date) {
        // Guest is arriving today
        String leavingGuest = getLeavingGuest(roomId, date);
        String arrivingGuest = getGuestFullName(reservation.guestId);

        if (leavingGuest.isNotEmpty) {
          return '$leavingGuest / $arrivingGuest';
        } else {
          return arrivingGuest;
        }
      } else {
        // Guest is staying or leaving today
        String leavingGuest = getLeavingGuest(roomId, date);
        return leavingGuest.isNotEmpty ? leavingGuest : getGuestFullName(reservation.guestId);
      }
    } else {
      return 'FREE'; // Room available
    }
  }

  String getLeavingGuest(int roomId, DateTime date) {
    List<Reservation> leavingReservations = DBHelper.getReservations()
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    if (leavingReservations.isNotEmpty) {
      Reservation leavingReservation = leavingReservations[0];
      DateTime nextDay = date.add(Duration(days: 1));

      List<Reservation> nextDayReservations = DBHelper.getReservations()
          .where((res) => res.roomId == roomId && nextDay.isAfter(res.startDate) && nextDay.isBefore(res.endDate))
          .toList();

      if (nextDayReservations.isNotEmpty && leavingReservation.id != nextDayReservations[0].id) {
        // Different reservation IDs on adjacent days, both guests are involved
        return '${getGuestFullName(leavingReservation.guestId)} / ${getGuestFullName(nextDayReservations[0].guestId)}';
      } else {
        // Same reservation ID on adjacent days, returning only the leaving guest
        return getGuestFullName(leavingReservation.guestId);
      }
    } else {
      return ''; // No leaving guest
    }
  }
}