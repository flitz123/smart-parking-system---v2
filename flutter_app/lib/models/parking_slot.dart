class ParkingSlot {
  final String id;
  final String name;
  final String status;
  final String? plate;
  final String? phone;
  final DateTime? startTime;
  final DateTime? reservedUntil;
  final String? reservedBy;

  ParkingSlot(
      {required this.id,
      required this.name,
      required this.status,
      this.plate,
      this.phone,
      this.startTime,
      this.reservedUntil,
      this.reservedBy});

  factory ParkingSlot.fromMap(Map<String, dynamic> m) => ParkingSlot(
        id: (m['id'] ?? m['Id'] ?? '') as String,
        name: (m['name'] ?? m['Name'] ?? '') as String,
        status: (m['status'] ?? m['Status'] ?? 'empty') as String,
        plate: m['plate'] ?? m['Plate'],
        phone: m['phone'] ?? m['Phone'],
        startTime: (() {
          final v = m['start_time'] ?? m['startTime'] ?? m['StartTime'];
          if (v == null) return null;
          try {
            return DateTime.parse(v);
          } catch (e) {
            return null;
          }
        })(),
        reservedUntil: (() {
          final v =
              m['reserved_until'] ?? m['reservedUntil'] ?? m['ReservedUntil'];
          if (v == null) return null;
          try {
            return DateTime.parse(v);
          } catch (e) {
            return null;
          }
        })(),
        reservedBy: m['reserved_by'] ?? m['reservedBy'] ?? m['ReservedBy'],
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
