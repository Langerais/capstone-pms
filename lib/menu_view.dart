import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'dbObjects.dart';


class MenuView extends StatefulWidget {
  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  late Future<List<MenuCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = MenuService.getMenuCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Categories'),
      ),
      body: FutureBuilder<List<MenuCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                MenuCategory category = snapshot.data![index];
                return ListTile(
                  title: Text(category.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryItemsView(categoryId: category.id),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CategoryItemsView extends StatelessWidget {
  final int categoryId;

  CategoryItemsView({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Items'),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: MenuService.getMenuItemsByCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No items available in this category'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                MenuItem item = snapshot.data![index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.description}\nPrice: €${item.price}'),
                  onTap: () {
                    _showActiveReservations(context, item);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showActiveReservations(BuildContext context, MenuItem item) async {
    try {
      DateTime today = DateTime.now();
      List<Reservation> activeReservations = await ReservationService.getReservationsByDateRange(today, today);
      List<Guest> guests = await GuestService.getGuests();
      List<Room> rooms = await RoomService.getRooms();
      _showReservationsDialog(context, item, activeReservations, guests, rooms);
    } catch (e) {
      // Handle errors or show a message if there is an issue fetching data
      print('Error fetching data: $e');
    }
  }

  void _showReservationsDialog(BuildContext context, MenuItem item, List<Reservation> reservations, List<Guest> guests, List<Room> rooms) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Reservation for ${item.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: reservations.map((reservation) {
                Room room = rooms.firstWhere((r) => r.id == reservation.roomId, orElse: () => Room(id: 0, name: 'Unknown', channelManagerId: 'Unknown'));
                Guest guest = guests.firstWhere((g) => g.id == reservation.guestId, orElse: () => Guest(id: 0, channelManagerId: 'Unknown', name: 'Unknown', surname: 'Guest', phone: 'Unknown', email: 'Unknown'));
                return ListTile(
                  title: Text('Room ${room.name}'),
                  subtitle: Text(guest.surname),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    // Implement your logic for when a reservation is tapped
                    // TODO: Implement _confirmOrder method
                    // Example: _confirmOrder(context, reservation, item);
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// Include _confirmOrder method and other methods as necessary

}
