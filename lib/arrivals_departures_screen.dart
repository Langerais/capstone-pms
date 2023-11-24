import 'package:capstone_pms/drawer_menu.dart';
import 'package:capstone_pms/main.dart';
import 'package:flutter/material.dart';
import 'test_db.dart';


class ArrivalsDeparturesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arrivals/Departures'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(userGroup, context), //Generate items for User
          ],
        ),
      ),
      body: ArrivalsDeparturesTable(),

    );
  }
}

class ArrivalsDeparturesTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Forward/Backward buttons (to be implemented)
        // Placeholder table
        ListView.builder(
          shrinkWrap: true,
          itemCount: rooms.length,
          itemBuilder: (BuildContext context, int index) {
            Room room = rooms[index];

            return Container(
              color: getCellColor(room.id, DateTime.now()),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text(room.name)),
                  ),
                  for (int i = 0; i < 7; i++)
                    Container(
                      padding: EdgeInsets.all(8.0),
                      color: getCellColor(room.id, DateTime.now().add(Duration(days: i))),
                      child: Center(child: Text(getReservationInfo(room.id, DateTime.now().add(Duration(days: i))))),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color? getCellColor(int roomId, DateTime date) {
    DateTime yesterday = date.subtract(Duration(days: 1));
    DateTime tomorrow = date.add(Duration(days: 1));

    List<Reservation> yesterdayReservations = reservations
        .where((res) => res.roomId == roomId && yesterday.isAfter(res.startDate) && yesterday.isBefore(res.endDate))
        .toList();

    List<Reservation> todayReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    List<Reservation> tomorrowReservations = reservations
        .where((res) => res.roomId == roomId && tomorrow.isAfter(res.startDate) && tomorrow.isBefore(res.endDate))
        .toList();


    if (todayReservations.isNotEmpty) {
      // Check for changes in reservations (check-in, check-out, stay or change of guest)
      if (yesterdayReservations.isEmpty) {
        return Colors.lightGreenAccent; // Guest is arriving today, use light green
      } else if (todayReservations[0].id != yesterdayReservations[0].id) {
        return Colors.greenAccent; // Guest is changing today, use green
      } else if (tomorrowReservations.isEmpty) {
        return Colors.lightGreenAccent; // Guest is leaving today, use light green
      } else {
        return Colors.lightGreen[200]; // Guest is staying, use light green
      }
    }

    return Colors.white; // Room available

  }

  String getGuestFullName(int guestId) {
    Guest guest = guests.firstWhere((g) => g.id == guestId);
    return guest.lastName;
  }

  String getReservationInfo(int roomId, DateTime date) {
    List<Reservation> roomReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    if (roomReservations.isNotEmpty) {
      Reservation reservation = roomReservations[0];

      if (reservation.startDate == date) {
        // Guest is arriving today
        String leavingGuest = getLeavingGuest(roomId, date);
        String arrivingGuest = getGuestFullName(reservation.guestId);

        if (leavingGuest.isNotEmpty) {
          return '$leavingGuest / $arrivingGuest';
        } else {
          return arrivingGuest;
        }
      } else {
        // Guest is staying or leaving today
        String leavingGuest = getLeavingGuest(roomId, date);
        return leavingGuest.isNotEmpty ? leavingGuest : getGuestFullName(reservation.guestId);
      }
    } else {
      return 'FREE'; // Room available
    }
  }

  String getLeavingGuest(int roomId, DateTime date) {
    List<Reservation> leavingReservations = reservations
        .where((res) => res.roomId == roomId && date.isAfter(res.startDate) && date.isBefore(res.endDate))
        .toList();

    if (leavingReservations.isNotEmpty) {
      Reservation leavingReservation = leavingReservations[0];
      DateTime nextDay = date.add(Duration(days: 1));

      List<Reservation> nextDayReservations = reservations
          .where((res) => res.roomId == roomId && nextDay.isAfter(res.startDate) && nextDay.isBefore(res.endDate))
          .toList();

      if (nextDayReservations.isNotEmpty && leavingReservation.id != nextDayReservations[0].id) {
        // Different reservation IDs on adjacent days, both guests are involved
        return '${getGuestFullName(leavingReservation.guestId)} / ${getGuestFullName(nextDayReservations[0].guestId)}';
      } else {
        // Same reservation ID on adjacent days, returning only the leaving guest
        return getGuestFullName(leavingReservation.guestId);
      }
    } else {
      return ''; // No leaving guest
    }
  }
}