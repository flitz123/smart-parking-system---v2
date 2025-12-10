import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../services/firebase_service.dart';
import 'reserve_sheet.dart';
import '../services/api_service.dart';

class GridScreen extends StatefulWidget {
  @override
  _GridScreenState createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final FirebaseService _fs = FirebaseService();
  late Stream<List<ParkingSlot>> _slotsStream;

  @override
  void initState() {
    super.initState();
    _slotsStream = _fs.slotsStream();
  }

  void _refreshSlots() {
    setState(() {
      _slotsStream = _fs.slotsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Parking')),
      body: StreamBuilder<List<ParkingSlot>>(
        stream: _slotsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final slots = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final s = slots[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    // Treat both 'empty' and 'available' as free
                    if (s.status == 'empty' || s.status == 'available') {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => Padding(
                                padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(ctx).viewInsets.bottom),
                                child: ReserveSheet(
                                    slot: s, onRefresh: _refreshSlots),
                              ));
                    } else if (s.status == 'reserved') {
                      await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (ctx) => Padding(
                                padding: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(ctx).viewInsets.bottom),
                                child: ReserveSheet(
                                  slot: s,
                                  onRefresh: _refreshSlots,
                                  manageReservation: true,
                                ),
                              ));
                    } else {
                      final duration = DateTime.now()
                          .difference(s.startTime ?? DateTime.now());
                      final minutes = duration.inMinutes;
                      final ratePerHour = 50.0;
                      final fee = (minutes / 60) * ratePerHour;
                      final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: Text('Checkout ${s.name}'),
                                content: Text(
                                    'Parked for ${minutes} minutes. Fee: KES ${fee.toStringAsFixed(2)}'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Pay'))
                                ],
                              ));
                      if (confirm == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Processing payment...')));

                        final result = await ApiService.initiateMpesa(
                            s.phone ?? '', fee, s.id);

                        if (result['ok'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  result['message'] ?? 'M-Pesa prompt sent'),
                              backgroundColor: Colors.green));
                          await _fs.updateSlotDocument(s.id, {
                            'status': 'empty',
                            'plate': null,
                            'phone': null,
                            'start_time': null
                          });
                          _refreshSlots();
                        } else {
                          String errorMsg =
                              result['error'] ?? 'Payment initiation failed';
                          if (result['details'] != null) {
                            errorMsg += ': ${result['details']}';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Colors.red));
                          print('[ERROR] Payment failed: $result');
                        }
                      }
                    }
                  },
                  child: Card(
                    color: s.status == 'occupied'
                        ? Colors.red[300]
                        : (s.status == 'reserved'
                            ? Colors.orange[200]
                            : Colors.green[200]),
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(s.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(s.status.toUpperCase())
                    ])),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
