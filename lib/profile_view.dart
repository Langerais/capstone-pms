/// UserProfileView.dart
///
/// This file contains the UserProfileView class, used
/// for displaying and managing a user's profile within application.
/// The view allows users to view and edit their personal information such as
/// email, phone number, and password.
///
/// Features:
/// - Display current user information including name, surname, and role.
/// - Allow users to modify their email and phone number with validation checks.
/// - Enable password changes with security measures including password strength
///   validation and current password verification.
/// - Implement a form-based interface with proper validation for all fields.
/// - Utilize TextEditingController for managing user input and form state.
/// - Provide a responsive UI that adjusts to various screen sizes and orientations.
/// - Integrate with backend services for data retrieval and update operations.
///
/// Usage:
/// This view is used as part of a navigation flow within the app,
/// allowing users to access their profile.
///
/// Note:
/// - The file depends on external services like Auth and UsersService for
///   authentication and data handling.
/// - Error handling and user feedback mechanisms are implemented to guide
///   the user through the profile update process.
library;


import 'dart:async';
import 'package:capstone_pms/authentication.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'drawer_menu.dart';
import 'models.dart';
import 'db_helper.dart';

class UserProfileView extends StatefulWidget {
  @override
  _UserProfileViewState createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController confirmEmailController = TextEditingController();
  final TextEditingController newPhoneController = TextEditingController();
  final TextEditingController confirmPhoneController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();

  // Key to identify the form and its state
  final _formKey = GlobalKey<FormState>();

  User? currentUser; // Holds the current user's data
  bool isEditingEmail = false; // Flag to indicate if the email is being edited
  bool isEditingPhone = false; // Flag to indicate if the phone is being edited
  bool isChangingPassword = false; // Flag to indicate if the password is being changed
  bool _isFormModified = false; // Flag to indicate if the form has been modified
  bool? _isCurrentPasswordValid; // Flag to indicate if the current password is valid

  @override
  void initState() {
    super.initState();
    Auth.getCurrentUser().then((user) {
      setState(() {
        emailController.text = user!.email;
        phoneController.text = user.phone;
        currentUser = user;
        _isFormModified = false;
      });
    });
  }



  /// Function called when any field in the form is changed.
  void _onFieldChanged() {
    if (!_isFormModified) {
      setState(() {
        _isFormModified = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: FutureBuilder<UserGroup>(
        future: Auth.getUserRole(),  // Get the current user's role
        builder: (BuildContext context, AsyncSnapshot<UserGroup> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting, show a progress indicator
            return Drawer(
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            // If there's an error, show an error message
            return Drawer(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            // Once data is available, build the drawer
            return Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  ...getDrawerItems(snapshot.data!, context), // Generate items for User
                ],
              ),
            );
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'User: ${currentUser?.name ?? 'Loading...'} ${currentUser?.surname ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Text(
                      'Role: ${currentUser?.department ?? 'Loading...'}',
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildEmailField(),
              _buildPhoneField(),
              if (isChangingPassword || isEditingEmail || isEditingPhone)
                _buildCurrentPasswordField(),
              if (isChangingPassword) _buildPasswordFields(),
              const SizedBox(height: 20),
              _buildSaveCancelButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Builds the email field and its associated logic
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: isEditingEmail ? newEmailController : emailController,
          decoration: InputDecoration(
            labelText: isEditingEmail ? 'New Email' : 'Email',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
          onChanged: (value) {
            _onFieldChanged();
          },
          enabled: isEditingEmail,
        ),
        if (isEditingEmail)
          TextFormField(
            controller: confirmEmailController,
            decoration: const InputDecoration(labelText: 'Confirm Email'),
            validator: (value) {
              if (value != newEmailController.text) {
                return 'Emails do not match';
              }
              return null;
            },
          ),
        if (!isEditingEmail)
          TextButton(
            onPressed: () => setState(() {
              isEditingEmail = true;
              newEmailController.clear();
              confirmEmailController.clear();
            }),
            child: const Text('Change Email'),
          ),

      ],
    );
  }

  // Builds the phone field and its associated logic
  Widget _buildPhoneField() {

    final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: isEditingPhone ? newPhoneController : phoneController,
          decoration: InputDecoration(
            labelText: isEditingPhone ? 'New Phone' : 'Phone',
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a phone number';
            } else if (!phoneRegex.hasMatch(value)) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
          onChanged: (value) {
            _onFieldChanged();
          },
          enabled: isEditingPhone,
        ),
        if (isEditingPhone)
          TextFormField(
            controller: confirmPhoneController,
            decoration: InputDecoration(labelText: 'Confirm Phone'),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
            validator: (value) {
              if (value != newPhoneController.text) {
                return 'Phone numbers do not match';
              } else if (!phoneRegex.hasMatch(value!)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        if (!isEditingPhone)
          TextButton(
            onPressed: () => setState(() {
              isEditingPhone = true;
              newPhoneController.clear();
              confirmPhoneController.clear();
            }),
            child: const Text('Change Phone'),
          ),
      ],
    );
  }

  // Builds the password fields for changing password
  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: newPasswordController,
          decoration: const InputDecoration(labelText: 'New Password'),
          obscureText: true,
          validator: (value) => _validatePassword(value),
          onChanged: (value) {
            _onFieldChanged();
          },
        ),

        TextFormField(
          controller: confirmNewPasswordController,
          decoration: const InputDecoration(labelText: 'Confirm New Password'),
          obscureText: true,
          validator: (value) {
            if (value != newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Builds the field for entering the current password
  Widget _buildCurrentPasswordField() {
    return TextFormField(
      controller: currentPasswordController,
      decoration: InputDecoration(
        labelText: 'Current Password',
        errorText: _isCurrentPasswordValid == false ? 'Incorrect password' : null,
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your current password';
        }
        // Add additional validation if necessary
        return null;
      },
    );
  }

  // Builds save and cancel buttons
  Widget _buildSaveCancelButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!isChangingPassword)
          TextButton(
            onPressed: () => setState(() => isChangingPassword = true),
            child: const Text('Change Password'),
          ),
        ElevatedButton(
          onPressed: _cancelEdit,
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _isFormModified ? _saveProfile() : null;
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  // Function to save profile changes
  void _saveProfile() async {
      try {
        if (kDebugMode) {
          print('Saving profile');
        }

        _isCurrentPasswordValid = await Auth.checkPassword(
          currentUser!.email,
          currentPasswordController.text,
        );

        setState(() {});

        if (!_isCurrentPasswordValid!) {
          // Stop the save process if the password is invalid
          return;
        }

        String updatedEmail = isEditingEmail ? newEmailController.text : currentUser!.email;
        String updatedPhone = isEditingPhone ? newPhoneController.text : currentUser!.phone;


        // Check if the email or phone is modified and update user details
        if (isEditingEmail || isEditingPhone) {
          await UsersService.modifyUser(
            userId: currentUser!.id,
            name: currentUser!.name,
            surname: currentUser!.surname,
            phone: updatedPhone,
            email: updatedEmail,
            department: currentUser!.department,
          );
        }

        // Check if the password is being changed
        if (isChangingPassword) {
          await UsersService.changePassword(
            currentPasswordController.text,
            newPasswordController.text,
          );
        }

        //currentUser = await UsersService.getUser(currentUser!.id);

        // Reset the state to reflect changes
        setState(() {
          isEditingEmail = false;
          isEditingPhone = false;
          isChangingPassword = false;
          _isFormModified = false;
          emailController.text = currentUser!.email;
          phoneController.text = currentUser!.phone;
        });


        // Display a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }

  }

  // Function to validate the password
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

  // Function to cancel edits and revert to original data
  void _cancelEdit() {
    // Reset form and state
    Auth.getCurrentUser().then((user) {
      setState(() {
        isEditingEmail = false;
        isEditingPhone = false;
        isChangingPassword = false;

        newPasswordController.clear();
        confirmNewPasswordController.clear();
        emailController.text = user!.email;
        phoneController.text = user.phone;
        confirmEmailController.clear();
        confirmPhoneController.clear();
        _formKey.currentState!.reset();
        _isFormModified = false;
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    confirmEmailController.dispose();
    confirmPhoneController.dispose();
    super.dispose();
  }
}
