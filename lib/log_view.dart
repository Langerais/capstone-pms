import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'authentication.dart';
import 'db_helper.dart';
import 'models.dart';
import 'drawer_menu.dart';


class LogsView extends StatefulWidget {
  const LogsView({super.key});

  @override
  _LogsViewState createState() => _LogsViewState();
}

class _LogsViewState extends State<LogsView> {
  List<String> _actions = [];
  String? _selectedAction;
  List<User> _users = [];
  int? _selectedUserId;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  List<Log> _logs = [];

  @override
  void initState() {
    super.initState();
    _fetchActions();
    _fetchUsers();
  }

  Future<void> _fetchActions() async {
    try {
      List<String> actionsFromService = await LogService.getUniqueActions();
      setState(() {
        _actions = ['All Actions'] + actionsFromService; // Prepend "All logs" to the list
        _selectedAction = _actions[0]; // Set the default value
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch actions: $e');
      }
    }
  }

  Future<void> _fetchUsers() async {
    try {
      List<User> usersFromService = await UsersService.getUsers();
      setState(() {
        _users = [User(id: 0, name: 'All Users', surname: '', department: '', email: '', phone: '')] + usersFromService;
        _selectedUserId = _users[0].id;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch users: $e');
      }
    }
  }


  Future<void> _fetchLogs() async {

    try {

      String? startDate;
      String? endDate;

      // Check if _selectedDateRange is not null before accessing its properties
      if (_selectedDateRange != null) {
        startDate = _selectedDateRange!.start.toIso8601String();
        endDate = _selectedDateRange!.end.toIso8601String();
      }

      var fetchedLogs = await LogService.fetchLogs(
        startDate: startDate,
        endDate: endDate,
        action: _selectedAction,
        userId: _selectedUserId,
        details: _searchQuery,
      );


      setState(() {
        _logs = fetchedLogs.map<Log>((json) => Log.fromJson(json)).toList();
        _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching logs: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
          ],
        ),
      ),
      body: Column(
        children: [
          Row(
            children: [
              // Action Dropdown
              const SizedBox(width: 20),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAction,
                  onChanged: (String? newValue) {
                    setState(() => _selectedAction = newValue);
                    _fetchLogs();
                  },
                  items: _actions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 20),
              // Date Range Picker
              Text(_selectedDateRange != null
                  ? '${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)}'
                  : 'Select Date Range'),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  DateTimeRange? range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDateRange: _selectedDateRange,
                  );
                  if (range != null) {
                    setState(() => _selectedDateRange = range);
                    _fetchLogs();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;  // Set the date range to null
                  });
                },
              ),
              // Selected Date Range
              const SizedBox(width: 20),
            ],
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20), // Adjust the padding as needed
            child: TextField(
              onChanged: (value) {
                _searchQuery = value;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search Log Details',
                suffixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<int>(
                  value: _selectedUserId,
                  onChanged: (int? newValue) {
                    setState(() {
                      _selectedUserId = newValue;
                    });
                    _fetchLogs();
                  },
                  items: _users.map<DropdownMenuItem<int>>((User user) {
                    return DropdownMenuItem<int>(
                      value: user.id,
                      child: Text(user.id == 0 ? user.name : '${user.id} ${user.name} ${user.surname} (${user.department})'),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 20),
                // Search Icon Button
                IconButton(
                  icon: CircleAvatar(
                    radius: 20, // Adjust the radius for size
                    backgroundColor: Theme.of(context).primaryColor, // Set the color
                    child: const Icon(Icons.search, size: 24), // Adjust icon size
                  ),
                  onPressed: _fetchLogs,
                ),
                const SizedBox(width: 15),
              ]
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('${_logs[index].action} | '
                      '${_users.firstWhere((user) => user.id == _logs[index].userId).name} '
                      '${_users.firstWhere((user) => user.id == _logs[index].userId).surname} | '
                      '${_users.firstWhere((user) => user.id == _logs[index].userId).department}'
                      '\n${DateFormat('yyyy-MM-dd HH:mm').format(_logs[index].timestamp)}'),
                  subtitle: Text(_logs[index].details),
                  // Add more details as needed
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}