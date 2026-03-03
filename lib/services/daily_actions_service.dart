import 'dart:convert';
import 'package:app/api.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

enum ActionType { STOP_FOOD, TAKE_WARFARIN, CONFIRM_DOSE, START_FOOD }

class DailyActionsResponse {
  final int? id;
  final int? patientId;
  final String? date;
  final bool stopFood;
  final String? stopFoodTime;
  final bool takeWarfarin;
  final String? takeWarfarinTime;
  final bool confirmDoseTake;
  final String? confirmDoseTakeTime;
  final bool startFood;
  final String? startFoodTime;

  DailyActionsResponse({
    this.id,
    this.patientId,
    this.date,
    required this.stopFood,
    this.stopFoodTime,
    required this.takeWarfarin,
    this.takeWarfarinTime,
    required this.confirmDoseTake,
    this.confirmDoseTakeTime,
    required this.startFood,
    this.startFoodTime,
  });

  factory DailyActionsResponse.fromJson(Map<String, dynamic> json) {
    return DailyActionsResponse(
      id: json['id'],
      patientId: json['patientId'],
      date: json['date'],
      stopFood: json['stopFood'] ?? false,
      stopFoodTime: json['stopFoodTime'],
      takeWarfarin: json['takeWarfarin'] ?? false,
      takeWarfarinTime: json['takeWarfarinTime'],
      confirmDoseTake: json['confirmDoseTake'] ?? false,
      confirmDoseTakeTime: json['confirmDoseTakeTime'],
      startFood: json['startFood'] ?? false,
      startFoodTime: json['startFoodTime'],
    );
  }

  factory DailyActionsResponse.empty() {
    return DailyActionsResponse(
      stopFood: false,
      takeWarfarin: false,
      confirmDoseTake: false,
      startFood: false,
    );
  }
}

class DailyActionsService {

  // Get daily actions status from backend
  Future<DailyActionsResponse> getDailyActions({
    required int patientId,
    required String date,
  }) async {
    try {
      final url = '$baseURL/daily-action/$patientId/$date';

      print('Getting daily actions: $url');

      final response = await http.get(Uri.parse(url));

      print('Get daily actions response status: ${response.statusCode}');
      print('Get daily actions response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DailyActionsResponse.fromJson(data);
      } else {
        // Return empty response if not found
        return DailyActionsResponse.empty();
      }
    } catch (e) {
      print('Error getting daily actions: $e');
      return DailyActionsResponse.empty();
    }
  }

  // Update action on backend
  Future<bool> updateAction({
    required int patientId,
    required String date,
    required ActionType actionType,
  }) async {
    try {
      final url = '$baseURL/daily-action/update';

      final payload = {
        'patientId': patientId,
        'date': date,
        'actionType': actionType.name,
      };

      print('Updating action: $url');
      print('Payload: $payload');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Update action response status: ${response.statusCode}');
      print('Update action response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating action: $e');
      return false;
    }
  }
}
