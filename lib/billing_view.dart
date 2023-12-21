import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'authentication.dart';
import 'config.dart';
import 'db_helper.dart';
import 'models.dart';
import 'package:intl/intl.dart';
import 'drawer_menu.dart';


class BillingView extends StatefulWidget {
  @override
  _BillingViewState createState() => _BillingViewState();
}

class _BillingViewState extends State<BillingView> {
  Timer? _timer;  // Timer to refresh the screen
  DateTime selectedDate = DateTime.now();
  List<Reservation> reservations = [];
  List<Room> rooms = [];
  Map<int, Guest> guestsMap = {};
  Map<int, Room> roomsMap = {};

  @override
  void initState() {
    super.initState();
    fetchReservationsAndGuests();
  }

  void refreshState() {
    setState(() {
      fetchReservationsAndGuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('billing-view-key'),
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          _timer?.cancel();
          print("Timer cancelled");
        } else {
          _startPeriodicFetch();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Billing Information')),
        drawer: FutureBuilder<UserGroup>(
          future: Auth.getUserRole(),  // Get the current user's role
          builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While waiting, show a progress indicator
              return const Drawer(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Drawer(
                child: Center(child: Text('Error: ${snapshot.error}')),
              );
            } else {
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
        body: Column(
          children: [
            Container(
              color: Colors.lightBlue[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(
                        'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today),
                    onPressed: () => _setToday(),
                  ),
                ],
              ),
            ),
            // List of Reservations
            Expanded(
              child: ListView.builder(
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  Reservation reservation = reservations[index];
                  Room ?room = roomsMap[reservation.roomId]; // Default Room or handle null
                  Guest ?guest = guestsMap[reservation.guestId]; // Default Guest or handle null

                  return FutureBuilder<double>(
                    future: BalanceService.calculateUnpaidAmount(reservation.id),
                    builder: (context, unpaidAmountSnapshot) {
                      if (!unpaidAmountSnapshot.hasData) return const CircularProgressIndicator();
                      double unpaidAmount = unpaidAmountSnapshot.data!;

                      return ListTile(
                        title: Text('${room?.name} - ${guest?.surname} : ${unpaidAmount.toStringAsFixed(2)}€'),
                        subtitle: Text('Check-out: ${DateFormat('yyyy-MM-dd').format(reservation.endDate)}'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => BillingDetailsDialog(
                              reservationId: reservation.id,
                              roomName: room?.name ?? '', // Add room number here
                              guestSurname: guest?.surname ?? '', // Add guest surname here
                              onRefresh: refreshState, // Pass the refreshState method as a callback
                            ),
                          );
                        },
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



  void _setToday() {
    setState(() {
      selectedDate = DateTime.now();
      fetchReservationsAndGuests(); // Fetch new reservations for the current date
    });
  }

  // Select a date from a date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fetchReservationsAndGuests(); // Fetch new reservations for the selected date
      });
    }
  }

  // Fetch reservations and guests for the selected date
  void fetchReservationsAndGuests() async {
    try {
      rooms = await RoomService.getRooms();
      reservations = await ReservationService.getReservationsByDateRange(selectedDate, selectedDate);
      List<int> guestIds = reservations.map((r) => r.guestId).toSet().toList();
      List<Guest> guests = await GuestService.getGuestsByIds(guestIds);
      roomsMap = {for (var room in rooms) room.id: room};
      guestsMap = {for (var guest in guests) guest.id: guest};
      try {
        reservations.sort((a, b) =>
            (roomsMap[a.roomId]?.name ?? '').compareTo(roomsMap[b.roomId]?.name ?? ''));
        setState(() {});
      } catch (e) {
        // TODO: Handle errors
      }
      setState(() {});
    } catch (e) {
      // TODO: Handle errors
    }
  }

  // Start periodic fetch of reservations and guests
  void _startPeriodicFetch() {
    _timer?.cancel();
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(const Duration(seconds: AppConfig.REFRESH_TIMER), (Timer t) =>
          fetchReservationsAndGuests());
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }
}



class BillingDetailsDialog extends StatelessWidget {
  final int reservationId;
  final String roomName;
  final String guestSurname;
  final Function onRefresh;

  BillingDetailsDialog({
    required this.reservationId,
    required this.roomName,
    required this.guestSurname,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: FutureBuilder<UserGroup>(
          future: Auth.getUserRole(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData &&
                (snapshot.data == UserGroup.Admin ||
                    snapshot.data == UserGroup.Manager
                )
            ) {
              return _buildAdminView(context, true);
            } else {
              return _buildAdminView(context, false);
            }
          },
        ),
      ),
    );
  }

  Widget _buildAdminView(BuildContext context, bool isAdmin) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Billing Details for Room $roomName, Guest $guestSurname'),
        ),
        const Divider(),
        Flexible(
          child: _buildBalanceEntries(context, isAdmin),
        ),
        ButtonBar(
          children: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _showAddPaymentDialog(context, reservationId),
              child: const Text('Add Payment'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceEntries(BuildContext context, bool isAdmin) {
    return FutureBuilder<List<BalanceEntry>>(
      future: BalanceService.getBalanceEntriesForReservation(reservationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No billing details available.');
        }
        List<BalanceEntry> entries = snapshot.data!;
        entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          shrinkWrap: true,
          itemCount: entries.length,
          itemBuilder: (context, index) {
            BalanceEntry entry = entries[index];
            return _buildListItem(context, entry, isAdmin);
          },
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, BalanceEntry entry, bool isAdmin) {
    String paymentMethod = entry.menuItemId == 0 ? "CASH" : "CARD";

    void refreshAndCloseDialog() {
      onRefresh();
      Navigator.of(context).pop(); // Close the dialog after refreshing
    }

    if (entry.menuItemId == 0 || entry.menuItemId == -1) {
      // Payment entry
      return ListTile(
        title: Text(
          'Payed $paymentMethod: ${entry.amount.toStringAsFixed(2)}€',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(entry.timestamp)),
        trailing: isAdmin ? IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmationDialog(context, entry, refreshAndCloseDialog),
        ) : null,
      );
    } else {
      // Order entry
      return FutureBuilder<MenuItem>(
        future: MenuService.getMenuItem(entry.menuItemId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(title: Text('Loading...'));
          }
          if (!snapshot.hasData) {
            return const ListTile(title: Text('Item not found'));
          }
          MenuItem menuItem = snapshot.data!;
          return ListTile(
            title: Text(
              '${entry.numberOfItems} x ${menuItem.name} - ${entry.amount.toStringAsFixed(2)}€',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(entry.timestamp)),
            trailing: isAdmin ? IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(context, entry, refreshAndCloseDialog),
            ) : null,
          );
        },
      );
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, BalanceEntry entry, VoidCallback refreshDialog) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Room: $roomName'),
                Text('Guest: $guestSurname'),
                Text('Amount: €${entry.amount.toStringAsFixed(2)}'),
                Text('Date: ${DateFormat('dd/MM/yyyy').format(entry.timestamp)}'),
                const Text('Are you sure you want to delete this entry?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the confirmation dialog first
                bool success = await BalanceService.deleteBalanceEntry(entry.id);
                if (success) {
                  onRefresh(); // Refresh the main BillingView
                  refreshDialog(); // Refresh and reopen BillingDetailsDialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddPaymentDialog(BuildContext context, int reservationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddPaymentDialog(
          reservationId: reservationId,
          roomName: roomName,
          guestSurname: guestSurname,
          onPaymentAdded: onRefresh,
        );
      },
    );
  }
}


class AddPaymentDialog extends StatefulWidget {

  final int reservationId;
  final String roomName;
  final String guestSurname;
  final Function onPaymentAdded;

  AddPaymentDialog({required this.reservationId, required this.roomName, required this.guestSurname, required this.onPaymentAdded});

  @override
  _AddPaymentDialogState createState() => _AddPaymentDialogState();
}




class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'CASH';  // Default payment method
  double unpaidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUnpaidAmount();
  }

  void _fetchUnpaidAmount() async {
    double amount = await BalanceService.calculateUnpaidAmount(widget.reservationId);
    setState(() {
      unpaidAmount = amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Unpaid Amount: \$${unpaidAmount.toStringAsFixed(2)}'),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Payment Amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _paymentMethodSelector('CASH'),
                const SizedBox(width: 10),
                _paymentMethodSelector('CARD'),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(),
          child: const Text('Pay'),
        ),
      ],
    );
  }

  Widget _paymentMethodSelector(String method) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: _paymentMethod == method ? Colors.blue : Colors.white,
        primary: _paymentMethod == method ? Colors.white : Colors.blue,
      ),
      child: Text(method.toUpperCase()),
    );
  }


  void _processPayment() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot be empty')),
      );
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;

    // Check if the amount is greater than the unpaid amount, if so set the amount to the unpaid amount
    if(amount > unpaidAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount cannot be greater than unpaid amount')),
      );
      _amountController.text = unpaidAmount.toStringAsFixed(2);
      return;
    }

    // Confirmation dialogue
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Pay: ${amount.toStringAsFixed(2)}€ $_paymentMethod\nRoom: ${widget.roomName}\nGuest: ${widget.guestSurname}'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false), // returns false
          ),
          ElevatedButton(
            child: const Text('Confirm'),
            onPressed: () => Navigator.of(context).pop(true), // returns true
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return; // If the user cancels, stop the function here

    try {
      // Process the payment
      await BalanceService.addPayment(widget.reservationId, _paymentMethod, amount);
      // Handle successful payment addition
      widget.onPaymentAdded(); // Call the callback after processing the payment
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add payment: $e")),
      );
    }
  }

}
