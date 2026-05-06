import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Appointment> get appointments => [..._appointments];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _firestore.collection('appointments');

  // ==========================
  // LOAD APPOINTMENTS
  // ==========================

  Future<void> loadAppointmentsForPatient(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _appointmentsRef
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      _appointments
        ..clear()
        ..addAll(snapshot.docs.map(_fromFirestoreDoc));
    } catch (e) {
      _errorMessage = 'Failed to load patient appointments: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAppointmentsForDoctor(String doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _appointmentsRef
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('createdAt', descending: true)
          .get();

      _appointments
        ..clear()
        ..addAll(snapshot.docs.map(_fromFirestoreDoc));
    } catch (e) {
      _errorMessage = 'Failed to load doctor appointments: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==========================
  // PATIENT ACTIONS
  // ==========================

  Future<String?> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required DateTime date,
    required String reason,
  }) async {
    try {
      final docRef = _appointmentsRef.doc();

      final dateOnly =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final timeOnly =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      await docRef.set({
        'id': docRef.id,
        'patientId': patientId,
        'patientName': patientName,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': dateOnly,
        'time': timeOnly,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      _errorMessage = 'Failed to book appointment: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await _appointmentsRef.doc(appointmentId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
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
    } catch (e) {
      _errorMessage = 'Failed to cancel appointment: $e';
      notifyListeners();
    }
  }

  List<Appointment> getAppointmentsForPatient(String patientId) {
    return _appointments.where((a) => a.patientId == patientId).toList();
  }

  // ==========================
  // DOCTOR ACTIONS
  // ==========================

  List<Appointment> getAppointmentsForDoctor(String doctorId) {
    return _appointments.where((a) => a.doctorId == doctorId).toList();
  }

  Future<void> approveAppointment(String appointmentId) async {
    await _updateStatus(appointmentId, AppointmentStatus.approved);
  }

  Future<void> rejectAppointment(String appointmentId) async {
    await _updateStatus(appointmentId, AppointmentStatus.rejected);
  }

  Future<void> completeAppointment(String appointmentId) async {
    await _updateStatus(appointmentId, AppointmentStatus.completed);
  }

  Future<void> _updateStatus(
      String appointmentId,
      AppointmentStatus status,
      ) async {
    try {
      await _appointmentsRef.doc(appointmentId).update({
        'status': _statusToString(status),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = _appointments.indexWhere((a) => a.id == appointmentId);
      if (index != -1) {
        _appointments[index] = Appointment(
          id: _appointments[index].id,
          patientId: _appointments[index].patientId,
          doctorId: _appointments[index].doctorId,
          date: _appointments[index].date,
          reason: _appointments[index].reason,
          status: status,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update appointment: $e';
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

  Appointment _fromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    return Appointment(
      id: data['id'] as String? ?? doc.id,
      patientId: data['patientId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      date: _parseDateTime(
        data['date'] as String?,
        data['time'] as String?,
      ),
      reason: data['reason'] as String? ?? '',
      status: _statusFromString(data['status'] as String?),
    );
  }

  AppointmentStatus _statusFromString(String? status) {
    switch (status) {
      case 'approved':
        return AppointmentStatus.approved;
      case 'rejected':
        return AppointmentStatus.rejected;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.pending;
    }
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.approved:
        return 'approved';
      case AppointmentStatus.rejected:
        return 'rejected';
      case AppointmentStatus.completed:
        return 'completed';
      case AppointmentStatus.pending:
        return 'pending';
    }
  }

  DateTime _parseDateTime(String? date, String? time) {
    try {
      if (date == null || date.isEmpty) return DateTime.now();

      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);

      int hour = 0;
      int minute = 0;

      if (time != null && time.isNotEmpty) {
        final timeParts = time.split(':');
        hour = int.parse(timeParts[0]);
        minute = int.parse(timeParts[1]);
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return DateTime.now();
    }
  }
}