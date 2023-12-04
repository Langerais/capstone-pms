import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'db_helper.dart';
import 'dbObjects.dart';
import 'drawer_menu.dart';
import 'main.dart';

class MenuView extends StatefulWidget {

  //final UserGroup userGroup;  // Assuming you have a UserGroup class

  //MenuView({required this.userGroup});

  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  late Future<List<MenuCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _categories = MenuCategoryService.getMenuCategories();
  }

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
                    _confirmOrder(context, reservation, item, room);
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

  void _confirmOrder(BuildContext context, Reservation reservation, MenuItem item, Room room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ConfirmOrderDialog(reservation: reservation, item: item, room: room);
      },
    );
  }


}

class _ConfirmOrderDialog extends StatefulWidget {
  final Reservation reservation;
  final MenuItem item;
  final Room room;

  _ConfirmOrderDialog({
    required this.reservation,
    required this.item,
    required this.room,
  });

  @override
  __ConfirmOrderDialogState createState() => __ConfirmOrderDialogState();
}

class __ConfirmOrderDialogState extends State<_ConfirmOrderDialog> {
  int itemCount = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Order'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Confirm adding ${widget.item.name} to Room ${widget.room.id} - ${widget.room.name} for €${(widget.item.price * itemCount).toStringAsFixed(2)}?'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: Icon(Icons.remove, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        if (itemCount > 1) itemCount--;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('$itemCount', style: TextStyle(fontSize: 20.0)),
                ),
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        itemCount++;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Yes'),
          onPressed: () async {
            await BalanceService.addOrder(widget.reservation.id, widget.item.id, itemCount, widget.item.price);
            Navigator.of(context).pop(); // Close the dialog
            Fluttertoast.showToast(
              msg: "${widget.item.name} x$itemCount added to Room ${widget.room.id} - ${widget.room.name}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          },
        ),
        TextButton(
          child: Text('No'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}
