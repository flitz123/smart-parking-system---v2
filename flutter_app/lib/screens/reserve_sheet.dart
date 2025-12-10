import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../services/api_service.dart';

class ReserveSheet extends StatefulWidget {
  final ParkingSlot slot;
  final VoidCallback? onRefresh;
  final bool manageReservation;
  ReserveSheet(
      {required this.slot, this.onRefresh, this.manageReservation = false});
  @override
  _ReserveSheetState createState() => _ReserveSheetState();
}

class _ReserveSheetState extends State<ReserveSheet> {
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  bool _loading = false;
  String _action = 'reserve';
  bool get _isManaging =>
      widget.manageReservation || widget.slot.status == 'reserved';

  @override
  void initState() {
    super.initState();
    if (widget.slot.phone != null) _phoneCtrl.text = widget.slot.phone!;
    if (widget.slot.plate != null) _plateCtrl.text = widget.slot.plate!;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text('Reserve ${widget.slot.name}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: _plateCtrl,
                decoration: const InputDecoration(labelText: 'Plate number'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (+254...)'),
              ),
              const SizedBox(height: 8),
              if (!_isManaging) ...[
                DropdownButtonFormField<String>(
                  initialValue: _action,
                  items: const [
                    DropdownMenuItem(value: 'reserve', child: Text('Reserve')),
                    DropdownMenuItem(
                        value: 'assign', child: Text('Assign & Send SMS')),
                  ],
                  onChanged: (v) => setState(() => _action = v ?? 'select'),
                  decoration: const InputDecoration(labelText: 'Action'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (_phoneCtrl.text.trim().isEmpty ||
                              _plateCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }

                          setState(() => _loading = true);
                          try {
                            Map<String, dynamic> res;
                            if (_action == 'reserve') {
                              res = await ApiService.reserveSlot(
                                widget.slot.id,
                                _phoneCtrl.text.trim(),
                                _plateCtrl.text.trim(),
                              );
                            } else {
                              res = await ApiService.occupySlot(
                                widget.slot.id,
                                _phoneCtrl.text.trim(),
                                _plateCtrl.text.trim(),
                              );
                              try {
                                await ApiService.sendSlotSms({
                                  'phoneNumber': _phoneCtrl.text.trim(),
                                  'message':
                                      'Your slot ${widget.slot.name} has been assigned.'
                                });
                              } catch (_) {}
                            }

                            setState(() => _loading = false);
                            if (res['ok'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _action == 'reserve'
                                        ? 'Slot reserved! Check SMS for confirmation.'
                                        : 'Slot assigned! SMS sent.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );

                              await Future.delayed(
                                  const Duration(milliseconds: 600));
                              widget.onRefresh?.call();
                              if (mounted) Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res["message"] ??
                                        'Action failed. Try again.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() => _loading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                  child: Text(_action == 'reserve'
                      ? 'Reserve Slot'
                      : 'Assign & Send SMS'),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text('Reserved until: ${widget.slot.reservedUntil ?? ''}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                try {
                                  final res =
                                      await ApiService.cancelReservation(
                                          widget.slot.id,
                                          _phoneCtrl.text.trim());
                                  setState(() => _loading = false);
                                  if (res['ok'] == true || res == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Reservation cancelled'),
                                            duration: Duration(seconds: 2)));
                                    widget.onRefresh?.call();
                                    if (mounted) Navigator.pop(context, true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(res['message'] ??
                                                'Cancel failed')));
                                  }
                                } catch (e) {
                                  setState(() => _loading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                        child: const Text('Cancel Reservation'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                try {
                                  final res = await ApiService.occupySlot(
                                      widget.slot.id,
                                      _phoneCtrl.text.trim(),
                                      _plateCtrl.text.trim());
                                  setState(() => _loading = false);
                                  if (res['ok'] == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Spot assigned to driver'),
                                            duration: Duration(seconds: 2)));
                                    widget.onRefresh?.call();
                                    if (mounted) Navigator.pop(context, true);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(res['message'] ??
                                                'Assign failed')));
                                  }
                                } catch (e) {
                                  setState(() => _loading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                        child: const Text('Confirm Arrival'),
                      ),
                    )
                  ],
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
