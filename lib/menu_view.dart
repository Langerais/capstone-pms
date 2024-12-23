import 'package:flutter/material.dart';
import 'authentication.dart';
import 'db_helper.dart';
import 'models.dart';
import 'drawer_menu.dart';

class MenuView extends StatefulWidget {



  //final UserGroup userGroup;  // Assuming you have a UserGroup class

  //MenuView({required this.userGroup});

  @override
  _MenuViewState createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  late Future<List<MenuCategory>> _categories;
  UserGroup userGroup = UserGroup.None;

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
      drawer: FutureBuilder<UserGroup>(
        future: Auth.getUserRole(),  // Get the current user's role
        builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting, show a progress indicator
            return Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            // If there's an error, show an error message
            return Drawer(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            userGroup = snapshot.data!;
            // Once data is available, build the drawer
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...getDrawerItems(snapshot.data!, context), // Generate items for User
                ],
              ),
            );
          }
        },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AI Chat
          print('AI Chat Button Pressed');
          // You might want to navigate to a new screen or open a dialog
        },
        child: Icon(Icons.chat),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class CategoryItemsView extends StatefulWidget {
  final int categoryId;

  CategoryItemsView({required this.categoryId});

  @override
  _CategoryItemsViewState createState() => _CategoryItemsViewState();
}

class _CategoryItemsViewState extends State<CategoryItemsView> {
  late Future<List<MenuItem>> _menuItems;
  late Future<UserGroup> _userGroupFuture;

  @override
  void initState() {
    super.initState();
    _menuItems = MenuService.getMenuItemsByCategory(widget.categoryId);
    _userGroupFuture = Auth.getUserRole(); // Get user role asynchronously
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Items'),
        actions: <Widget>[
          FutureBuilder<UserGroup>(
            future: _userGroupFuture,
            builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
              if (!snapshot.hasData) {
                return Container(); // Return an empty container if user role is not yet determined
              }
              UserGroup userGroup = snapshot.data!;
              if (userGroup == UserGroup.Admin || userGroup == UserGroup.Manager) {
                return Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _showCreateItemDialog(context, widget.categoryId);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (BuildContext context) => EditItemDialog(categoryId: widget.categoryId),
                      ),
                    ),
                  ],
                );
              } else {
                return Container(); // Return an empty container if user role does not have permission
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menuItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items available in this category'));
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

    reservations.sort((a, b) {
      Room roomA = rooms.firstWhere((r) => r.id == a.roomId, orElse: () => Room(id: 0, name: 'Unknown', maxGuests: 0));
      Room roomB = rooms.firstWhere((r) => r.id == b.roomId, orElse: () => Room(id: 0, name: 'Unknown', maxGuests: 0));
      return roomA.name.compareTo(roomB.name);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Reservation for ${item.name}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: reservations.map((reservation) {
                Room room = rooms.firstWhere((r) => r.id == reservation.roomId, orElse: () => Room(id: 0, name: 'Unknown', maxGuests: 0));
                Guest guest = guests.firstWhere((g) => g.id == reservation.guestId, orElse: () => Guest(id: 0, name: 'Unknown', surname: 'Guest', phone: 'Unknown', email: 'Unknown'));
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

void _showCreateItemDialog(BuildContext context, int categoryId) {
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Create New Menu Item'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: InputDecoration(hintText: 'Item Name'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(hintText: 'Description'),
              ),
              TextField(
                controller: priceController,
                decoration: InputDecoration(hintText: 'Price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Create'),
            onPressed: () async {
              String name = nameController.text;
              String description = descriptionController.text;
              String priceStr = priceController.text;
              double? price = double.tryParse(priceStr);

              if (name.isEmpty || description.isEmpty || price == null || price < 0) {
                // Handle input validation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields with valid data.')),
                );
                return;
              }

              try {
                await MenuService.addMenuItem(name, categoryId, description, price);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name added successfully')),
                );
                Navigator.of(context).pop(); // Close the create item dialog
                Navigator.of(context).pop(); // Navigate back to the categories view

              } catch (e) {
                // Handle errors like network issues or server errors
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create item: $e')),
                );
              }
            },
          ),
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
          child: const Text('Yes'),
          onPressed: () async {
            await BalanceService.addOrder(widget.reservation.id, widget.item.id, itemCount, widget.item.price);
            Navigator.of(context).pop(); // Close the dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.item.name} x$itemCount added to Room ${widget.room.id} - ${widget.room.name}')),
            );
          },
        ),
        TextButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }

}

class EditItemDialog extends StatefulWidget {
  final int categoryId;

  EditItemDialog({required this.categoryId});

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  MenuItem? selectedItem;
  List<MenuItem> items = [];
  List<MenuCategory> categories = [];
  bool isLoading = true;

  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;
  int selectedCategoryId = 0;

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
    _loadMenuCategories();
  }

  void _updateEditingControllers(MenuItem item) {
    nameController = TextEditingController(text: item.name);
    descriptionController = TextEditingController(text: item.description);
    priceController = TextEditingController(text: item.price.toString());
    selectedCategoryId = item.categoryId;
  }

  void _loadMenuItems() async {
    try {
      items = await MenuService.getMenuItemsByCategory(widget.categoryId);
      if (items.isNotEmpty) {
        selectedItem = items.first;
        _updateEditingControllers(selectedItem!);
      }
      setState(() => isLoading = false);
    } catch (e) {
      // TODO: Show error message
      setState(() => isLoading = false);
    }
  }

  void _loadMenuCategories() async {
    try {
      categories = await MenuCategoryService.getMenuCategories();
      setState(() {});
    } catch (e) {
      // TODO: Show error message
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();

// Inside the build method of _EditItemDialogState
    return AlertDialog(
      title: const Text('Edit Menu Item'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<MenuItem>(
                    value: selectedItem,
                    onChanged: (MenuItem? newValue) {
                      setState(() {
                        selectedItem = newValue!;
                        _updateEditingControllers(newValue);
                      });
                    },
                    items: items.map<DropdownMenuItem<MenuItem>>((MenuItem item) {
                      return DropdownMenuItem<MenuItem>(
                        value: item,
                        child: Text(item.name),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(context, selectedItem),
                ),
              ],
            ),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Item Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(hintText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            DropdownButton<int>(
              value: selectedCategoryId,
              onChanged: (int? newValue) {
                setState(() {
                  selectedCategoryId = newValue!;
                });
              },
              items: categories.map<DropdownMenuItem<int>>((MenuCategory category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {

                try {

                  if (nameController.text.isEmpty || priceController.text.isEmpty || double.parse(priceController.text) < 0) {
                    // Handle input validation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in all fields with valid data.')),
                    );
                    return;
                  }

                  await MenuService.updateMenuItem(
                    selectedItem!.id,
                    nameController.text,
                    selectedCategoryId,
                    descriptionController.text,
                    double.parse(priceController.text),
                  );
                  Navigator.of(context).pop(); // Close the edit dialog
                  Navigator.of(context).pop(); // Close the category items view

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Item '${nameController.text}' updated successfully")),
                  );
                } catch (e) {
                  // Handle the error (e.g., show an error message)
                }
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],

        ),

      ),
    );

  }

  void _confirmDelete(BuildContext context, MenuItem? item) {
    if (item == null) return; // Safety check

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${item.name}?'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this item?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  await MenuService.deleteMenuItem(item.id);
                  Navigator.of(context).pop(); // Close the confirmation dialog
                  Navigator.of(context).pop(); // Close the edit dialog
                  Navigator.of(context).pop(); // Close the category items view

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Item '${item.name}' deleted successfully")),
                  );
                } catch (e) {
                  Navigator.of(context).pop(); // Close the confirmation dialog
                }
              },
              style: TextButton.styleFrom(primary: Colors.red),
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
              },
            ),
          ],
        );
      },
    );
  }
}

