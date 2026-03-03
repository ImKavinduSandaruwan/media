import 'dart:convert';
import 'package:app/api.dart';
import 'package:http/http.dart' as http;

class AuthService {

  Future<LoginResponse> login(String email, String password) async {
    try {
      // Convert password to int if it's numeric, otherwise keep as string
      dynamic passwordValue = password;
      final numPassword = int.tryParse(password);
      if (numPassword != null) {
        passwordValue = numPassword;
      }

      final requestBody = {'email': email, 'password': passwordValue};

      print('Request URL: $baseURL/auth/login');
      print('Request Body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseURL/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResponse.fromJson(data);
      } else {
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          return LoginResponse.fromJson(errorData);
        } catch (e) {
          throw Exception(
            'Failed to login: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }
}

class LoginResponse {
  final int? userId;
  final String msg;
  final String? username;
  final String? role;

  LoginResponse({
    required this.userId,
    required this.msg,
    this.username,
    this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['userId'],
      msg: json['msg'] ?? 'Unknown error',
      username: json['username'],
      role: json['role'],
    );
  }

  bool get isSuccess => userId != null;
}
