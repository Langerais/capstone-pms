

class Room {
  final int id;
  final String name;

  Room({required this.id, required this.name});
}

class Reservation {
  final int id;
  final int roomId;
  final int guestId;
  final DateTime startDate;
  final DateTime endDate;
  final double costOfStay;

  Reservation({
    required this.id,
    required this.roomId,
    required this.guestId,
    required this.startDate,
    required this.endDate,
    required this.costOfStay,
  });
}

class Guest {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;

  Guest({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
  });

}