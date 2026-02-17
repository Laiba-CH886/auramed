enum AppointmentStatus {
  pending,
  approved,
  rejected,
  completed,
}

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime date;
  final String reason;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.reason,
    required this.status,
  });

  // Convert Appointment → Map (Firestore-ready)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'reason': reason,
      'status': status.name,
    };
  }

  // Convert Map → Appointment
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'],
      doctorId: map['doctorId'],
      date: DateTime.parse(map['date']),
      reason: map['reason'],
      status: AppointmentStatus.values.firstWhere(
            (e) => e.name == map['status'],
      ),
    );
  }
}
