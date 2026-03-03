import 'dart:convert';
import 'package:app/api.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DailyActionService {

  Future<void> performDailyAction(int userId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final url = '$baseURL/daily-action/$userId/$today';
      //final url = '$baseUrl/daily-action/1/$today';

      print('Calling daily action: $url');

      final response = await http.post(Uri.parse(url));

      print('Daily action response status: ${response.statusCode}');
      print('Daily action response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Daily action completed successfully');
      } else {
        print('Daily action failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error performing daily action: $e');
      // Don't throw error - we don't want to block login if this fails
    }
  }
}
