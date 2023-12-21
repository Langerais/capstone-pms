import 'dart:async';
import 'package:MyLittlePms/authentication.dart';
import 'package:MyLittlePms/drawer_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'config.dart';
import 'create_reservation_view.dart';
import 'models.dart';
import 'db_helper.dart';
import 'package:collection/collection.dart';


class ArrivalsDeparturesScreen extends StatelessWidget {
  final GlobalKey<_ArrivalsDeparturesTableState> _tableKey = GlobalKey();

  ArrivalsDeparturesScreen({super.key});

  void _navigateAndRefresh(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReservationView(
          onReservationCreated: () {},
        ),
      ),
    );
    _tableKey.currentState?.fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserGroup>(
      future: Auth.getUserRole(),
      builder: (context, snapshot) {
        List<Widget> appBarActions = [];

        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData &&
              (snapshot.data == UserGroup.Admin || snapshot.data == UserGroup.Manager || snapshot.data == UserGroup.Reception)) {
            appBarActions.add(
              SizedBox(
                width: 60,
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.add, size: 50),
                  onPressed: () => _navigateAndRefresh(context),
                ),
              ),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Arrivals/Departures'),
            actions: appBarActions,
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                ...getDrawerItems(snapshot.data ?? UserGroup.None, context),
              ],
            ),
          ),
          body: ArrivalsDeparturesTable(key: _tableKey),
        );
      },
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

  // Utility function to get the Monday of the selected week
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
                    currentWeekStart = currentWeekStart.subtract(const Duration(days: 7));
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
              // Button to go to today's date
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                    fetchData();
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
                        padding: const EdgeInsets.all(8.0),
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
                // The row under the date with day names
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
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

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
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

  // Build a cell for a reservation
  Widget buildReservationCell(int roomId, DateTime date) {
    return FutureBuilder<String>(
      future: getGuestsNamesForRoomAndDate(roomId, date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            color: getCellColor(roomId, date),
            child: const Center(child: CircularProgressIndicator()),
          );
        } else {
          return GestureDetector(
            onTap: () => onCellTap(roomId, date),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: getCellColor(roomId, date),
                border: const Border(
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
              heightFactor: 1.2,
              child: buildReservationDetailsModal(arrivingReservation!, guest),
            );
          },
        );

      }
    }
  }


  // Utility function to check if two DateTime objects are the same date
  bool isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Utility function to format DateTime
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // Utility function to get the day name from DateTime
  String formatDayName(DateTime date) {
    List<String> daysOfWeek = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
    return daysOfWeek[date.weekday - 1];
  }

  // Utility function to get the cell color for a room on a specific date depending on the reservation status
  Color? getCellColor(int roomId, DateTime date) {
    List<Reservation> todayReservations = reservations
        .where((res) => res.roomId == roomId && res.startDate.isBefore(date) && res.endDate.isAfter(date.subtract(Duration(days: 1))))
        .toList();

    if (todayReservations.isNotEmpty) {
      // Check for changes in reservations (check-in, check-out, stay, or change of guest)
      if (todayReservations.length > 1) {
        return Colors.blueAccent; // Guest is changing today, use blue
      } else if (isSameDate(todayReservations[0].startDate, date)) {
        return Colors.lightBlueAccent; // Guest is arriving today, use lighter blue
      } else {
        return Colors.lightBlue[200]; // Guest is in room, use the lightest blue
      }
    }

    return Colors.white; // Room available
  }

  // Refresh the data every 5 minutes
  void startRefreshTimer() {
    cancelRefreshTimer();
    if (refreshTimer == null || !refreshTimer!.isActive) {
      const refreshInterval = Duration(seconds: AppConfig.REFRESH_TIMER); // Set your desired interval
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

  Future<String> getGuestSurname(int guestId) async {
    Guest? guest = guests.firstWhereOrNull((g) => g.id == guestId);
    return guest != null ? guest.surname : 'Unknown';
  }


  // Utility function to get the guest name for a room on a specific date;
  // If there is a guest leaving on that date, return their surname
  // If there is a guest arriving on that date, return their surname
  // If there is a guest staying on that date, return their surname
  // If there is no guest on that date, return an empty string
  // If there are multiple guests on that date, return Guest1 / Guest2
  Future<String> getGuestsNamesForRoomAndDate(int roomId, DateTime date) async {
    List<Reservation> todayReservations =  await ReservationService.getReservationsByRoomAndDateRange(date, date, roomId);


    String leavingGuest = '';
    String arrivingGuest = '';

    for (var reservation in todayReservations) {
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
    } else if (todayReservations.isNotEmpty) {
      return getGuestSurname(todayReservations[0].guestId); // No leaving or arriving guest
    } else {
      return ''; // Room available
    }
  }

  Widget buildReservationDetailsModal(Reservation reservation, Guest guest) {

    // State to hold the new selected status
    String newStatus = reservation.status ?? 'Pending';
    UserGroup userRole = UserGroup.None;

    // Fetch the creation log for the reservation
    Future<Map<String, dynamic>> fetchCreationLogAndUser() async {
      var logs = await LogService.fetchLogs(
          action: "Reservation Add",
          details: "Reservation Id: ${reservation.id}"
      );

      userRole = await Auth.getUserRole();

      if (logs.isNotEmpty) {
        var log = logs.first;
        var user = await UsersService.getUser(log['user_id']);
        return {
          'timestamp': log['timestamp'],
          'user': user,
        };
      }
      return {};
    }

    // Fetch the last reservation status change and the user who changed it
    Future<Map<String, dynamic>> fetchLastStatusChangeAndUser() async {
      var statusChanges = await ReservationService.getReservationStatusChangeByReservation(reservation.id);
      if (statusChanges.isNotEmpty) {
        var lastStatusChange = statusChanges.last;
        var user = await UsersService.getUser(lastStatusChange.userId);
        return {
          'timestamp': lastStatusChange.timestamp,
          'user': user,
        };
      }
      return {};
    }

    String formatTimestamp(DateTime dateTime) {
      return DateFormat('yyyy-MM-dd – kk:mm').format(dateTime);
    }


    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Container(
            height: MediaQuery.of(context).size.height * 1, // 80% of screen height
            child: AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Reservation Details"),
                  if (userRole == UserGroup.Admin || userRole == UserGroup.Manager)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => confirmAndDeleteReservation(context, reservation.id),
                    ),
                ],
              ),
              content: FutureBuilder(
                future: Future.wait([fetchCreationLogAndUser(), fetchLastStatusChangeAndUser()]),
                builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else {
                    var creationData = snapshot.data![0];
                    var lastChangeData = snapshot.data![1];
                    var creationUser = creationData['user'] as User?;
                    var lastChangeUser = lastChangeData['user'] as User?;

                    return Container(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            const SizedBox(height: 10),
                            Text("Guest Name: ${guest.name} ${guest.surname ?? ''}"),
                            Text("Email: ${guest.email}"),
                            Text("Phone: ${guest.phone}"),
                            Text("Check-in Date: ${formatDate(reservation.startDate)}"),
                            Text("Check-out Date: ${formatDate(reservation.endDate)}"),
                            if (creationUser != null && creationData['timestamp'] != null) ...[
                              Text("Date Created: ${DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.parse(creationData['timestamp']))}"),
                              Text("Created by: ${creationUser.name} ${creationUser.surname}"),
                            ],
                            if (lastChangeUser != null && lastChangeData['timestamp'] != null) ...[
                              Text("Last Status Change: ${formatTimestamp(lastChangeData['timestamp'])}"),
                              Text("Changed by: ${lastChangeUser.name} ${lastChangeUser.surname}"),
                            ],
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
                    );
                  }
                },
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
