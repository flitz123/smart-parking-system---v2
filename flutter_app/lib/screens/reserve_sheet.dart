import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../services/api_service.dart';

class ReserveSheet extends StatefulWidget {
  final ParkingSlot slot;
  ReserveSheet({required this.slot});
  @override
  _ReserveSheetState createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<ReserveSheet> {
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _phoneCtrl.dispose(); _plateCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Reserve ${widget.slot.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextField(controller: _plateCtrl, decoration: const InputDecoration(labelText: 'Plate number')),
        TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (+254...)')),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          final res = await ApiService.reserveSlot(widget.slot.name, _phoneCtrl.text.trim(), _plateCtrl.text.trim());
          setState(() => _loading = false);
          if (res['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reserved until ${res['reservedUntil']}')));
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Reservation failed')));
          }
        }, child: const Text('Reserve'))
      ]),
    );
  }
}
