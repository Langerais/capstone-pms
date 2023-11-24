// artificial_database.dart

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

// Sample data
final List<Room> rooms = [
  Room(id: 1, name: '101'),
  Room(id: 2, name: '102'),
  Room(id: 3, name: '103'),
  Room(id: 4, name: '104'),
  Room(id: 5, name: '105'),
];

final List<Guest> guests = [
  Guest(id: 1, firstName: 'John', lastName: 'Doe', phone: '123456789', email: 'john@example.com'),
  Guest(id: 2, firstName: 'Jane', lastName: 'Smith', phone: '987654321', email: 'jane@example.com'),
  Guest(id: 3, firstName: 'Alice', lastName: 'Johnson', phone: '111223344', email: 'alice@example.com'),
  Guest(id: 4, firstName: 'Bob', lastName: 'Williams', phone: '555666777', email: 'bob@example.com'),
  Guest(id: 5, firstName: 'Eva', lastName: 'Anderson', phone: '999888777', email: 'eva@example.com'),
  Guest(id: 6, firstName: 'Michael', lastName: 'Brown', phone: '777888999', email: 'michael@example.com'),
  // Add more guests as needed
];

final List<Reservation> reservations = [
  Reservation(
    id: 1,
    roomId: 1,
    guestId: 1,
    startDate: DateTime.now().subtract(Duration(days: 2)),
    endDate: DateTime.now().add(Duration(days: 4)),
    costOfStay: 300.0,
  ),
  Reservation(
    id: 2,
    roomId: 3,
    guestId: 2,
    startDate: DateTime.now().add(Duration(days: 1)),
    endDate: DateTime.now().add(Duration(days: 8)),
    costOfStay: 250.0,
  ),
  Reservation(
    id: 3,
    roomId: 2,
    guestId: 3,
    startDate: DateTime.now().add(Duration(days: 3)),
    endDate: DateTime.now().add(Duration(days: 10)),
    costOfStay: 200.0,
  ),
  Reservation(
    id: 4,
    roomId: 4,
    guestId: 4,
    startDate: DateTime.now().add(Duration(days: 2)),
    endDate: DateTime.now().add(Duration(days: 9)),
    costOfStay: 280.0,
  ),
  Reservation(
    id: 5,
    roomId: 5,
    guestId: 5,
    startDate: DateTime.now().subtract(Duration(days: 1)),
    endDate: DateTime.now().add(Duration(days: 6)),
    costOfStay: 320.0,
  ),
  Reservation(
    id: 6,
    roomId: 1,
    guestId: 6,
    startDate: DateTime.now().add(Duration(days: 4)),
    endDate: DateTime.now().add(Duration(days: 11)),
    costOfStay: 180.0,
  ),
  // Add more reservations as needed
];
