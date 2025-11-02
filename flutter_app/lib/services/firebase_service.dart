import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_slot.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ParkingSlot>> slotsStream() {
    return _db.collection('slots').snapshots().map((snap) => snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return ParkingSlot.fromMap(data);
        }).toList());
  }

  Future<void> updateSlotDocument(String id, Map<String, dynamic> data) async {
    await _db.collection('slots').doc(id).set(data, SetOptions(merge: true));
  }
}
