import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const baseUrl = String.fromEnvironment('BACKEND_BASE', defaultValue: 'http://10.0.2.2:5000');

  static Future<Map<String, dynamic>> reserveSlot(String slotId, String phone, String plate, {int durationMinutes = 60}) async {
    final url = Uri.parse('$baseUrl/api/reservations/reserve');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slotId': slotId, 'phone': phone, 'plate': plate, 'durationMinutes': durationMinutes}));
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> cancelReservation(String slotId, String phone) async {
    final url = Uri.parse('$baseUrl/api/reservations/cancel');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'slotId': slotId, 'phone': phone}));
    return jsonDecode(res.body);
  }

  static Future<bool> sendSlotSms(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/api/twilio/send');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    return res.statusCode == 200;
  }

  static Future<bool> initiateMpesa(String phone, double amount, String slotId) async {
    final url = Uri.parse('$baseUrl/api/mpesa/stkpush');
    final res = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'phoneNumber': phone, 'amount': amount.toString(), 'accountReference': slotId, 'description': 'Parking fee for $slotId'}));
    return res.statusCode == 200;
  }
}
