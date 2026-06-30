enum TtnStatus { pending, completed }

class TtnRecord {
  final String ttnId;       // 'nomer' from API or 'ttnId' locally
  final String qrData;      // 'id_ttn' from API or 'qrData' locally
  final String idCar;       // 'avto' from API or 'idCar' locally
  final String driverName;  // 'driver' from API or 'driverName' locally
  final String idAvto;      // 'id_avto' from API or 'idAvto' locally
  final String kontragent;  // 'kontragent'
  final String gosp;        // 'gosp'
  final String fieldName;   // 'field_name' or 'fieldName'
  final String fieldId;     // 'id_field' or 'fieldId'
  final DateTime dateTime;
  final int rez;
  TtnStatus? status;

  String get id => ttnId;

  TtnRecord({
    required this.ttnId,
    required this.qrData,
    required this.idCar,
    required this.driverName,
    required this.idAvto,
    required this.kontragent,
    required this.gosp,
    required this.fieldName,
    required this.fieldId,
    required this.dateTime,
    this.rez = 1,
    this.status = TtnStatus.pending,
  });

  factory TtnRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['load_time'] ?? json['dateTime'] ?? json['date_time'];
    if (rawDate != null) {
      try {
        if (rawDate.toString().contains('-') && rawDate.toString().contains('T')) {
          // ISO8601 (local storage format)
          parsedDate = DateTime.parse(rawDate.toString());
        } else {
          // "30.06.2026 14:08:41" format from ListTTN
          final parts = rawDate.toString().split(' ');
          final dateParts = parts[0].split('.'); // [dd, MM, yyyy]
          final timeParts = parts.length > 1 ? parts[1].split(':') : ['0', '0', '0'];
          parsedDate = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
            int.parse(timeParts[0]),
            timeParts.length > 1 ? int.parse(timeParts[1]) : 0,
            timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
          );
        }
      } catch (_) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return TtnRecord(
      ttnId:      (json['nomer']      ?? json['ttnId']      ?? 'N/A').toString(),
      qrData:     (json['id_ttn']     ?? json['qrData']     ?? '').toString(),
      idCar:      (json['avto']       ?? json['idCar']      ?? '').toString(),
      driverName: (json['driver']     ?? json['driverName'] ?? 'Невідомо').toString(),
      idAvto:     (json['id_avto']    ?? json['idAvto']     ?? '').toString(),
      kontragent: (json['kontr']      ?? json['kontragent'] ?? '').toString(),
      gosp:       (json['gosp']       ?? '').toString(),
      fieldName:  (json['field']      ?? json['field_name'] ?? json['fieldName'] ?? 'Невідомо').toString(),
      fieldId:    (json['id_field']   ?? json['fieldId']    ?? '0').toString(),
      dateTime:   parsedDate,
      rez:        int.tryParse(json['rez']?.toString() ?? '1') ?? 1,
      status:     json['status'] != null && json['status'] is int
          ? TtnStatus.values[json['status'] as int]
          : TtnStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ttnId':      ttnId,
      'qrData':     qrData,
      'idCar':      idCar,
      'driverName': driverName,
      'idAvto':     idAvto,
      'kontragent': kontragent,
      'gosp':       gosp,
      'fieldName':  fieldName,
      'fieldId':    fieldId,
      'dateTime':   dateTime.toIso8601String(),
      'rez':        rez,
      'status':     status?.index,
    };
  }
}
