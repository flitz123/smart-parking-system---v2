import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/parking_slot.dart';

class FirebaseService {
  late final FirebaseFirestore? _db;

  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return String.fromEnvironment('BACKEND_BASE',
        defaultValue: 'http://10.0.2.2:5000');
  }

  FirebaseService() {
    if (!kIsWeb) {
      // Only use Firestore if Firebase was successfully initialized in main
      try {
        if (Firebase.apps.isNotEmpty) {
          _db = FirebaseFirestore.instance;
        } else {
          // Firebase not initialized (e.g. missing google-services.json)
          print('FirebaseService: Firebase.apps is empty, falling back to API');
          _db = null;
        }
      } catch (e) {
        print(
            'FirebaseService: Firestore unavailable, falling back to API: $e');
        _db = null;
      }
    } else {
      _db = null;
    }
  }

  Stream<List<ParkingSlot>> slotsStream() {
    if (kIsWeb || _db == null) {
      return Stream.periodic(
        const Duration(seconds: 2),
        (_) async {
          try {
            final response = await http
                .get(Uri.parse('$apiBaseUrl/api/parking/slots'))
                .timeout(const Duration(seconds: 3));
            if (response.statusCode == 200) {
              final List<dynamic> data = jsonDecode(response.body);
              return data
                  .map((json) =>
                      ParkingSlot.fromMap(json as Map<String, dynamic>))
                  .toList();
            }
          } catch (e) {
            print('API error (using fallback): $e');
          }
          return _getMockSlots();
        },
      ).asyncExpand<List<ParkingSlot>>((future) => Stream.fromFuture(future));
    }

    return _db!
        .collection('slots')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return ParkingSlot.fromMap(data);
            }).toList());
  }

  List<ParkingSlot> _getMockSlots() {
    return [
      ParkingSlot(
        id: '1',
        name: 'A1',
        status: 'available',
        plate: null,
        phone: null,
        startTime: null,
        reservedUntil: null,
        reservedBy: null,
      ),
      ParkingSlot(
        id: '2',
        name: 'A2',
        status: 'occupied',
        plate: 'KDD123A',
        phone: '+254712345678',
        startTime: DateTime.now().subtract(const Duration(minutes: 45)),
        reservedUntil: null,
        reservedBy: null,
      ),
      ParkingSlot(
        id: '3',
        name: 'A3',
        status: 'available',
        plate: null,
        phone: null,
        startTime: null,
        reservedUntil: null,
        reservedBy: null,
      ),
      ParkingSlot(
        id: '4',
        name: 'B1',
        status: 'reserved',
        plate: null,
        phone: '+254798765432',
        startTime: null,
        reservedUntil: DateTime.now().add(const Duration(hours: 2)),
        reservedBy: 'John Doe',
      ),
      ParkingSlot(
        id: '5',
        name: 'B2',
        status: 'available',
        plate: null,
        phone: null,
        startTime: null,
        reservedUntil: null,
        reservedBy: null,
      ),
      ParkingSlot(
        id: '6',
        name: 'B3',
        status: 'occupied',
        plate: 'KBX456B',
        phone: '+254723456789',
        startTime: DateTime.now().subtract(const Duration(minutes: 120)),
        reservedUntil: null,
        reservedBy: null,
      ),
    ];
  }

  Future<void> updateSlotDocument(String id, Map<String, dynamic> data) async {
    if (kIsWeb || _db == null) {
      try {
        if (data['status'] == 'empty' || data['status'] == 'available') {
          await http.post(
            Uri.parse('$apiBaseUrl/api/parking/leave'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'slotId': id}),
          );
        } else {
          await http.post(
            Uri.parse('$apiBaseUrl/api/parking/occupy'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'slotId': id, 'plate': data['plate'], 'phone': data['phone']}),
          );
        }
      } catch (e) {
        print('Update error: $e');
      }
      return;
    }

    await _db!.collection('slots').doc(id).set(data, SetOptions(merge: true));
  }
}
