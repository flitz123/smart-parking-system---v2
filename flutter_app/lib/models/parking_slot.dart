class ParkingSlot {
  final String id;
  final String name;
  final String status;
  final String? plate;
  final String? phone;
  final DateTime? startTime;
  final DateTime? reservedUntil;
  final String? reservedBy;

  ParkingSlot({required this.id, required this.name, required this.status, this.plate, this.phone, this.startTime, this.reservedUntil, this.reservedBy});

  factory ParkingSlot.fromMap(Map<String, dynamic> m) => ParkingSlot(
        id: m['id'] ?? '',
        name: m['name'] ?? '',
        status: m['status'] ?? 'empty',
        plate: m['plate'],
        phone: m['phone'],
        startTime: m['start_time'] == null ? null : DateTime.parse(m['start_time']),
        reservedUntil: m['reserved_until'] == null ? null : DateTime.parse(m['reserved_until']),
        reservedBy: m['reserved_by'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'status': status,
        'plate': plate,
        'phone': phone,
        'start_time': startTime?.toIso8601String(),
        'reserved_until': reservedUntil?.toIso8601String(),
        'reserved_by': reservedBy
      };
}
