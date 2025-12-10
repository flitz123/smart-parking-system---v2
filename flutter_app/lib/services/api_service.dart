import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static String get baseUrl {
    if (kIsWeb)
      return const String.fromEnvironment('BACKEND_BASE',
          defaultValue: 'http://localhost:5000');
    return const String.fromEnvironment('BACKEND_BASE',
        defaultValue: 'http://10.0.2.2:5000');
  }

  static Future<Map<String, dynamic>> reserveSlot(
      String slotId, String phone, String plate,
      {int durationMinutes = 60}) async {
    final url = Uri.parse('$baseUrl/api/reservations/reserve');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'slotId': slotId,
          'phone': phone,
          'plate': plate,
          'durationMinutes': durationMinutes
        }));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> cancelReservation(
      String slotId, String phone) async {
    final url = Uri.parse('$baseUrl/api/reservations/cancel');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slotId': slotId, 'phone': phone}));
    return jsonDecode(res.body);
  }

  static Future<bool> sendSlotSms(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/twilio/send');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));
    return res.statusCode == 200;
  }

  static Future<Map<String, dynamic>> initiateMpesa(
      String phone, double amount, String slotId) async {
    final url = Uri.parse('$baseUrl/api/mpesa/stkpush');
    try {
      print(
          '[API] Initiating M-Pesa STK push: phone=$phone, amount=$amount, slotId=$slotId');

      final res = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'phoneNumber': phone,
                'amount': amount.toStringAsFixed(0),
                'accountReference': slotId,
                'description': 'Parking fee for slot $slotId'
              }))
          .timeout(const Duration(seconds: 10));

      print('[API] M-Pesa response status: ${res.statusCode}');
      print('[API] M-Pesa response body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {
          'ok': data['ok'] ?? true,
          'data': data['data'],
          'message': 'M-Pesa prompt sent successfully'
        };
      } else {
        final errorData = jsonDecode(res.body);
        return {
          'ok': false,
          'error': errorData['error'] ?? 'Failed to initiate payment',
          'details': errorData['details']
        };
      }
    } catch (e) {
      print('[API] M-Pesa error: $e');
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> occupySlot(
      String slotId, String phone, String plate) async {
    final url = Uri.parse('$baseUrl/api/parking/occupy');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slotId': slotId, 'phone': phone, 'plate': plate}));
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'ok': res.statusCode == 200};
    }
  }
}
