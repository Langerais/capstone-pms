import 'package:capstone_pms/main.dart';
import 'test_db.dart';
import 'dart:convert';
import 'dbObjects.dart';
import 'package:http/http.dart' as http;


class ReservationService {
  static Future<List<Reservation>> getReservations() async {
    var url = Uri.parse('http://16.16.140.209:5000/reservations/get_reservations');
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
        'http://16.16.140.209:5000/reservations/get_guest_reservations/${guest
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
}

class GuestService {
  static Future<List<Guest>> getGuests() async {
    var url = Uri.parse('http://16.16.140.209:5000/guests/get_guests');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Guest.fromJson(json)).toList();
    } else {
      print('Failed to load guests. Status code: ${response.statusCode}. Response body: ${response.body}');
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
    var url = Uri.parse('http://16.16.140.209:5000/rooms/get_rooms');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = jsonDecode(response.body) as List;
      return jsonData.map((json) => Room.fromJson(json)).toList();
    } else {
      print('Failed to load rooms. Status code: ${response.statusCode}. Response body: ${response.body}');
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
    print("Date parsing error: $e");
    return null;
  }
}




