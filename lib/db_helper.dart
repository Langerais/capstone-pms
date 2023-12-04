import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'dbObjects.dart';
import 'package:http/http.dart' as http;

// TODO: Save URL in a config file
const BASE_URL = 'http://16.16.140.209:5000';

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
}

class GuestService {
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

  static List<Guest> filterGuests(String searchText, List<Guest> allGuests) {
    return allGuests.where((guest) {
      return guest.name.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.surname.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.email.toLowerCase().contains(searchText.toLowerCase()) ||
          guest.phone.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }

}

class RoomService {
  static Future<List<Room>> getRooms() async {
    var url = Uri.parse('$BASE_URL/rooms/get_rooms');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Room.fromJson(json)).toList();
    } else {
      if (kDebugMode) {
        print('Failed to load rooms. Status code: ${response.statusCode}. Response body: ${response.body}');
      }
      throw Exception('Failed to load rooms');
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
    var url = Uri.parse('$BASE_URL/menu_management/get_item/$itemId');
    var response = await http.get(url);
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
    if (response.statusCode != 201) {
      throw Exception('Failed to add payment');
    }
  }

  static Future<List<BalanceEntry>> getBalanceEntriesForReservation(int reservationId) async {
    var url = Uri.parse('$BASE_URL/menu/get_balance_entries/$reservationId');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => BalanceEntry.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load balance entries for reservation $reservationId');
    }
  }

}







