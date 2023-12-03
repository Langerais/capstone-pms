import 'package:capstone_pms/drawer_menu.dart';
import 'package:capstone_pms/main.dart';
import 'package:flutter/material.dart';
import 'dbObjects.dart';
import 'db_helper.dart';
import 'db_helper.dart' as DBHelper;
import 'package:collection/collection.dart';

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
  List<Reservation> reservations = [];
  List<Room> rooms = [];
  List<Guest> guests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    fetchData();
  }

  void fetchData() async {
    setState(() => isLoading = true);
    try {
      // Fetch reservations for the current week + 1 week before and after
      DateTime previousWeekStart = currentWeekStart.subtract(Duration(days: 7));
      DateTime nextWeekEnd = currentWeekStart.add(Duration(days: 14));
      reservations = await ReservationService.getReservationsByDateRange(previousWeekStart, nextWeekEnd);
      print("Reservations fetched");

      rooms = await RoomService.getRooms();
      print("Rooms fetched");

      guests = await GuestService.getGuests();
      print("Guests fetched");

    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      //fetchReservations();
      return Center(child: CircularProgressIndicator());
    }
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
                    fetchData();
                  });
                },
              ),
              Text('Week of ${formatDate(currentWeekStart)}'),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    currentWeekStart = currentWeekStart.add(Duration(days: 7));
                    fetchData();
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                    fetchData();
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
            itemCount: rooms.length, // Assuming you have a list of rooms
            itemBuilder: (BuildContext context, int index) {
              Room room = rooms[index];

              return Container(
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
                        child: buildReservationCell(room.id, currentWeekStart.add(Duration(days: i))),
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

  Widget buildReservationCell(int roomId, DateTime date) {
    return FutureBuilder<String>(
      future: getLeavingGuest(roomId, date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(8.0),
            color: getCellColor(roomId, date),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          return GestureDetector(
            onTap: () => onCellTap(roomId, date),
            child: Container(
              padding: EdgeInsets.all(8.0),
              color: getCellColor(roomId, date),
              child: Center(child: Text(snapshot.data ?? '')),
            ),
          );
        }
      },
    );
  }

  void onCellTap(int roomId, DateTime date) {
    // Find the reservation for this room and date
    Reservation? reservation = reservations.firstWhereOrNull(
          (r) => r.roomId == roomId &&
          date.isAfter(r.startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(r.endDate.add(const Duration(days: 1))),
    );

    if (reservation != null) {
      // Find the guest details
      Guest? guest = guests.firstWhereOrNull((g) => g.id == reservation.guestId);

      if (guest != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return buildReservationDetailsModal(reservation, guest);
          },
        );
      }
    }
  }



  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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

    List<Reservation> yesterdayReservations = reservations
        .where((res) => res.roomId == roomId && yesterday.isAfter(res.startDate) && yesterday.isBefore(res.endDate.add(Duration(days: 1))))
        .toList();

    List<Reservation> todayReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate.add(Duration(days: 1))))
        .toList();

    List<Reservation> tomorrowReservations = reservations
        .where((res) => res.roomId == roomId && tomorrow.isAfter(res.startDate) && tomorrow.isBefore(res.endDate.add(Duration(days: 1))))
        .toList();

    if (todayReservations.isNotEmpty) {
      // Check for changes in reservations (check-in, check-out, stay, or change of guest)
      if (yesterdayReservations.isEmpty) {
        return Colors.lightBlueAccent; // Guest is arriving today, use light green
      } else if (tomorrowReservations.isNotEmpty && todayReservations[0].id != tomorrowReservations[0].id) {
        return Colors.blueAccent; // Guest is changing today, use green
      } else {
        return Colors.lightBlue[200]; // Guest is in room, use light green
      }
    }

    return Colors.white; // Room available
  }

  Future<String> getGuestFullName(int guestId) async {  //TODO: Remove this function ???
    //List<Guest> guests = await GuestService.getGuests();
    Guest? guest = guests.firstWhereOrNull((g) => g.id == guestId);
    return guest != null ? '${guest.name} ${guest.surname}' : 'Unknown';
  }

  Future<String> getGuestSurname(int guestId) async {
    //List<Guest> guests = await GuestService.getGuests();
    Guest? guest = guests.firstWhereOrNull((g) => g.id == guestId);
    return guest != null ? guest.surname : 'Unknown';
  }

  Future<String?> getReservationInfo(int roomId, DateTime date) async {
    List<Reservation> roomReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate.add(Duration(days: 1))))
        .toList();


    if (roomReservations.isNotEmpty) {
      Reservation reservation = roomReservations[0];
      String arrivingGuest = await getGuestSurname(reservation.guestId);

      if (reservation.startDate == date) {
        // Guest is arriving today
        String leavingGuest = await getLeavingGuest(roomId, date);
        return leavingGuest.isNotEmpty ? '$leavingGuest / $arrivingGuest' : arrivingGuest;
      } else {
        // Guest is staying or leaving today
        String leavingGuest = await getLeavingGuest(roomId, date);
        return leavingGuest.isNotEmpty ? leavingGuest : arrivingGuest;
      }
    } else {
      return 'FREE'; // Room available
    }
  }


  Future<String> getLeavingGuest(int roomId, DateTime date) async {
    List<Reservation> leavingReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate.add(Duration(days: 1))))
        .toList();

    if (leavingReservations.isNotEmpty) {
      Reservation leavingReservation = leavingReservations[0];
      DateTime nextDay = date.add(Duration(days: 1));

      List<Reservation> nextDayReservations = reservations
          .where((res) => res.roomId == roomId && nextDay.isAfter(res.startDate) && nextDay.isBefore(res.endDate))
          .toList();

      if (nextDayReservations.isNotEmpty && leavingReservation.id != nextDayReservations[0].id) {
        // Different reservation IDs on adjacent days, both guests are involved
        return '${await getGuestSurname(leavingReservation.guestId)} / ${await getGuestSurname(nextDayReservations[0].guestId)}';
      } else {
        // Same reservation ID on adjacent days, returning only the leaving guest
        return await getGuestSurname(leavingReservation.guestId);
      }
    } else {
      return ''; // No leaving guest
    }
  }

  Widget buildReservationDetailsModal(Reservation reservation, Guest guest) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("Reservation Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Guest Name: ${guest.name} ${guest.surname}"),
          Text("Email: ${guest.email}"),
          Text("Phone: ${guest.phone}"),
          Text("Check-in Date: ${formatDate(reservation.startDate)}"),
          Text("Check-out Date: ${formatDate(reservation.endDate)}"),
          // Add more details as needed
        ],
      ),
    );
  }

}