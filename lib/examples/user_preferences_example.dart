// Example: How to use the saved userId in other parts of your app

import 'package:flutter/material.dart';
import '../services/user_preferences.dart';

// Example 1: Get userId in any widget
void exampleGetUserId() async {
  final userId = await UserPreferences.getUserId();
  if (userId != null) {
    print('Current user ID: $userId');
    // Use the userId for API calls or other operations
  }
}

// Example 2: Use in a StatefulWidget
class ExampleWidget extends StatefulWidget {
  const ExampleWidget({super.key});

  @override
  State<ExampleWidget> createState() => _ExampleWidgetState();
}

class _ExampleWidgetState extends State<ExampleWidget> {
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await UserPreferences.getUserId();
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text('User ID: ${userId ?? "Not logged in"}');
  }
}

// Example 3: Check if user is logged in
Future<bool> checkLoginStatus() async {
  return await UserPreferences.isLoggedIn();
}

// Example 4: Get all user data
Future<Map<String, dynamic>> getUserData() async {
  final userId = await UserPreferences.getUserId();
  final username = await UserPreferences.getUsername();
  final role = await UserPreferences.getRole();

  return {'userId': userId, 'username': username, 'role': role};
}

// Example 5: Logout (clear user data)
Future<void> logout() async {
  await UserPreferences.clearUserData();
  // Navigate to login screen
}
