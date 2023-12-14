import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'dbObjects.dart';
import 'db_helper.dart';

class CreateReservationView extends StatefulWidget {
  @override
  _CreateReservationViewState createState() => _CreateReservationViewState();
}

class _CreateReservationViewState extends State<CreateReservationView> {
  List<Room> availableRooms = [];
  Room? selectedRoom;
  int? selectedGuestId;

  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now().add(Duration(days: 1));

  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController pricePerNightController = TextEditingController();

  FocusNode emailFocusNode = FocusNode();
  FocusNode phoneFocusNode = FocusNode();

  double totalDueAmount = 0.0;

  bool nameModified = false;
  bool surnameModified = false;
  bool emailModified = false;
  bool phoneModified = false;
  bool priceModified = false;

  String lastCheckedEmail = '';
  String lastCheckedPhone = '';

  String guestExistsMessage = '';

  bool isExistingGuest = false;
  List<Guest> guests = [];
  String searchQuery = '';

  String? getErrorText(String text, bool modified, String errorMessage) {
    if (text.isEmpty && modified) {
      return errorMessage;
    }
    return null;
  }

  bool isEmailValid(String email) {
    if (email.isEmpty) return true;
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern as String);
    return regex.hasMatch(email);
  }

  bool isPhoneValid(String phone) {
    if (phone.isEmpty) return true;
    Pattern pattern = r'^[0-9+]+$';
    RegExp regex = new RegExp(pattern as String);
    return regex.hasMatch(phone);
  }

  bool isPriceValid(String price) {
    if (price.isEmpty) return true;
    double? priceVal = double.tryParse(price);
    return priceVal != null && priceVal > 0;
  }


  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(() {
      if (!emailFocusNode.hasFocus) {
        checkForExistingGuest();
      }
    });
    phoneFocusNode.addListener(() {
      if (!phoneFocusNode.hasFocus) {
        checkForExistingGuest();
      }
    });
    updateAvailableRooms();
    fetchAllGuests();
  }

  void onFieldFocusChange() {
    if (!emailFocusNode.hasFocus || !phoneFocusNode.hasFocus) {
      // Call the function to check for existing guest when focus is lost
      checkForExistingGuest();
    }
  }

  @override
  void dispose() {
    // Dispose text editing controllers
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    pricePerNightController.dispose();

    // Dispose focus nodes
    emailFocusNode.dispose();
    phoneFocusNode.dispose();

    super.dispose();
  }

  void updateAvailableRooms() async {
    List<Reservation> reservations = await ReservationService.getReservationsByDateRange(
        selectedStartDate.subtract(Duration(days: 1)),
        selectedEndDate.add(Duration(days: 1))
    );

    List<Room> allRooms = await RoomService.getRooms();

    Set<int> unavailableRoomIds = reservations.where((reservation) {
      // A room is unavailable if the existing reservation overlaps with the selected date range,
      // excluding cases where an existing reservation ends on the selected start date
      // or starts on the selected end date.
      return !(reservation.endDate.isAtSameMomentAs(selectedStartDate) ||
          reservation.startDate.isAtSameMomentAs(selectedEndDate)) &&
          ((reservation.startDate.isBefore(selectedEndDate) && reservation.endDate.isAfter(selectedStartDate)));
    }).map((reservation) => reservation.roomId).toSet();

    setState(() {
      availableRooms = allRooms.where((room) => !unavailableRoomIds.contains(room.id)).toList();
      selectedRoom = availableRooms.isNotEmpty ? availableRooms.first : null;
    });
  }



  void calculateTotalAmount() {
    try {
      double pricePerNight = double.parse(pricePerNightController.text);
      int numberOfNights = selectedEndDate.difference(selectedStartDate).inDays + 1;
      setState(() {
        totalDueAmount = pricePerNight * numberOfNights;
      });
    } catch (e) {
      // Handle parsing error
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime firstDate = isStartDate ? DateTime.now() : selectedStartDate.add(Duration(days: 1));
    DateTime initialDate = isStartDate ? selectedStartDate : selectedEndDate.isBefore(firstDate) ? firstDate : selectedEndDate;
    DateTime lastDate = DateTime.now().add(Duration(days: 365));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
          // Adjust end date if it's before the new start date
          if (selectedEndDate.isBefore(selectedStartDate.add(Duration(days: 1)))) {
            selectedEndDate = selectedStartDate.add(Duration(days: 1));
          }
        } else {
          selectedEndDate = picked;
        }
        calculateTotalAmount();
        updateAvailableRooms(); // Update available rooms based on the new date range
      });
    }
  }


  void fetchAllGuests() async {
    try {
      guests = await GuestService.getGuests();
      setState(() {});
    } catch (e) {
      // Handle exception
    }
  }

  void searchGuests(String query) {
    setState(() {
      searchQuery = query;
    });
  }


  void addReservation() async {
    try {
      // Validate all fields before proceeding
      if (selectedRoom == null) throw Exception("Room is not selected");
      if (selectedGuestId == null && (nameController.text.isEmpty || surnameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty || pricePerNightController.text.isEmpty)) {
        throw Exception("Guest details are incomplete");
      }

      if(guestExistsMessage == '') {
        double dueAmount = double.tryParse(pricePerNightController.text) ?? 0;
        if (dueAmount <= 0) throw Exception("Invalid price per night");

        int actualGuestId; // Local variable to hold the non-nullable guest ID

        if (selectedGuestId == null) {
          Guest newGuest = await GuestService.addGuest(
            name: nameController.text,
            surname: surnameController.text,
            phone: phoneController.text,
            email: emailController.text,
          );
          actualGuestId = newGuest.id; // Use the new guest's ID
        } else {
          actualGuestId =
          selectedGuestId!; // Use the existing non-null guest ID
        }


        // Check if room is available for the selected date range (Whether no other reservations appeared for the room and date range while the user was creating the reservation)
        List<Reservation> checkReservations = await ReservationService.getReservationsByRoomAndDateRange(selectedStartDate, selectedEndDate, selectedRoom!.id);
        if(checkReservations.isNotEmpty) {

          Fluttertoast.showToast(
              msg: "Room is not available for the selected date range",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0
          );

          Navigator.pop(context); // Navigate back to previous screen

          throw Exception("Room is not available for the selected date range");
        }

        await ReservationService.addReservation(
          startDate: selectedStartDate,
          endDate: selectedEndDate,
          roomId: selectedRoom!.id,
          guestId: actualGuestId,
          dueAmount: dueAmount,
        );

        Fluttertoast.showToast(
            msg: "Reservation Created Successfully",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0
        );

        Navigator.pop(context); // Navigate back to previous screen
      } else {

      }
      // Show success message or navigate to another screen
    } catch (e) {
      // Show error message
      print("Error adding reservation: ${e.toString()}");
    }
  }

  void cancelReservation() {
    Navigator.of(context).pop(); // Closes the current view
  }

  void pickGuest() {
    // Navigate to view for picking an existing guest
    // Implement logic to handle guest selection
  }



  void checkForExistingGuest() async {

    String currentEmail = emailController.text;
    String currentPhone = phoneController.text;

    // Check if either email or phone has changed since the last check
    if (currentEmail != lastCheckedEmail || currentPhone != lastCheckedPhone) {
      lastCheckedEmail = currentEmail;
      lastCheckedPhone = currentPhone;

      try {
        Guest? existingGuest = await GuestService.findGuestByEmailOrPhone(
            emailController.text, phoneController.text);
        if (existingGuest != null) {
          setState(() {
            guestExistsMessage =
            'Guest already exists: ${existingGuest.name} ${existingGuest
                .surname};\nPlease select guest from "Existing Guest" list';
          });
        } else {
          setState(() {
            guestExistsMessage = ''; // Clear the message if no guest is found
          });
        }
      } catch (e) {
        setState(() {
          guestExistsMessage = ''; // Clear the message in case of an exception
        });
        // You might want to handle this exception differently, e.g., logging
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    List<Guest> filteredGuests = GuestService.filterGuests(searchQuery, guests);


    return Scaffold(
      appBar: AppBar(
        title: Text('Create Reservation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<Room>(
              value: selectedRoom,
              onChanged: (Room? newValue) {
                setState(() {
                  selectedRoom = newValue;
                });
              },
              items: availableRooms.map<DropdownMenuItem<Room>>((Room room) {
                return DropdownMenuItem<Room>(
                  value: room,
                  child: Text(room.name),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select Room',
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ListTile(
                    title: Text("Start Date: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text("End Date: ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            // Display the guest exists message, if any
            if (guestExistsMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(guestExistsMessage, style: TextStyle(color: Colors.red)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Text('New Guest', textAlign: TextAlign.right),
                  ),
                ),
                Switch(
                  value: isExistingGuest,
                  onChanged: (bool value) {
                    setState(() {
                      isExistingGuest = value;
                    });
                  },
                ),
                const Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Text('Existing Guest', textAlign: TextAlign.left),
                  ),
                ),
              ],
            ),

            if (isExistingGuest) ...[
              TextField(
                onChanged: searchGuests,
                decoration: InputDecoration(
                  labelText: 'Search Guests',
                  suffixIcon: Icon(Icons.search),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: filteredGuests.length,
                itemBuilder: (context, index) {
                  Guest guest = filteredGuests[index];
                  bool isSelected = guest.id == selectedGuestId;

                  return ListTile(
                    title: Text('${guest.name} ${guest.surname}'),
                    subtitle: Text('${guest.email} - ${guest.phone}'),
                    tileColor: isSelected ? Colors.grey[300] : null,
                    onTap: () {
                      setState(() {
                        selectedGuestId = guest.id; // Update selected guest ID
                      });
                    },
                  );
                },
              ),
            ] else ...[
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Guest Name',
                  errorText: getErrorText(nameController.text, nameModified, 'Name is required'),
                ),
                onChanged: (value) {
                  setState(() {
                    nameModified = true;
                  });
                },
              ),
              TextField(
                controller: surnameController,
                decoration: InputDecoration(
                  labelText: 'Guest Surname',
                  errorText: getErrorText(surnameController.text, surnameModified, 'Surname is required'),
                ),
                onChanged: (value) {
                  setState(() {
                    surnameModified = true;
                  });
                },
              ),
              // Email TextField
              TextField(
                controller: emailController,
                focusNode: emailFocusNode,
                decoration: InputDecoration(
                  labelText: 'Guest Email',
                  errorText: emailController.text.isNotEmpty
                      ? (isEmailValid(emailController.text) ? null : 'Enter a valid email')
                      : getErrorText(emailController.text, emailModified, 'Email is required'),
                ),
                onEditingComplete: () {
                  if (emailController.text.isNotEmpty || phoneController.text.isNotEmpty) {
                    checkForExistingGuest();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    emailModified = true;
                    guestExistsMessage = ''; // Reset the message when editing
                  });
                },
              ),
              // Phone TextField
              TextField(
                controller: phoneController,
                focusNode: phoneFocusNode,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')), // Allow only numbers and '+'
                ],
                decoration: InputDecoration(
                  labelText: 'Guest Phone',
                  errorText: phoneController.text.isNotEmpty
                      ? (isPhoneValid(phoneController.text) ? null : 'Enter a valid phone number')
                      : getErrorText(phoneController.text, phoneModified, 'Phone is required'),
                ),
                onEditingComplete: () {
                  if (emailController.text.isNotEmpty || phoneController.text.isNotEmpty) {
                    checkForExistingGuest();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    phoneModified = true;
                    guestExistsMessage = ''; // Reset the message when editing
                  });
                },
              ),
            ],
            // Price per Night TextField
            TextField(
              controller: pricePerNightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Allow only numbers and '.'
              ],
              decoration: InputDecoration(
                labelText: 'Price per Night',
                errorText: pricePerNightController.text.isNotEmpty
                    ? (isPriceValid(pricePerNightController.text) ? null : 'Enter a valid price')
                    : getErrorText(pricePerNightController.text, priceModified, 'Price per night is required'),
              ),
              onChanged: (value) {
                setState(() {
                  priceModified = true;
                  calculateTotalAmount();
                  if(pricePerNightController.text.isEmpty) {
                    totalDueAmount = 0.0;
                  }
                }
                );
              },
            ),
            SizedBox(height: 20),
            Text('Total Due Amount: €${totalDueAmount.toStringAsFixed(2)}'),
            SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addReservation,
        child: Icon(Icons.save),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
