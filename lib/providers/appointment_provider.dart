import 'package:flutter/material.dart';
import '../models/appointment.dart';

class AppointmentProvider with ChangeNotifier {
  final List<Appointment> _appointments = [];

  List<Appointment> get appointments => [..._appointments];

  // ==========================
  // PATIENT ACTIONS
  // ==========================

  void bookAppointment({
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String reason,
  }) {
    final newAppointment = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      doctorId: doctorId,
      date: date,
      reason: reason,
      status: AppointmentStatus.pending,
    );

    _appointments.add(newAppointment);
    notifyListeners();
  }

  List<Appointment> getAppointmentsForPatient(String patientId) {
    return _appointments
        .where((a) => a.patientId == patientId)
        .toList();
  }

  // ==========================
  // DOCTOR ACTIONS
  // ==========================

  List<Appointment> getAppointmentsForDoctor(String doctorId) {
    return _appointments
        .where((a) => a.doctorId == doctorId)
        .toList();
  }

  void approveAppointment(String appointmentId) {
    final index =
    _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = Appointment(
        id: _appointments[index].id,
        patientId: _appointments[index].patientId,
        doctorId: _appointments[index].doctorId,
        date: _appointments[index].date,
        reason: _appointments[index].reason,
        status: AppointmentStatus.approved,
      );
      notifyListeners();
    }
  }

  void rejectAppointment(String appointmentId) {
    final index =
    _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = Appointment(
        id: _appointments[index].id,
        patientId: _appointments[index].patientId,
        doctorId: _appointments[index].doctorId,
        date: _appointments[index].date,
        reason: _appointments[index].reason,
        status: AppointmentStatus.rejected,
      );
      notifyListeners();
    }
  }

  // ==========================
  // GENERAL
  // ==========================

  Appointment? getAppointmentById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
