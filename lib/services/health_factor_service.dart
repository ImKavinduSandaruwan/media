import 'dart:convert';
import 'package:app/api.dart';
import 'package:http/http.dart' as http;

class HealthFactorService {
  static const String baseUrl = '$baseURL/health-factor';

  /// Initialize health factor session
  /// POST: /health-factor/initialize/{userId}
  static Future<Map<String, dynamic>> initializeSession(int userId) async {
    try {
      print('=== Health Factor Initialize API Call ===');
      print('URL: $baseUrl/initialize/$userId');
      print('Method: POST');
      print('Headers: Content-Type: application/json');

      final response = await http.post(
        Uri.parse('$baseUrl/initialize/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=========================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.body;

        // Check if response is just a boolean or empty
        if (responseBody == 'true' ||
            responseBody == 'false' ||
            responseBody.isEmpty) {
          // API returned boolean, use userId as temporary ID
          return {
            'success': true,
            'data': {'id': userId},
          };
        }

        try {
          final data = json.decode(responseBody);

          // If data is a boolean or not a Map, return userId as ID
          if (data is! Map<String, dynamic>) {
            return {
              'success': true,
              'data': {'id': userId},
            };
          }

          return {'success': true, 'data': data};
        } catch (jsonError) {
          // JSON decode failed, use userId as ID
          return {
            'success': true,
            'data': {'id': userId},
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Failed to initialize session: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error initializing session: $e'};
    }
  }

  /// Update health factor with exercise data
  /// PUT: /health-factor/update
  static Future<Map<String, dynamic>> updateHealthFactor({
    required int id,
    required int patientId,
    required String date,
    required double beforeSpo2,
    required double beforeHr,
    required double afterSpo2,
    required double afterHr,
    required double run,
  }) async {
    try {
      final body = {
        // 'id': 16,
        'patientId': patientId,
        'date': date,
        'beforeSpo2': beforeSpo2,
        'beforeHr': beforeHr,
        'afterSpo2': afterSpo2,
        'aftereHr': afterHr, // Note: API has typo "aftereHr"
        'run': run,
      };

      print('=== Health Factor Update API Call ===');
      print('URL: $baseUrl/update');
      print('Method: PUT');
      print('Headers: Content-Type: application/json');
      print('Payload: ${json.encode(body)}');

      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=====================================');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': 'Failed to update health factor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error updating health factor: $e'};
    }
  }
}
