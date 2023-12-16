import 'dart:async';

import 'package:capstone_pms/authentication.dart';
import 'package:capstone_pms/drawer_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'create_reservation_view.dart';
import 'models.dart';
import 'db_helper.dart';
import 'package:collection/collection.dart';

// TODO: Change Date Picker to Date Range Picker

class ArrivalsDeparturesScreen extends StatelessWidget {

  final GlobalKey<_ArrivalsDeparturesTableState> _tableKey = GlobalKey();

  ArrivalsDeparturesScreen({super.key});

  void _navigateAndRefresh(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReservationView(
          onReservationCreated: () {

          },
        ),
      ),
    );
    _tableKey.currentState?.fetchData();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arrivals/Departures'),
        actions: <Widget>[
          SizedBox(
            width: 60,
            height: 60,
            child: IconButton(
              icon: const Icon(Icons.add, size: 50),
              onPressed: () => _navigateAndRefresh(context),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
          ],
        ),
      ),
      body: ArrivalsDeparturesTable(key: _tableKey),
    floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AI Chat
          print('AI Chat Button Pressed');
          // You might want to navigate to a new screen or open a dialog
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.chat),
      ),
    );
  }
}

class ArrivalsDeparturesTable extends StatefulWidget {
  const ArrivalsDeparturesTable({Key? key}) : super(key: key);

  @override
  _ArrivalsDeparturesTableState createState() => _ArrivalsDeparturesTableState();

}

class _ArrivalsDeparturesTableState extends State<ArrivalsDeparturesTable> {
  late DateTime currentWeekStart;
  List<Reservation> reservations = [];
  List<Room> rooms = [];
  List<Guest> guests = [];
  Timer? refreshTimer;
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
      DateTime previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
      DateTime nextWeekEnd = currentWeekStart.add(const Duration(days: 14));
      reservations = await ReservationService.getReservationsByDateRange(previousWeekStart, nextWeekEnd);

      rooms = await RoomService.getRooms();

      guests = await GuestService.getGuests();


    } catch (e) {
      if (kDebugMode) {
        print("Error fetching data: $e");
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  DateTime getMondayOfSelectedWeek(DateTime date) {
    DateTime weekStart = date.subtract(Duration(days: date.weekday - 1));
    weekStart = weekStart.add(const Duration(seconds: 1)); // Needed to avoid cells coloring bug
    return weekStart;
  }


  @override
  Widget build(BuildContext context) {


    if (isLoading) { return const Center(child: CircularProgressIndicator()); }

    return VisibilityDetector(
      key: const Key('arrivals-departures-key'), // Unique key for VisibilityDetector
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          cancelRefreshTimer(); // Cancel timer when widget is not visible
        } else {
          startRefreshTimer(); // Start timer when widget is visible
        }
      },
      child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          // Forward/Backward buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentWeekStart = currentWeekStart.subtract(Duration(days: 7));
                    fetchData();
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: currentWeekStart,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      currentWeekStart = getMondayOfSelectedWeek(picked);
                      fetchData();
                    });
                  }
                },
              ),
              Text('Week of ${formatDate(currentWeekStart)}'),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    currentWeekStart = currentWeekStart.add(const Duration(days: 7));
                    fetchData();
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                    fetchData();
                    print("TODAY: " + currentWeekStart.toString());
                  });
                },
                child: const Text('TODAY'),
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
                        decoration: BoxDecoration(
                          color: Colors.grey[500], // Background color
                          border: const Border(
                            right: BorderSide(width: 1.0, color: Colors.black), // Right border
                            bottom: BorderSide(width: 1.0, color: Colors.black), // Bottom border
                          ),
                        ),
                        child: const Center(child: Text('Day → ')),
                      ),
                    ),
                    for (int i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: currentWeekStart.add(Duration(days: i)).day == DateTime.now().day &&
                                currentWeekStart.add(Duration(days: i)).month == DateTime.now().month
                                ? Colors.grey[500] // Darker grey for today's date
                                : Colors.grey[300],
                            border: const Border(
                              right: BorderSide(width: 1.0, color: Colors.black), // Right border
                              bottom: BorderSide(width: 1.0, color: Colors.black), // Bottom border
                            ),
                          ),
                          padding: const EdgeInsets.all(8.0),
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
                        decoration: BoxDecoration(
                          color: Colors.grey[500], // Background color
                          border: const Border(
                            right: BorderSide(width: 1.0, color: Colors.black), // Right border
                            bottom: BorderSide(width: 2.0, color: Colors.black), // Bottom border
                          ),
                        ),
                        child: const Center(child: Text('Room ↓ ')),
                      ),
                    ),
                    for (int i = 0; i < 7; i++)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: currentWeekStart.add(Duration(days: i)).day == DateTime.now().day &&
                                currentWeekStart.add(Duration(days: i)).month == DateTime.now().month
                                ? Colors.grey[500] // Darker grey for today's date
                                : Colors.grey[300], // Background color
                            border: const Border(
                              right: BorderSide(width: 1.0, color: Colors.black), // Right border
                              bottom: BorderSide(width: 2.0, color: Colors.black), // Bottom border
                            ),
                          ),
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
            physics: const NeverScrollableScrollPhysics(), // Disable ListView scrolling
            itemCount: rooms.length,
            itemBuilder: (BuildContext context, int index) {
              Room room = rooms[index];

              return IntrinsicHeight( // Wrap Row in an IntrinsicHeight widget
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Align children vertically
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[500], // Background color
                          border: const Border(
                            right: BorderSide(width: 1.0, color: Colors.black), // Right border
                            bottom: BorderSide(width: 1.0, color: Colors.black), // Bottom border
                          ),
                        ),
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
          )
          ],
        ),
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
              decoration: BoxDecoration(
                color: getCellColor(roomId, date),
                border: const Border(
                  //right: BorderSide(width: 1.0, color: Colors.black), // Right border
                  bottom: BorderSide(width: 0.2, color: Colors.black), // Bottom border
                ),
              ),
              child: Center(child: Text(snapshot.data ?? '')),
            ),
          );
        }
      },
    );
  }

  // Show reservation details when tapping on a cell / If there are multiple reservations for the same room on the same day, find the one that is arriving today
  Future<void> onCellTap(int roomId, DateTime date) async {
    List<Reservation> relevantReservations = await ReservationService.getReservationsByRoomAndDateRange(date, date, roomId);

    Reservation? arrivingReservation;

    if (relevantReservations.isNotEmpty) {
      // If there are multiple reservations for the same room on the same day, find the one that is arriving today

      if(relevantReservations.length > 1){
        for (var reservation in relevantReservations) {
          if (isSameDate(date, reservation.startDate)) {
            arrivingReservation = reservation;
            break;
          }
        }
      } else {
        // If there is only one reservation for the room on the selected date, use it
        arrivingReservation = relevantReservations[0];
      }

    }


    if (arrivingReservation != null) {
      // Find the guest details
      Guest? guest = guests.firstWhereOrNull((g) => g.id == arrivingReservation!.guestId);

      if (guest != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return FractionallySizedBox(
              heightFactor: 0.8, // Adjust this value as needed (0.8 = 80% of screen height)
              child: buildReservationDetailsModal(arrivingReservation!, guest),
            );
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

    List<Reservation> todayReservations = reservations
        .where((res) => res.roomId == roomId && res.startDate.isBefore(date) && res.endDate.isAfter(date.subtract(Duration(days: 1))))
        .toList();


    if (todayReservations.isNotEmpty) {
      // Check for changes in reservations (check-in, check-out, stay, or change of guest)
      if (todayReservations.length > 1) {
        return Colors.blueAccent; // Guest is changing today, use green
      } else if (isSameDate(todayReservations[0].startDate, date)) {
        return Colors.lightBlueAccent; // Guest is arriving today, use light green
      } else {
        return Colors.lightBlue[200]; // Guest is in room, use light green
      }
    }

    return Colors.white; // Room available
  }

  void startRefreshTimer() {
    cancelRefreshTimer();
    if (refreshTimer == null || !refreshTimer!.isActive) {
      const refreshInterval = Duration(seconds: REFRESH_TIMER); // Set your desired interval
      refreshTimer = Timer.periodic(refreshInterval, (Timer t) => fetchData());
    }
  }

  void cancelRefreshTimer() {
    refreshTimer?.cancel();
    refreshTimer = null;
  }

  @override
  void dispose() {
    cancelRefreshTimer();
    super.dispose();
  }



  Future<String> getGuestFullName(int guestId) async {  //TODO: Remove this function ???
    Guest? guest = guests.firstWhereOrNull((g) => g.id == guestId);
    return guest != null ? '${guest.name} ${guest.surname}' : 'Unknown';
  }

  Future<String> getGuestSurname(int guestId) async {
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
    List<Reservation> todaysReservations =  await ReservationService.getReservationsByRoomAndDateRange(date, date, roomId);


    String leavingGuest = '';
    String arrivingGuest = '';

    for (var reservation in todaysReservations) {
      if (isSameDate(reservation.endDate, date)) {
        leavingGuest = await getGuestSurname(reservation.guestId);
      }
      if (isSameDate(reservation.startDate, date)) {
        arrivingGuest = await getGuestSurname(reservation.guestId);
      }
    }


    if (leavingGuest.isNotEmpty && arrivingGuest.isNotEmpty) {
      return '$leavingGuest / $arrivingGuest';
    } else if (leavingGuest.isNotEmpty) {
      return leavingGuest;
    } else if (arrivingGuest.isNotEmpty) {
      return arrivingGuest;
    } else if (todaysReservations.isNotEmpty) {
      return getGuestSurname(todaysReservations[0].guestId); // No leaving or arriving guest
    } else {
      return ''; // Room available
    }
  }

  Widget buildReservationDetailsModal(Reservation reservation, Guest guest) {
    // State to hold the new selected status
    String newStatus = reservation.status ?? 'Pending';

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Reservation Details"),
              if (Auth.getUserRole() == UserGroup.Admin || Auth.getUserRole() == UserGroup.Manager)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => confirmAndDeleteReservation(context, reservation.id),
                ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            //constraints: const BoxConstraints(maxWidth: 6000),
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const SizedBox(height: 10),
                  Text("Guest Name: ${guest.name} ${guest.surname ?? ''}"),
                  Text("Email: ${guest.email}"),
                  Text("Phone: ${guest.phone}"),
                  Text("Check-in Date: ${formatDate(reservation.startDate)}"),
                  Text("Check-out Date: ${formatDate(reservation.endDate)}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status Picker Dropdown
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: newStatus,
                          onChanged: (String? newValue) {
                            setState(() {
                              newStatus = newValue!;
                            });
                          },
                          items: <String>['Pending', 'Checked-in', 'Checked-out']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                      // Save Button
                      const SizedBox(width: 50), // Add some space between the dropdown and the button
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: newStatus != reservation.status ? () async {
                          await ReservationService.changeReservationStatus(reservationId: reservation.id, newStatus: newStatus);
                          Navigator.pop(context);
                          fetchData();
                          // Close the modal after saving
                        } : null, // Disable button if status is unchanged
                        style: ElevatedButton.styleFrom(
                          primary: newStatus != reservation.status ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void confirmAndDeleteReservation(BuildContext context, int reservationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Warning: This action cannot be undone!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                // Implement the logic to delete the reservation
                await ReservationService.deleteReservation(reservationId: reservationId);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reservation deleted')),
                );
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(); // Close the reservation details dialog
                fetchData();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }



}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
