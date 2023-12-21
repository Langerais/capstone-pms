import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'authentication.dart';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'config.dart';


class ReservationService {
  static Future<List<Reservation>> getReservations() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/get_reservations');
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<List<Reservation>> getReservationsForGuest(Guest guest) async {
    var url = Uri.parse(
        '${AppConfig.BASE_URL}/reservations/get_guest_reservations/${guest.id}');
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load reservations for guest ${guest.name} ${guest.surname}');
    }
  }

  static Future<List<Reservation>> getReservationsByDateRange(DateTime startDate, DateTime endDate) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/get_reservations_by_date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<List<Reservation>> getReservationsByRoomAndDateRange(DateTime startDate, DateTime endDate, int roomId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/get_reservations_by_room_and_date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'room_id': roomId.toString(),
    });
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Reservation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  static Future<void> addReservation({
    required DateTime startDate,
    required DateTime endDate,
    required int roomId,
    required int guestId,
    required double dueAmount,
  }) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/add_reservation');
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
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

  static Future<void> deleteReservation({
    required int reservationId,
  }) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/delete_reservation/$reservationId');
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reservation');
    }
  }

  static Future<void> changeReservationStatus({
    required int reservationId,
    required String newStatus,
  }) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/change_reservation_status/$reservationId');
    final token = await CrossPlatformTokenStorage.getToken();

    var response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to change reservation status');
    }
  }

  static Future<List<ReservationStatusChange>> getAllReservationStatusChanges() async {
    final url = Uri.parse('${AppConfig.BASE_URL}/reservations/get_reservation_status_changes');
    final token = await CrossPlatformTokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ReservationStatusChange.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reservation status changes');
    }
  }

  static Future<List<ReservationStatusChange>> getReservationStatusChangeByReservation(int reservationId) async {
    final url = Uri.parse('${AppConfig.BASE_URL}/reservations/get_reservation_status_changes/$reservationId');
    final token = await CrossPlatformTokenStorage.getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => ReservationStatusChange.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reservation status change');
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
    var url = Uri.parse('${AppConfig.BASE_URL}/guests/add_guest');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
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
    var url = Uri.parse('${AppConfig.BASE_URL}/guests/get_guests');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/guests/get_guest/$guestId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Guest.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load guest');
    }
  }


  static Future<List<Guest>> getGuestsByIds(List<int> guestIds) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/guests/get_guests_by_ids');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/guests/find_guest');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/rooms/get_rooms');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/rooms/get_room/$roomId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/get_categories');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/get_item/$itemId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MenuItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load menu item');
    }
  }

  static Future<List<MenuItem>> getMenuItemsByCategory(int categoryId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/get_items_by_category/$categoryId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => MenuItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load items for category $categoryId');
    }
  }

  static Future<void> addMenuItem(String name, int categoryId, String description, double price) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/create_item');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/modify_item/$itemId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/remove_item/$itemId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete menu item');
    }
  }

}


class BalanceService {

  static Future<BalanceEntry> createBalanceEntry(int reservationId, int menuItemId, double amount) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/create_balance_entry');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/create_balance_entry');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/add_payment');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/remove_balance_entry/$balanceEntryId');

    try {
      final token = await CrossPlatformTokenStorage.getToken();
      var response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/menu/get_balance_entries/$reservationId');

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;

      return jsonData.map((json) => BalanceEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load balance entries for reservation $reservationId');
    }
  }


  static Future<double> calculateUnpaidAmount(int reservationId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/reservations/calculate_unpaid_amount/$reservationId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

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
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/get_cleaning_schedule/room/$roomId/date_range')
        .replace(queryParameters: {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CleaningSchedule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cleaning schedule');
    }
  }

  static Future<List<CleaningAction>> getCleaningActions() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/get_cleaning_actions');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      List<CleaningAction> actions = jsonData.map((json) => CleaningAction.fromJson(json)).toList();
      return actions;
    } else {
      throw Exception('Failed to load cleaning actions');
    }
  }


  static Future<CleaningAction> getCleaningAction(int actionId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/get_cleaning_action/$actionId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return CleaningAction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load cleaning action');
    }
  }

  static Future<void> scheduleCleaning(DateTime startDate) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/schedule_cleaning');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'start_date': startDate.toIso8601String().split('T').first, // Formatting the date as 'YYYY-MM-DD'
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to schedule cleaning: ${response.body}');
    }

  }

  static Future<void> toggleCleaningTaskStatus(int scheduleId, String newStatus, String completedDate) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/toggle_task_status/$scheduleId');

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'completed_date': completedDate,
        'task_status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle task status. Error: ${response.body}');
    }
  }

  static Future<bool> createCleaningAction(String actionName, int frequencyDays) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/create_cleaning_action');

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'action_name': actionName,
        'frequency_days': frequencyDays,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateCleaningAction(int actionId, String actionName, int frequency) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/modify_cleaning_action/$actionId');

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'action_name': actionName,
        'frequency_days': frequency,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteCleaningAction(int actionId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/cleaning_management/remove_cleaning_action/$actionId');

    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

}

class LogService {

  // Get all logs
  static Future<List<Log>> getLogs() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/get_logs');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

  static Future<List<String>> getUniqueActions() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/actions');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<String> actions = List<String>.from(json.decode(response.body));
      return actions;
    } else {
      throw Exception('Failed to load actions');
    }
  }

  static Future<List<Log>> getLogsForAction(String action) async { // TODO: Implement Endpoint
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/action/$action');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

  static Future<List<Log>> getLogsForDateRange(DateTime startDate, DateTime endDate) async {

    String start = startDate.toIso8601String();
    String end = endDate.toIso8601String();
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/date_range/$start/$end');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }


  static Future<List<Log>> getLogsForUser(int userId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/user/$userId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

  // Get logs for a specific user, for a specific date range
  static Future<List<Log>> getLogsForUserAndDateRange(DateTime startDate, DateTime endDate, int userId) async {
    String start = startDate.toIso8601String();
    String end = endDate.toIso8601String();
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/user/$userId/date_range/$start/$end');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

 // Get logs for a specific user, for a specific action
  static Future<List<Log>> getLogsForUserAndAction(String action, int userId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/logging/user/$action/action/$userId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> logsJson = json.decode(response.body);
      return logsJson.map((json) => Log.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load logs');
    }
  }

  static Future<List<dynamic>> fetchLogs({
    String? startDate,
    String? endDate,
    String? action,
    int? userId,
    String? details,
  }) async {
    var queryParams = {
      'start_date': startDate,
      'end_date': endDate,
      'action': action,
      'user_id': userId?.toString(),
      'details': details,
    };


    // Remove null entries
    queryParams.removeWhere((key, value) => value == null);

    var uri = Uri.parse('${AppConfig.BASE_URL}/logging/search_logs').replace(queryParameters: queryParams);
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load logs');
    }
  }

}

class UsersService {

  static Future<void> createUser({
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String department,
    required String password,
  }) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/user_management/create_user');
    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'department': department,
        'password': password,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create User');
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.BASE_URL}/registration/register'); // Update with your actual server URL

    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'email': email,
        'phone': phone,
        'password': password,
        'department': 'Pending', // Department is set to 'Pending' by default
      }),
    );

    if (response.statusCode == 201) {
      // User created successfully
      return {'success': true, 'message': json.decode(response.body)['msg']};
    } else {
      // Error occurred
      return {'success': false, 'message': json.decode(response.body)['msg']};
    }
  }

  static Future<void> modifyUser({
    required int userId,
    required String name,
    required String surname,
    required String phone,
    required String email,
    required String department,
  }) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/modify_user/$userId');
    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'phone': phone,
        'email': email,
        'department': department,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to modify User');
    }
  }

  static Future<void> changeDepartment(int userId, String department) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/change_department/$userId');
    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'department': department,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change User department');
    }
  }

  static Future<User> getUser(int userId) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/get_user/$userId');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  static Future<User> getUserByEmail(String email) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/get_user_by_email/$email');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      User user = User.fromJson(jsonDecode(response.body));
      print("User: ${user.name}");
      return user;
    } else {
      throw Exception('Failed to load user');
    }
  }

  static Future<List<User>> getUsers() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/get_users');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Handle the response
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Users');
    }
  }

  static Future<List<User>> getUsersByDepartment(String department) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/get_users_by_department/$department');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Users by $department department');
    }
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/change_password/');
    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      String message = responseBody['msg'] ?? 'Failed to update password';
      throw Exception(message);
    }
  }

  static Future<void> changePasswordManager(int userId, String managerPassword, String newPassword) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/change_password_manager/$userId');
    String? token = await CrossPlatformTokenStorage.getToken();
    var response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        'manager_password': managerPassword,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      Map<String, dynamic> responseBody = json.decode(response.body);
      String message = responseBody['msg'] ?? 'Failed to update password';
      throw Exception(message);
    }
  }

  static Future<List<Department>> getAllDepartments() async {
    var url = Uri.parse('${AppConfig.BASE_URL}/users/get_all_departments');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> departmentJsonList = jsonDecode(response.body);
      final List<Department> departments = departmentJsonList
          .map((dynamic json) => Department.fromJson(json))
          .toList();
      return departments;
    } else {
      throw Exception('Failed to fetch departments');
    }
  }

}


class TimeZoneService {

  static String _timezone = 'UTC'; // Default timezone

  static Future<String?> fetchTimezone() async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.BASE_URL}/get_timezone'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _timezone = data['timezone'];
        return _timezone;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load timezone: $e');
      }
      return null; // Or handle as appropriate
    }
  }

}

class AppNotificationsService {

  static Future<List<AppNotification>> getAppNotifications() async {

    var url = Uri.parse('${AppConfig.BASE_URL}/notifications/get_notifications');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => AppNotification.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<List<AppNotification>> getAppNotificationsByDepartment(String department) async {
    var url = Uri.parse('${AppConfig.BASE_URL}/notifications/get_notifications/department/$department');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => AppNotification.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }


  static Future<void> createNotification(AppNotification notification) async {
    final url = Uri.parse('${AppConfig.BASE_URL}/notifications/add_notification');
    final token = await CrossPlatformTokenStorage.getToken();
    var response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(notification.toJson()),
    );

    if (response.statusCode == 201) {
      // Notification created successfully
      return;
    } else {
      // Error occurred
      throw Exception('Failed to create notification');
    }
  }
}







