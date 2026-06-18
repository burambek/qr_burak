enum TtnStatus { pending, completed }

class TtnRecord {
  final String ttnId;
  final String idCar;
  final String driverName;
  final String fieldName;
  final String fieldId;
  final DateTime dateTime;
  TtnStatus? status;

  String get id => ttnId;

  TtnRecord({
    required this.ttnId,
    required this.idCar,
    required this.driverName,
    required this.fieldName,
    required this.fieldId,
    required this.dateTime,
    this.status,
  });

  factory TtnRecord.fromJson(Map<String, dynamic> json) {
    // 1. Get the timestamp string
    String? timeString = json['timestamp']?.toString();

    // 2. Parse it. If it doesn't have a 'Z', append it so Dart treats it as UTC.
    // This forces the parser to recognize the string as UTC time.
    DateTime parsedDate;
    if (timeString != null && timeString.isNotEmpty) {
      // If the string is "2026-06-18 07:56:00", make it "2026-06-18 07:56:00Z"
      String isoString = timeString.contains('Z') ? timeString : '${timeString.replaceAll(' ', 'T')}Z';
      parsedDate = DateTime.tryParse(isoString) ?? DateTime.now().toUtc();
    } else {
      parsedDate = DateTime.now().toUtc();
    }

    return TtnRecord(
      ttnId: json['id_ttn']?.toString() ?? 'N/A',
      driverName: json['driver_name']?.toString() ?? 'Невідомо',
      idCar: json['id_car']?.toString() ?? '',
      fieldName: json['field_name']?.toString() ?? 'Невідомо',
      fieldId: json['field_id']?.toString() ?? '0',
      // 3. Convert the UTC parsed time to the device's local timezone (Ukraine)
      dateTime: parsedDate.toLocal(),
      status: json['status'] != null ? TtnStatus.values[json['status'] as int] : TtnStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_ttn': ttnId,
      'driver_name': driverName,
      'id_car': idCar,
      'field_name': fieldName,
      'field_id': fieldId,
    };
  }
}