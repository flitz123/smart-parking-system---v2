import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../services/firebase_service.dart';
import 'entry_form.dart';
import 'reserve_sheet.dart';
import '../services/api_service.dart';

class GridScreen extends StatefulWidget {
  @override
  _GridScreenState createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final FirebaseService _fs = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Parking')),
      body: StreamBuilder<List<ParkingSlot>>(
        stream: _fs.slotsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final slots = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final s = slots[index];
              return GestureDetector(
                onTap: () async {
                  if (s.status == 'empty') {
                    showModalBottomSheet(context: context, builder: (_) => ReserveSheet(slot: s));
                  } else if (s.status == 'reserved') {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      title: Text('Slot ${s.name}'),
                      content: Text('Reserved by: ${s.reservedBy}\nUntil: ${s.reservedUntil}'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                    ));
                  } else {
                    // occupied - allow checkout
                    final duration = DateTime.now().difference(s.startTime ?? DateTime.now());
                    final minutes = duration.inMinutes;
                    final ratePerHour = 50.0;
                    final fee = (minutes / 60) * ratePerHour;
                    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                      title: Text('Checkout ${s.name}'),
                      content: Text('Parked for ${minutes} minutes. Fee: KES ${fee.toStringAsFixed(2)}'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay'))
                      ],
                    ));
                    if (confirm == true) {
                      final ok = await ApiService.initiateMpesa(s.phone ?? '', fee, s.name);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('M-Pesa prompt sent')));
                        // mark empty locally; finalization on backend callback
                        await _fs.updateSlotDocument(s.name, {'status': 'empty', 'plate': null, 'phone': null, 'start_time': null});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment initiation failed')));
                      }
                    }
                  }
                },
                child: Card(
                  color: s.status == 'occupied' ? Colors.red[300] : (s.status == 'reserved' ? Colors.orange[200] : Colors.green[200]),
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(s.status.toUpperCase())])),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
