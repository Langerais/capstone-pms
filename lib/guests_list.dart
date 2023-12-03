
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dbObjects.dart';

//import 'guest_reservations_view.dart';

class GuestsListView extends StatefulWidget {
  @override
  _GuestsListViewState createState() => _GuestsListViewState();
}

class _GuestsListViewState extends State<GuestsListView> {
  List<Guest> guests = [];
  List<Guest> filteredGuests = [];

  @override
  void initState() {
    super.initState();
    _fetchGuests();
  }

  void _fetchGuests() async {
    try {
      var fetchedGuests = await GuestService.getGuests();
      setState(() {
        guests = fetchedGuests;
        filteredGuests = fetchedGuests;
      });
    } catch (e) {
      // Handle exceptions
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
    return Scaffold(
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
                      'Due Amount: \$${reservation.dueAmount.toString()}'),
                  // Optionally, add trailing or leading widgets
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