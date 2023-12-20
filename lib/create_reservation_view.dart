import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'db_helper.dart';


/// CreateReservationView
///
/// This class is a StatefulWidget that manages the view for creating a new reservation.
/// It allows users to select a room, guest details, and reservation dates. It also handles
/// the logic for calculating the total due amount based on the price per night and date range.
///
class CreateReservationView extends StatefulWidget {
  final Function() onReservationCreated;

  CreateReservationView({required this.onReservationCreated});

  @override
  _CreateReservationViewState createState() => _CreateReservationViewState();
}

class _CreateReservationViewState extends State<CreateReservationView> {
  List<Room> availableRooms = []; // Stores available rooms for the selected date range
  Room? selectedRoom; // Currently selected room
  int? selectedGuestId; // ID of the selected guest (if existing guest is selected)
  int maxGuestsForSelectedRoom = 0;

  // Selected start and end date for the reservation
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now().add(const Duration(days: 1));

  // TextEditingControllers for handling form inputs
  TextEditingController nameController = TextEditingController();
  TextEditingController surnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController pricePerNightController = TextEditingController();

  // FocusNodes for handling focus of email and phone input fields
  FocusNode emailFocusNode = FocusNode();
  FocusNode phoneFocusNode = FocusNode();

  double totalDueAmount = 0.0; // Calculated total amount due for the reservation

  // Flags to indicate if the respective fields have been modified
  bool nameModified = false;
  bool surnameModified = false;
  bool emailModified = false;
  bool phoneModified = false;
  bool priceModified = false;

  // Variables to store the last checked email and phone for existing guest check
  String lastCheckedEmail = '';
  String lastCheckedPhone = '';

  String guestExistsMessage = ''; // Message displayed if an existing guest is found

  bool isExistingGuest = false; // Flag to indicate if an existing guest is selected
  List<Guest> guests = []; // Stores the list of guests for existing guest selection
  String searchQuery = ''; // Stores the query for searching guests

  /// getErrorText
  ///
  /// Helper function to get the error text for text fields based on their state.
  String? getErrorText(String text, bool modified, String errorMessage) {
    return (text.isEmpty && modified) ? errorMessage : null;
  }

  // Helper functions to validate email, phone, and price fields
  bool isEmailValid(String email) {
    if (email.isEmpty) return true;
    Pattern pattern = r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = RegExp(pattern as String);
    return regex.hasMatch(email);
  }

  bool isPhoneValid(String phone) {
    if (phone.isEmpty) return true;
    Pattern pattern = r'^[0-9+]+$';
    RegExp regex = RegExp(pattern as String);
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

    // Initialize the room selection and max guests
    updateAvailableRooms().then((_) {
      if (availableRooms.isNotEmpty) {
        setState(() {
          selectedRoom = availableRooms.first;
          maxGuestsForSelectedRoom = selectedRoom?.maxGuests ?? 0;
        });
      }
    });

    fetchAllGuests();
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes to free up resources
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    pricePerNightController.dispose();

    emailFocusNode.dispose();
    phoneFocusNode.dispose();
    super.dispose();
  }

  /// updateAvailableRooms
  ///
  /// Fetches available rooms based on the selected date range and updates the state.
  Future<void> updateAvailableRooms() async {
    // Fetch reservations for the selected date range
    List<Reservation> reservations = await ReservationService.getReservationsByDateRange(
        selectedStartDate.subtract(const Duration(days: 1)),
        selectedEndDate.add(const Duration(days: 1))
    );

    // Fetch all rooms
    List<Room> allRooms = await RoomService.getRooms();

    // Determine unavailable rooms based on existing reservations
    Set<int> unavailableRoomIds = reservations.where((reservation) {
      return !(reservation.endDate.isAtSameMomentAs(selectedStartDate) ||
          reservation.startDate.isAtSameMomentAs(selectedEndDate)) &&
          ((reservation.startDate.isBefore(selectedEndDate) && reservation.endDate.isAfter(selectedStartDate)));
    }).map((reservation) => reservation.roomId).toSet();

    // Update the state with available rooms and reset selected room
    setState(() {
      availableRooms = allRooms.where((room) => !unavailableRoomIds.contains(room.id)).toList();
      selectedRoom = availableRooms.isNotEmpty ? availableRooms.first : null;
    });
  }

  /// calculateTotalAmount
  ///
  /// Calculates the total amount due for the reservation based on price per night and date range.
  void calculateTotalAmount() {
    try {
      double pricePerNight = double.parse(pricePerNightController.text);
      int numberOfNights = selectedEndDate.difference(selectedStartDate).inDays + 1;
      setState(() {
        totalDueAmount = pricePerNight * numberOfNights;
      });
    } catch (e) {
      Exception('Failed to calculate total amount: $e');
    }
  }

  /// _selectDate
  ///
  /// Opens a date picker to select either the start or end date of the reservation.
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    DateTime firstDate = isStartDate ? DateTime.now() : selectedStartDate.add(const Duration(days: 1));
    DateTime initialDate = isStartDate ? selectedStartDate : selectedEndDate.isBefore(firstDate) ? firstDate : selectedEndDate;
    DateTime lastDate = DateTime.now().add(const Duration(days: 365 * 2));

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
          if (selectedEndDate.isBefore(selectedStartDate.add(const Duration(days: 1)))) {
            selectedEndDate = selectedStartDate.add(const Duration(days: 1));
          }
        } else {
          selectedEndDate = picked;
        }
        calculateTotalAmount();
        updateAvailableRooms();

        updateAvailableRooms().then((_) {
          if (availableRooms.isNotEmpty) {
            setState(() {
              selectedRoom = availableRooms.first;
              maxGuestsForSelectedRoom = selectedRoom?.maxGuests ?? 0;
            });
          }
        });
      });
    }
  }

  /// fetchAllGuests
  ///
  /// Fetches all guests for the existing guest selection functionality.
  void fetchAllGuests() async {
    try {
      guests = await GuestService.getGuests();
      setState(() {});
    } catch (e) {
      Exception('Failed to fetch guests: $e');
    }
  }

  /// searchGuests
  ///
  /// Handles the search functionality for existing guests.
  void searchGuests(String query) {
    setState(() {
      searchQuery = query;
    });
  }



  /// addReservation
  ///
  /// Adds a new reservation based on the form inputs.
  void addReservation() async {
    try {
      // Validation logic before adding a reservation
      if (selectedRoom == null) throw Exception("Room is not selected");
      if (selectedGuestId == null && (nameController.text.isEmpty || surnameController.text.isEmpty || emailController.text.isEmpty || phoneController.text.isEmpty || pricePerNightController.text.isEmpty)) {
        throw Exception("Guest details are incomplete");
      }

      if (guestExistsMessage == '') {
        double dueAmount = double.tryParse(pricePerNightController.text) ?? 0;
        if (dueAmount <= 0) throw Exception("Invalid price per night");

        int actualGuestId;
        if (selectedGuestId == null) {
          // Add a new guest if not an existing one
          Guest newGuest = await GuestService.addGuest(
            name: nameController.text,
            surname: surnameController.text,
            phone: phoneController.text,
            email: emailController.text,
          );
          actualGuestId = newGuest.id;
        } else {
          actualGuestId = selectedGuestId!;
        }

        // Check if room is available for the selected date range (Whether no other reservations appeared for the room and date range while the user was creating the reservation)
        List<Reservation> checkReservations = await ReservationService.getReservationsByRoomAndDateRange(selectedStartDate.add(Duration(days: 1)), selectedEndDate.subtract(Duration(days: 1)), selectedRoom!.id);
        if(checkReservations.isNotEmpty) {


          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room is not available for the selected date range')),
          );

          widget.onReservationCreated();
          Navigator.pop(context); // Navigate back to previous screen

          throw Exception("Room is not available for the selected date range");
        }

        await ReservationService.addReservation(
          startDate: selectedStartDate,
          endDate: selectedEndDate,
          roomId: selectedRoom!.id,
          guestId: actualGuestId,
          dueAmount: totalDueAmount,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully')),
        );

        widget.onReservationCreated();
        Navigator.pop(context); // Navigate back to previous screen
      } else {

      }
      // Show success message or navigate to another screen
    } catch (e) {
      // Show error message
      if (kDebugMode) {
        print("Error adding reservation: ${e.toString()}");
      }
    }
  }

  void cancelReservation() {
    Navigator.of(context).pop(); // Closes the current view
  }

  /// Checks if a guest already exists with the entered email or phone.
  /// Sets the `guestExistsMessage` state variable accordingly.
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
            'Guest already exists: ${existingGuest.name} ${existingGuest.surname};\nPlease select guest from "Existing Guest" list';
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Guest> filteredGuests = GuestService.filterGuests(searchQuery, guests);

    // Main build method of the widget, defining the layout and functionality of the UI.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reservation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: availableRooms.isNotEmpty
                      ? DropdownButtonFormField<Room>(
                    value: selectedRoom,
                    onChanged: (Room? newValue) {
                      setState(() {
                        selectedRoom = newValue;
                        maxGuestsForSelectedRoom = newValue?.maxGuests ?? 0; // Update max guests
                      });
                    },
                    items: availableRooms.map<DropdownMenuItem<Room>>((Room room) {
                      return DropdownMenuItem<Room>(
                        value: room,
                        child: Text(room.name),
                      );
                    }).toList(),
                    decoration: const InputDecoration(
                      labelText: 'Select Room',
                    ),
                  )
                      : const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'No available rooms for selected dates',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
                ),
                availableRooms.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Max Guests: $maxGuestsForSelectedRoom',
                          style: TextStyle(fontSize: 16),
                  ),
                )
                    : SizedBox.shrink(), // Hide the 'Max Guests' text when no rooms are available
              ],
            ),

            // Date pickers for start and end dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ListTile(
                    title: Text("Start Date: ${DateFormat('yyyy-MM-dd').format(selectedStartDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text("End Date: ${DateFormat('yyyy-MM-dd').format(selectedEndDate)}"),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context, false),
                  ),
                ),
              ],
            ),
            // Display the guest exists message, if any
            if (guestExistsMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(guestExistsMessage, style: const TextStyle(color: Colors.red)),
              ),
            // Switch to toggle between new and existing guest
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
            // Fields and list for handling new or existing guest details
            if (isExistingGuest) ...[
              TextField(
                controller: pricePerNightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 20),
              Text('Total Due Amount: €${totalDueAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              TextField(
                onChanged: searchGuests,
                decoration: const InputDecoration(
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
              TextField(
                controller: pricePerNightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              const SizedBox(height: 20),
              Text('Total Due Amount: €${totalDueAmount.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
            ],
            // Price per Night TextField

          ],
        ),
      ),
      // Floating action button for saving the reservation
      floatingActionButton: FloatingActionButton(
        onPressed: addReservation,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.save),
      ),
    );
  }
}
