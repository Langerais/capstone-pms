import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'authentication.dart';
import 'db_helper.dart';
import 'dbObjects.dart';
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
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
            ],
          ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.today),
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
                      if (!unpaidAmountSnapshot.hasData) return CircularProgressIndicator();
                      double unpaidAmount = unpaidAmountSnapshot.data!;

                      return ListTile(
                        title: Text('${room?.name} - ${guest?.surname}'),
                        subtitle: Text('Check-out: ${DateFormat('yyyy-MM-dd').format(reservation.endDate)} - Due: \$${unpaidAmount.toStringAsFixed(2)}'),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => BillingDetailsDialog(
                              reservationId: reservation.id,
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
        // Handle errors
      }
      setState(() {});
    } catch (e) {
      // TODO: Handle errors
    }
  }

  // Start periodic fetch of reservations and guests
  void _startPeriodicFetch() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: REFRESH_TIMER), (Timer t) => fetchReservationsAndGuests());
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    print("Timer cancelled");
    super.dispose();
  }

}



class BillingDetailsDialog extends StatelessWidget {
  final int reservationId;
  final Function onRefresh; // Add this
  BillingDetailsDialog({required this.reservationId, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Billing Details'),
      content: FutureBuilder<List<BalanceEntry>>(
        future: BalanceService.getBalanceEntriesForReservation(reservationId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No billing details available.');
          }
          List<BalanceEntry> entries = snapshot.data!;
          entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Container(
            height: MediaQuery.of(context).size.height, /* subtract any additional padding or margins if needed */
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                BalanceEntry entry = entries[index];
                return _buildListItem(context, entry);
              },
            ),
          );
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () => _showAddPaymentDialog(context, reservationId),
          child: Text('Add Payment'),
        ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, BalanceEntry entry) { // Show order details for menu items and payment method for payments
    if (entry.menuItemId == 0 || entry.menuItemId == -1) {
      String paymentMethod = entry.menuItemId == 0 ? "cash" : "card";
      return ListTile(
        title: Text(
          'Payed $paymentMethod : ${entry.amount.toStringAsFixed(2)}€',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        subtitle: Text('${DateFormat('dd/MM/yyyy').format(entry.timestamp)}'),
      );
    }

    return FutureBuilder<MenuItem>(
      future: MenuService.getMenuItem(entry.menuItemId),
      builder: (context, itemSnapshot) {
        if (itemSnapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('Loading...'));
        }
        if (!itemSnapshot.hasData) {
          return ListTile(title: Text('Item not found'));
        }
        MenuItem menuItem = itemSnapshot.data!;
        return ListTile(
          title: Text('${menuItem.name} : ${entry.numberOfItems} : ${entry.amount.toStringAsFixed(2)}€'),
          subtitle: Text('${DateFormat('dd/MM/yyyy').format(entry.timestamp)}'),

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
          onPaymentAdded: onRefresh, // Use the callback here
        );
      },
    );
  }
}


class AddPaymentDialog extends StatefulWidget {
  final int reservationId;
  final Function onPaymentAdded;

  AddPaymentDialog({required this.reservationId, required this.onPaymentAdded});

  @override
  _AddPaymentDialogState createState() => _AddPaymentDialogState();
}



class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final TextEditingController _amountController = TextEditingController();
  String _paymentMethod = 'cash';  // Default payment method
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
      title: Text('Add Payment'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Unpaid Amount: \$${unpaidAmount.toStringAsFixed(2)}'),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Payment Amount'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _paymentMethodSelector('cash'),
                SizedBox(width: 10),
                _paymentMethodSelector('card'),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(),
          child: Text('Pay'),
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
      child: Text(method.toUpperCase()),
      style: OutlinedButton.styleFrom(
        backgroundColor: _paymentMethod == method ? Colors.blue : Colors.white,
        primary: _paymentMethod == method ? Colors.white : Colors.blue,
      ),
    );
  }


  void _processPayment() async {
    if (_amountController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Amount cannot be empty",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      );
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;

    if(amount > unpaidAmount) {
      Fluttertoast.showToast(
        msg: "Amount cannot be greater than unpaid amount",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
      );
      _amountController.text = unpaidAmount.toStringAsFixed(2);
      return;
    }

    try {
      // TODO: Confirm payment !!!!
      await BalanceService.addPayment(widget.reservationId, _paymentMethod, amount);
      // Handle successful payment addition
      widget.onPaymentAdded(); // Call the callback after processing the payment
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } catch (e) {
      Exception('Failed to add payment: $e');
    }
  }
}
