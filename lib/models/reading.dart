class PatientReading {
  final DateTime timestamp;
  final int heartRate;
  final String bp;
  final int spo2;

  PatientReading({
    required this.timestamp,
    required this.heartRate,
    required this.bp,
    required this.spo2,
  });
}

class Reading {
  final String type;
  final String value;
  final DateTime date;
  final String? notes;

  Reading({
    required this.type,
    required this.value,
    required this.date,
    this.notes,
  });
}
