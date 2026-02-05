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
