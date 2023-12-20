import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'config.dart';
import 'db_helper.dart';
import 'models.dart';



class GuestsListView extends StatefulWidget {
  @override
  _GuestsListViewState createState() => _GuestsListViewState();
}

class _GuestsListViewState extends State<GuestsListView> {
  List<Guest> guests = [];
  List<Guest> filteredGuests = [];
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    refreshTimer?.cancel();
    _fetchGuests();
    startRefreshTimer();
  }

  void startRefreshTimer() {
    refreshTimer?.cancel();
    const refreshInterval = Duration(seconds: AppConfig.REFRESH_TIMER);
    refreshTimer = Timer.periodic(refreshInterval, (Timer t) => _fetchGuests());
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void _fetchGuests() async {
    try {
      var fetchedGuests = await GuestService.getGuests();
      if (mounted) {
        setState(() {
          guests = fetchedGuests;
          filteredGuests = fetchedGuests;
        });
      }
    } catch (e) {
      print('Failed to fetch guests: $e');
    }
  }

  void _searchGuest(String searchText) {
    setState(() {
      filteredGuests = GuestService.filterGuests(searchText, guests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('guests-list-view-key'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          refreshTimer?.cancel();
        } else {
          startRefreshTimer();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Guests'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _searchGuest,
              decoration: InputDecoration(
                labelText: 'Search Guests',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredGuests.length,
              itemBuilder: (context, index) {
                final guest = filteredGuests[index];
                return ListTile(
                  title: Text('${guest.name} ${guest.surname}'),
                  subtitle: Text('${guest.phone}\n${guest.email}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GuestReservationsView(guest: guest),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Open AI Chat
            print('AI Chat Button Pressed');
            // You might want to navigate to a new screen or open a dialog
          },
          child: Icon(Icons.chat),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}

class GuestReservationsView extends StatelessWidget {   // TODO: Fetch only Guest's reservations (Add fetchReservationsForGuest method)
  final Guest guest;

  GuestReservationsView({required this.guest});

  Future<List<Reservation>> fetchReservationsForGuest(Guest guest) async {
    try {
      var guestReservations = await ReservationService.getReservationsForGuest(guest);
      // Filter reservations for the selected guest
      return guestReservations.toList();
    } catch (e) {
      // Handle exceptions
      print('Failed to fetch reservations: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reservations for ${guest.name} ${guest.surname}'),
      ),
      body: FutureBuilder<List<Reservation>>(
        future: fetchReservationsForGuest(guest),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final reservation = snapshot.data![index];
                return ListTile(
                  title: Text('Room ${reservation.roomId}'),
                  subtitle: Text('Check-In: ${formatDate(reservation.startDate)}\n'
                      'Check-Out: ${formatDate(reservation.endDate)}\n'
                      'Due Amount: ${reservation.dueAmount.toString()}€'),
                );
              },
            );
          } else {
            return Center(child: Text('No reservations found'));
          }
        },
      ),
    );
  }
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year % 100}';
}