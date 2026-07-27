import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<List<dynamic>> getVitals(String patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/vitals/$patientId'));
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> getLatestVital(String patientId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/vitals/$patientId/latest'));
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getSymptoms(String patientId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/symptoms/$patientId'));
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getReminders(String patientId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/api/reminders/$patientId'));
    return json.decode(response.body);
  }
}
