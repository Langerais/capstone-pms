import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import 'dbObjects.dart';
import 'package:http/http.dart' as http;

// TODO: Save URL in a config file
const BASE_URL = 'http://16.16.140.209:5000';  //TODO: Move to config file
const REFRESH_TIMER = 600;  // Refresh db every X seconds TODO: Move to config file

class ReservationService {
  static Future<List<Reservation>> getReservations() async {
    var url = Uri.parse('$BASE_URL/reservations/get_reservations');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<List<Reservation>> getReservationsForGuest(Guest guest) async {
    var url = Uri.parse(
        '$BASE_URL/reservations/get_guest_reservations/${guest
            .id}');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load reservations for guest ${guest.name} ${guest
              .surname}');
    }
  }


  static Future<List<Reservation>> getReservationsByDateRange(DateTime startDate, DateTime endDate) async {
    var url = Uri.parse('$BASE_URL/reservations/get_reservations_by_date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<List<Reservation>> getReservationsByRoomAndDateRange(DateTime startDate, DateTime endDate, int roomId) async {
    var url = Uri.parse('$BASE_URL/reservations/get_reservations_by_room_and_date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'room_id': roomId.toString(),
    });

    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<void> addReservation({
    //required String channelManagerId,
    required DateTime startDate,
    required DateTime endDate,
    required int roomId,
    required int guestId,
    required double dueAmount,
  }) async {
    var url = Uri.parse('$BASE_URL/reservations/add_reservation');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        // 'channel_manager_id': channelManagerId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'room_id': roomId,
        'guest_id': guestId,
        'due_amount': dueAmount,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add reservation');
    }
  }

}

class GuestService {

  static Future<Guest> addGuest({
    //required String channelManagerId,
    required String name,
    required String surname,
    required String phone,
    required String email,
  }) async {
    var url = Uri.parse('$BASE_URL/guests/add_guest');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        //'channel_manager_id': channelManagerId,
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
      }),
    );

    if (response.statusCode == 201) {
      var jsonData = jsonDecode(response.body);
      return Guest.fromJson(jsonData);
    } else {
      throw Exception('Failed to add guest');
    }
  }

  static Future<List<Guest>> getGuests() async {
    var url = Uri.parse('$BASE_URL/guests/get_guests');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Guest.fromJson(json)).toList();
    } else {
      if (kDebugMode) {
        print('Failed to load guests. Status code: ${response.statusCode}. Response body: ${response.body}');
      }
      throw Exception('Failed to load guests');
    }
  }


  static Future<Guest> getGuest(int guestId) async {
    var url = Uri.parse('$BASE_URL/guests/get_guest/$guestId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return Guest.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guest');
    }
  }


  static Future<List<Guest>> getGuestsByIds(List<int> guestIds) async {
    var url = Uri.parse('$BASE_URL/guests/get_guests_by_ids');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'guest_ids': guestIds}),
    );
    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Guest.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load guests');
    }
  }


  static List<Guest> filterGuests(String searchText, List<Guest> allGuests) {
    return allGuests.where((guest) {
      return guest.name.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.surname.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.email.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.phone.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }


  static Future<Guest?> findGuestByEmailOrPhone(String email, String phone) async {
    var url = Uri.parse('$BASE_URL/guests/find_guest');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'email': email, 'phone': phone}),
    );
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body);
      return jsonData != null ? Guest.fromJson(jsonData) : null;
    } else {
      throw Exception('Failed to find guest');
    }
  }

}

class RoomService {
  static Future<List<Room>> getRooms() async {
    var url = Uri.parse('$BASE_URL/rooms/get_rooms');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      List<Room> rooms = jsonData.map((json) => Room.fromJson(json)).toList();
      rooms.sort((a, b) => a.name.compareTo(b.name));  // Sort rooms by name
      return rooms;
    } else {
      if (kDebugMode) {
        print('Failed to load rooms. Status code: ${response.statusCode}. Response body: ${response.body}');
      }
      throw Exception('Failed to load rooms');
    }
  }

  static Future<Room> getRoom(int roomId) async {
    var url = Uri.parse('$BASE_URL/rooms/get_room/$roomId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return Room.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load room');
    }
  }


}

DateTime? parseDate(String dateString) {
  try {
    // Extracting date parts
    var parts = dateString.split(' ');
    var day = parts[1];
    var month = parts[2];
    var year = parts[3];
    var timeParts = parts[4].split(':');
    var hours = timeParts[0];
    var minutes = timeParts[1];
    var seconds = timeParts[2];

    // Converting month to a number
    var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    var monthNumber = months.indexOf(month) + 1;

    // Creating a new DateTime object
    return DateTime.parse('$year-$monthNumber-$day $hours:$minutes:$seconds');
  } catch (e) {
    if (kDebugMode) {
      print("Date parsing error: $e");
    }
    return null;
  }
}

class MenuCategoryService {
  static Future<List<MenuCategory>> getMenuCategories() async {
    var url = Uri.parse('$BASE_URL/menu/get_categories');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => MenuCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load menu categories');
    }
  }
}

class MenuService {
  static Future<MenuItem> getMenuItem(int itemId) async {
    var url = Uri.parse('$BASE_URL/menu/get_item/$itemId');
    var response = await http.get(url);
    print(MenuItem.fromJson(jsonDecode(response.body)));
    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load menu item');
    }
  }

  static Future<List<MenuItem>> getMenuItemsByCategory(int categoryId) async {
    var url = Uri.parse('$BASE_URL/menu/get_items_by_category/$categoryId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => MenuItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items for category $categoryId');
    }
  }

  static Future<void> addMenuItem(String name, int categoryId, String description, double price) async {
    var url = Uri.parse('$BASE_URL/menu/create_item');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add menu item');
    }
  }

  static Future<void> updateMenuItem(int itemId, String name, int categoryId, String description, double price) async {
    var url = Uri.parse('$BASE_URL/menu/modify_item/$itemId');
    var response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'name': name,
        'category_id': categoryId,
        'description': description,
        'price': price,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update menu item');
    }
  }

  static Future<void> deleteMenuItem(int itemId) async {
    var url = Uri.parse('$BASE_URL/menu/remove_item/$itemId');
    var response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu item');
    }
  }

}


class BalanceService {

  static Future<BalanceEntry> createBalanceEntry(int reservationId, int menuItemId, double amount) async {
    var url = Uri.parse('$BASE_URL/menu/create_balance_entry');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'reservation_id': reservationId,
        'menu_item_id': menuItemId,
        'amount': amount,
      }),
    );
    if (response.statusCode == 201) {
      return BalanceEntry.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create balance entry');
    }
  }

  static Future<void> addOrder(int reservationId, int menuItemId, int quantity, double pricePerItem) async {
    var url = Uri.parse('$BASE_URL/menu/create_balance_entry');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'reservation_id': reservationId,
        'menu_item_id': menuItemId,
        'amount': (pricePerItem * quantity),  // Calculate total amount
        'number_of_items': quantity,  // Include quantity as number of items
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add order');
    }
  }


  static Future<void> addPayment(int reservationId, String paymentMethod, double amount) async {
    var url = Uri.parse('$BASE_URL/menu/add_payment');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'reservation_id': reservationId,
        'payment_method': paymentMethod,
        'payment_amount': amount,
      }),
    );
    print(response.body);
    if (response.statusCode != 201) {
      throw Exception('Failed to add payment');
    }
  }

  static Future<bool> deleteBalanceEntry(int balanceEntryId) async {
    final String url = '$BASE_URL/menu/remove_balance_entry/$balanceEntryId';

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "Balance entry removed successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return true; // Successfully deleted
      } else {
        Fluttertoast.showToast(
          msg: "Error removing balance entry: ${response.body}",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return false; // Failed to delete
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return false; // Error occurred
    }
  }

  static Future<List<BalanceEntry>> getBalanceEntriesForReservation(int reservationId) async {
    var url = Uri.parse('$BASE_URL/menu/get_balance_entries/$reservationId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      print(jsonData);
      print(jsonData.length);
      return jsonData.map((json) => BalanceEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load balance entries for reservation $reservationId');
    }
  }


  static Future<double> calculateUnpaidAmount(int reservationId) async {
    var url = Uri.parse('$BASE_URL/reservations/calculate_unpaid_amount/$reservationId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return double.parse(data['unpaid_amount']);
    } else {
      throw Exception('Failed to calculate unpaid amount');
    }
  }

}


class CleaningService {
  static Future<List<CleaningSchedule>> getRoomCleaningSchedule(int roomId, DateTime startDate, DateTime endDate) async {
    var url = Uri.parse('$BASE_URL/cleaning_management/get_cleaning_schedule/room/$roomId/date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });

    var response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CleaningSchedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cleaning schedule');
    }
  }

  static Future<List<CleaningAction>> getCleaningActions() async {
    var url = Uri.parse('$BASE_URL/cleaning_management/get_cleaning_actions');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      List<CleaningAction> actions = jsonData.map((json) => CleaningAction.fromJson(json)).toList();
      return actions;
    } else {
      throw Exception('Failed to load cleaning actions');
    }
  }


  static Future<CleaningAction> getCleaningAction(int actionId) async {
    var url = Uri.parse('$BASE_URL/cleaning_management/get_cleaning_action/$actionId');
    var response = await http.get(url);
    print(CleaningAction.fromJson(jsonDecode(response.body)));
    if (response.statusCode == 200) {
      return CleaningAction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load cleaning action');
    }
  }

  static Future<void> scheduleCleaning(DateTime startDate) async {
    var url = Uri.parse('$BASE_URL/cleaning_management/schedule_cleaning');
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'start_date': startDate.toIso8601String().split('T').first, // Formatting the date as 'YYYY-MM-DD'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to schedule cleaning: ${response.body}');
    }

  }

  static Future<void> toggleCleaningTaskStatus(int scheduleId, String newStatus, String completedDate) async {
    var url = Uri.parse('$BASE_URL/cleaning_management/toggle_task_status/$scheduleId');

    //DateTime completed = DateFormat('yyyy-MM-dd HH:mm').format(completedDate);
    //String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(completedDate);
    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'id': scheduleId,
        'completed_date': completedDate,
        'task_status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle task status. Error: ${response.body}');
    }
  }

  static Future<bool> createCleaningAction(String actionName, int frequencyDays) async {
    final response = await http.post(
      Uri.parse('$BASE_URL/cleaning_management/create_cleaning_action'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'action_name': actionName,
        'frequency_days': frequencyDays,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateCleaningAction(int actionId, String actionName, int frequency) async {
    final response = await http.put(
      Uri.parse('$BASE_URL/cleaning_management/modify_cleaning_action/$actionId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'action_name': actionName,
        'frequency_days': frequency,
      }),
    );

    print("Send: " + actionId.toString() + " " + actionName.toString() + " " + frequency.toString());
    return response.statusCode == 200;
  }

  static Future<bool> deleteCleaningAction(int actionId) async {
    final response = await http.delete(
      Uri.parse('$BASE_URL/cleaning_management/remove_cleaning_action/$actionId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    return response.statusCode == 200;
  }

}







