import 'package:flutter/foundation.dart';

class Room {
  final int id;
  final String name;
  final String channelManagerId;

  Room({
    required this.id,
    required this.name,
    required this.channelManagerId
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      name: json['room_name'] as String? ?? 'Unknown Name',
      channelManagerId: json['channel_manager_id'] as String? ?? 'Unknown Channel Manager ID',
    );
  }
}



class Reservation {
  final int id;
  final String channelManagerId;
  final int roomId;
  final int guestId;
  final DateTime startDate;
  final DateTime endDate;
  final double dueAmount;

  Reservation({
    required this.id,
    required this.channelManagerId,
    required this.roomId,
    required this.guestId,
    required this.startDate,
    required this.endDate,
    required this.dueAmount
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    //DateFormat dateFormat = DateFormat('E, dd MMM yyyy HH:mm:ss \'GMT\'');

    return Reservation(
      id: json['id'] as int,
      channelManagerId: json['channel_manager_id'] as String,
      roomId: json['room_id'] as int,
      guestId: json['guest_id'] as int,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      dueAmount: json['due_amount'] != null ? double.parse(json['due_amount']) : 0.0,

    );
  }

  String get formattedDueAmount {
    return dueAmount.toStringAsFixed(2);
  }
}

DateTime? parseCustomDateFormat(String dateString) {
  try {
    // Split the date string by spaces and colons
    final parts = dateString.split(RegExp(r'[: ]'));
    // The parts array should look like [DayName, DD, Month, YYYY, HH, MM, SS, 'GMT']
    if (parts.length != 8) return null;

    final day = int.parse(parts[1]);
    final month = _monthToInt(parts[2]);
    final year = int.parse(parts[3]);
    final hour = int.parse(parts[4]);
    final minute = int.parse(parts[5]);
    final second = int.parse(parts[6]);

    return DateTime.utc(year, month, day, hour, minute, second);
  } catch (e) {
    if (kDebugMode) {
      print("Error parsing date: $e");
    }  // For debugging
    return null;
  }
}

int _monthToInt(String month) {
  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  return months[month] ?? 1; // Default to January if month is unknown
}

class Guest {
  final int id;
  final String channelManagerId;
  final String name;
  final String surname;
  final String phone;
  final String email;

  Guest({
    required this.id,
    required this.channelManagerId,
    required this.name,
    required this.surname,
    required this.phone,
    required this.email,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] as int,
      channelManagerId: json['channel_manager_id'] as String? ?? "Unknown Channel Manager ID",
      name: json['name'] as String? ?? "Unknown First Name",
      surname: json['surname'] as String? ?? "Unknown Last Name",
      phone: json['phone'] as String? ?? "Unknown Phone Number",
      email: json['email'] as String? ?? "Unknown Email Address",
    );
  }

}


class MenuCategory {
  final int id;
  final String name;

  MenuCategory({required this.id, required this.name});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class MenuItem {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double price;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] != null ? double.parse(json['price']) : 0.0,

    );
  }

}

class BalanceEntry {
  final int id;
  final int reservationId;
  final int menuItemId; // 0 for cash payments, -1 for credit card payments
  final double amount;
  final int numberOfItems;
  final DateTime timestamp;

  BalanceEntry({
    required this.id,
    required this.reservationId,
    required this.menuItemId,
    required this.amount,
    required this.numberOfItems,
    required this.timestamp,
  });

  factory BalanceEntry.fromJson(Map<String, dynamic> json) {
    return BalanceEntry(
      id: json['id'] as int,
      reservationId: json['reservation_id'] as int,
      menuItemId: json['menu_item_id'] as int,
      amount: json['amount'] != null ? double.parse(json['amount']) : 0.0,
      numberOfItems: json['number_of_items'] as int? ?? 1,  // Default to 1 if not provided
      timestamp: DateTime.parse(json['transaction_timestamp']),
    );
  }
}

