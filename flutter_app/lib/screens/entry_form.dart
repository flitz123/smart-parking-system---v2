import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../services/api_service.dart';

class EntryForm extends StatefulWidget {
  final ParkingSlot slot;
  EntryForm({required this.slot});
  @override
  _EntryFormState createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  final _plateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _plateCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign ${widget.slot.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: _plateCtrl, decoration: const InputDecoration(labelText: 'Plate number')),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (+254...)')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () async {
            final updated = {
              'status': 'occupied',
              'plate': _plateCtrl.text.trim(),
              'phone': _phoneCtrl.text.trim(),
              'start_time': DateTime.now().toIso8601String()
            };
            final ok = await ApiService.sendSlotSms({'phoneNumber': _phoneCtrl.text.trim(), 'message': 'Your slot ${widget.slot.name} has been reserved.'});
            await ApiService.reserveSlot(widget.slot.name, _phoneCtrl.text.trim(), _plateCtrl.text.trim());
            Navigator.pop(context, true);
          }, child: const Text('Confirm & Send SMS'))
        ]),
      ),
    );
  }
}
