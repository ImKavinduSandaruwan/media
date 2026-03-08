import 'dart:convert';
import 'package:app/api.dart';
import 'package:http/http.dart' as http;

class TrackerService {
  Future<bool> saveExtraDose({
    required int patientId,
    required String date,
    required bool status,
    double? doseAmount,
    String? time,
    String? reason,
  }) async {
    try {
      final url = '$baseURL/tracker/extra-dose';

      final payload = {
        'patientId': patientId,
        'date': date,
        'status': status,
        if (doseAmount != null) 'doseAmount': doseAmount,
        if (time != null) 'time': time,
        if (reason != null) 'reason': reason,
      };

      print('Saving extra dose: $url');
      print('Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Extra dose response status: ${response.statusCode}');
      print('Extra dose response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving extra dose: $e');
      return false;
    }
  }

  Future<bool> saveVitaminK({
    required int patientId,
    required String date,
    required bool status,
    double? weight,
  }) async {
    try {
      final url = '$baseURL/tracker/vitamin-k';

      final payload = {
        'patientId': patientId,
        'date': date,
        'status': status,
        if (weight != null) 'weight': weight,
      };

      print('Saving vitamin K: $url');
      print('Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Vitamin K response status: ${response.statusCode}');
      print('Vitamin K response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving vitamin K: $e');
      return false;
    }
  }

  Future<bool> saveExtraMedication({
    required int patientId,
    required String date,
    required bool status,
    String? category,
    String? name,
    String? doseAndFreq,
  }) async {
    try {
      final url = '$baseURL/tracker/extra-medication';

      final payload = {
        'patientId': patientId,
        'date': date,
        'status': status,
        if (category != null) 'category': category,
        if (name != null) 'name': name,
        if (doseAndFreq != null) 'doseAndFreq': doseAndFreq,
      };

      print('Saving extra medication: $url');
      print('Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Extra medication response status: ${response.statusCode}');
      print('Extra medication response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving extra medication: $e');
      return false;
    }
  }

  Future<bool> saveSymptoms({
    required int patientId,
    required String date,
    required bool status,
    String? sList,
  }) async {
    try {
      final url = '$baseURL/tracker/symptoms';

      final payload = {
        'patientId': patientId,
        'date': date,
        'status': status,
        if (sList != null) 'sList': sList,
      };

      print('Saving symptoms: $url');
      print('Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('Symptoms response status: ${response.statusCode}');
      print('Symptoms response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error saving symptoms: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> calculateInrDose({
    required int patientId,
    required double inr,
  }) async {
    try {
      final url = '$baseURL/inr/dose';

      final payload = {'patientId': patientId, 'inr': inr};
      //final payload = {'patientId': 1, 'inr': inr};

      print('Calculating INR dose: $url');
      print('Payload: $payload');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('INR dose response status: ${response.statusCode}');
      print('INR dose response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error calculating INR dose: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBehaviorAnalysis({
    required int patientId,
    required String date,
    required int inrStatus,
  }) async {
    try {
      final url =
          '$baseURL/tracker/behavior-analysis?patientId=$patientId&date=$date&inrStatus=$inrStatus';

      print('Getting behavior analysis: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Behavior analysis response status: ${response.statusCode}');
      print('Behavior analysis response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting behavior analysis: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getInrByUserAndDate({
    required int patientId,
    required String date,
  }) async {
    try {
      final url = '$baseURL/inr/id/date/$patientId/$date';

      print('Getting INR by user and date: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('INR by date response status: ${response.statusCode}');
      print('INR by date response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // API returns a list — take the first item
        if (decoded is List && decoded.isNotEmpty) {
          return decoded.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error getting INR by date: \$e');
      return null;
    }
  }

  Future<List<dynamic>?> getInrRange({
    required int patientId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final url =
          '$baseURL/inr/range?patientId=$patientId&startDate=$startDate&endDate=$endDate';

      print('Getting INR range: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('INR range response status: ${response.statusCode}');
      print('INR range response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting INR range: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getOverallInsights({
    required int patientId,
  }) async {
    try {
      final url = '$baseURL/tracker/overall/$patientId';

      print('Getting overall insights: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Overall insights response status: ${response.statusCode}');
      print('Overall insights response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting overall insights: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getPatientTrackingData({
    required int patientId,
  }) async {
    try {
      final url = '$baseURL/tracker/patient/$patientId';

      print('Getting patient tracking data: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('Patient tracking data response status: ${response.statusCode}');
      print('Patient tracking data response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting patient tracking data: $e');
      return null;
    }
  }
}
