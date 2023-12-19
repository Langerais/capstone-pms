import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db_helper.dart';
import 'authentication.dart';
import 'drawer_menu.dart';
import 'models.dart';

class UserManagementView extends StatefulWidget {
  @override
  _UserManagementViewState createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();
  final TextEditingController _managerPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<User> _users = [];
  User? _selectedUser;
  User? _currentUser;
  String? _selectedDepartment;
  bool _isEditing = false;
  bool _isPasswordChange = false;

  @override
  void initState() {
    super.initState();
    _initializeView();
    print('Current user: ${_currentUser?.name} ${_currentUser?.surname}');

  }

  Future<void> _initializeView() async {
    try {
      List<User> users = await UsersService.getUsers();
      _currentUser = await Auth.getCurrentUser();
      print('Current user: ${_currentUser?.name} ${_currentUser?.surname}');

      setState(() {
        _users = users.where((user) => user.id != _currentUser?.id).toList();
        _selectedUser = _users.isNotEmpty ? _users.first : null;
        _updateControllers();
      });
    } catch (e) {
      // Handle errors if necessary
    }
  }

  void _refreshUserList() async {
    try {
      List<User> users = await UsersService.getUsers();
      setState(() {
        _users = users;
        // You may need to reset _selectedUser or other related states as well
        _selectedUser = _users.isNotEmpty ? _users.first : null;
        _updateControllers();
      });
    } catch (e) {
      // Handle errors if necessary
    }
  }


  void _updateControllers() {
    _emailController.text = _selectedUser?.email ?? '';
    _phoneController.text = _selectedUser?.phone ?? '';
    _selectedDepartment = _selectedUser?.department;
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;


    // Check if the user is trying to change the admin user and is not an admin
    if(_selectedUser?.department == 'Admin' && _currentUser?.department != 'Admin'){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot change admin user')),
      );
      return;
    }

    // Check if the user is trying to make a user an admin or manager and is not an admin
    if((_selectedDepartment == 'Admin' || _selectedDepartment == 'Manager') && _currentUser?.department != 'Admin'){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot make user admin or manager')),
      );
      return;
    }

    // Check if user is trying to change department of Admin user
    if(_selectedUser?.department == 'Admin' && _selectedDepartment != 'Admin'){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot change admin department')),
      );
      return;
    }

    // Check if the user is trying to change the manager department and is not an admin
    if(_selectedUser?.department == 'Manager' && _currentUser?.department != 'Admin'){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot change manager user')),
      );
      return;
    }

    if (_managerPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the manager password')),
      );
      return;
    }
    //_currentUser = await Auth.getCurrentUser();

    bool managerPasswordCorrect = await Auth.checkPassword(
        _currentUser!.email, _managerPasswordController.text);

    try {
      if (!managerPasswordCorrect) {
          SnackBar(content: Text('Incorrect manager password'));
          return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to check password: $e')),
      );
      return;
    }

    // Use changePasswordManager if _isPasswordChange is true
    if (_isPasswordChange) {
      await UsersService.changePasswordManager(
        _selectedUser!.id,
        _managerPasswordController.text,
        _newPasswordController.text,
      );
    }

    // Update department
    if (_selectedUser!.department != _selectedDepartment) {
      await UsersService.changeDepartment(
        _selectedUser!.id,
        _selectedDepartment!.toString()
      );
    }

    // Update other user details
    if(_selectedUser!.email != _emailController.text || _selectedUser!.phone != _phoneController.text){
      await UsersService.modifyUser(
        name: _selectedUser!.name,
        surname: _selectedUser!.surname,
        userId: _selectedUser!.id,
        email: _emailController.text,
        phone: _phoneController.text,
        department: _selectedUser!.department,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User updated successfully')),
    );

    _managerPasswordController.clear(); //TODO: Fix dropdown refresh on save and manager password clear

    // Refresh the user list
    await _initializeView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _navigateToNewUserView,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            ...getDrawerItems(Auth.getUserRole(), context), //Generate items for User
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_users.isNotEmpty) _buildUserDropdown(),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value != null && value.contains('@') ? null : 'Enter a valid email',
                onChanged: (_) => _isEditing = true,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value != null && value.isNotEmpty ? null : 'Enter a valid phone number',
                onChanged: (_) => _isEditing = true,
              ),
              _buildDepartmentDropdown(),
              if (_isPasswordChange) _buildPasswordFields(),
              _buildManagerPasswordField(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveChanges,
                    child: Text('Save Changes'),  // TODO: Fix dropdown refresh on save and manager password clear
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _isPasswordChange = !_isPasswordChange),
                    child: Text(_isPasswordChange ? 'Cancel Password Change' : 'Change Password'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildUserDropdown() {
    return DropdownButton<User>(
      value: _selectedUser,
      onChanged: (User? newUser) {
        setState(() {
          _selectedUser = newUser;
          _updateControllers();
        });
      },
      items: _users.map<DropdownMenuItem<User>>((User user) {
        return DropdownMenuItem<User>(
          value: user,
          child: Text('${user.name} ${user.surname} (${user.department})'),
        );
      }).toList(),
      hint: const Text('Select a user to edit'),
    );
  }



  Widget _buildDepartmentDropdown() {
    return FutureBuilder<List<Department>>(
      future: UsersService.getAllDepartments(),
      builder: (BuildContext context, AsyncSnapshot<List<Department>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Display a loader while the data is being fetched
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle the error case
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Handle the case when there is no data
          return Text('No departments available');
        } else {
          // Data is available, build the dropdown
          List<DropdownMenuItem<String>> departmentItems = snapshot.data!
              .map<DropdownMenuItem<String>>((Department department) {
            return DropdownMenuItem<String>(
              value: department.departmentName,
              child: Text(department.departmentName),
            );
          }).toList();

          return DropdownButton<String>(
            value: _selectedDepartment,
            onChanged: (String? newDepartment) {
              setState(() {
                _selectedDepartment = newDepartment;
              });
            },
            items: departmentItems,
          );
        }
      },
    );
  }


  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: _newPasswordController,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
          validator: _validatePassword,
        ),
        TextFormField(
          controller: _confirmNewPasswordController,
          decoration: const InputDecoration(labelText: 'Confirm New Password'),
          obscureText: true,
          validator: (value) {
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildManagerPasswordField() {
    return TextFormField(
      controller: _managerPasswordController,
      decoration: const InputDecoration(labelText: 'Manager Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the manager password';
        }
        return null;
      },
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[0-9]').hasMatch(value) || !RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one number and one letter';
    }
    return null;
  }

  @override
  void dispose() {

    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    _managerPasswordController.dispose();

    super.dispose();
  }

  void _navigateToNewUserView() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewUserView()),
    ).then((_) => _refreshUserList()); // Refresh the user list when returning
  }

}



class NewUserView extends StatefulWidget {
  @override
  _NewUserViewState createState() => _NewUserViewState();
}

class _NewUserViewState extends State<NewUserView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create New User')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildNameField(),
              _buildSurnameField(),
              _buildEmailField(),
              _buildConfirmEmailField(),
              _buildPhoneField(),
              _buildPasswordField(),
              _buildConfirmPasswordField(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(labelText: 'Name'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  Widget _buildSurnameField() {
    return TextFormField(
      controller: _surnameController,
      decoration: const InputDecoration(labelText: 'Surname'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a surname';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(labelText: 'Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmEmailField() {
    return TextFormField(
      controller: _confirmEmailController,
      decoration: const InputDecoration(labelText: 'Confirm Email'),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value != _emailController.text) {
          return 'Email addresses do not match';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: const InputDecoration(labelText: 'Phone'),
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(labelText: 'Password'),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!RegExp(r'\d').hasMatch(value) || !RegExp(r'[A-Za-z]').hasMatch(value)) {
          return 'Password must contain at least one number and one letter';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: const InputDecoration(labelText: 'Confirm Password'),
      obscureText: true,
      validator: (value) {
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  void _createUser() async {
    if (_formKey.currentState!.validate()) {
      final result = await UsersService.registerUser(
        name: _nameController.text,
        surname: _surnameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        // Navigate back to UserManagementView after successful creation
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


}

